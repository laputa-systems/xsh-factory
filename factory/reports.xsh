##! Common report construction and graph/evidence auditing.
use factory.evidence as evidence
use factory.graph as graph
use factory.schema as schema
use factory.types as types

## Expected machine outputs for one admitted node.
export type NodeEvidence = {
  node_id: Str,
  report: Bool,
  manifest: Bool,
  session: Bool,
  narrative: Bool,
}

## Plan-vs-observed audit result.
export type AuditResult = {
  pass: Bool,
  missing_nodes: List[Str],
  extra_nodes: List[Str],
  invalid_nodes: List[Str],
  findings: List[Any],
}

## Builds the one common machine-report envelope with typed data preserved.
export pure machine_report(
  kind: Str,
  identity: Any,
  state: Str,
  result: Str,
  data: Any,
  findings: List[Any],
  artifacts: List[Any],
) -> Any {
  return {
    schema_version: schema.SCHEMA_VERSION,
    kind: kind,
    identity: identity,
    state: state,
    result: result,
    data: data,
    findings: findings,
    artifacts: artifacts,
  }
}

## Validates the common envelope and the expected identity in one place.
export pure validate_machine_report(report: Any, kind: Str, expected: evidence.ExpectedIdentity) -> Bool {
  return schema.valid(report, kind) and evidence.report_identity_ok(report, expected)
}

## Validates identity and mode-specific data while preserving the common schema.
export pure validate_mode_report(report: Any, kind: Str, mode: Str, expected: evidence.ExpectedIdentity) -> Bool {
  return schema.mode_contract_ok(report, kind, mode) and evidence.report_identity_ok(report, expected)
}

pure observed_for(observed: List[NodeEvidence], node_id: Str) -> NodeEvidence {
  for item in observed {
    if item.node_id == node_id {
      return item
    }
  }

  return {node_id: "", report: false, manifest: false, session: false, narrative: false}
}

pure duplicate_observed(observed: List[NodeEvidence]) -> Str {
  var seen: List[Str] = []
  for item in observed {
    continue when item.node_id == ""
    for prior in seen {
      if prior == item.node_id {
        return prior
      }
    }

    seen = seen.push(item.node_id)
  }

  return ""
}

## Audits exact graph membership and required machine evidence.
export pure audit_plan(plan: Any, observed: List[NodeEvidence]) -> AuditResult {
  var missing: List[Str] = []
  var invalid: List[Str] = []
  for node in plan.nodes {
    let item = observed_for(observed, node.node_id)
    if item.node_id == "" {
      missing = missing.push(node.node_id)
    } else {
      if ! item.report or ! item.manifest or ! item.session {
        invalid = invalid.push(node.node_id)
      }
    }
  }

  var extra: List[Str] = []
  for item in observed {
    continue when item.node_id == ""
    var expected = false
    for node in plan.nodes {
      if node.node_id == item.node_id {
        expected = true
      }
    }

    if ! expected {
      extra = extra.push(item.node_id)
    }
  }

  let duplicate = duplicate_observed(observed)
  if duplicate != "" {
    invalid = invalid.push(duplicate)
  }
  var findings: List[Any] = []
  if missing.len() > 0 {
    findings = findings.push({kind: "missing-node", nodes: missing})
  }
  if extra.len() > 0 {
    findings = findings.push({kind: "extra-node", nodes: extra})
  }
  if invalid.len() > 0 {
    findings = findings.push({kind: "invalid-evidence", nodes: invalid})
  }
  return {
    pass: missing.len() == 0 and extra.len() == 0 and invalid.len() == 0,
    missing_nodes: missing,
    extra_nodes: extra,
    invalid_nodes: invalid,
    findings: findings,
  }
}

## The root report is derived from graph evidence, never employee prose.
export pure root_report(plan: Any, audit: AuditResult, states: List[Any], outputs: List[Str]) -> Any {
  let graph_result = graph.root_result(plan, states, outputs)
  let result = if audit.pass and graph_result == "pass" { "pass" } else { "fail" }
  return machine_report(
    "run",
    {run_id: plan.run_id, mode: plan.mode},
    "completed",
    result,
    {missing_nodes: audit.missing_nodes, extra_nodes: audit.extra_nodes, invalid_nodes: audit.invalid_nodes},
    audit.findings,
    [{kind: "raw-events", path: "events.jsonl"}],
  )
}
