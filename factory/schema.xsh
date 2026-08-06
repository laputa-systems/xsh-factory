##! The one structured reporting contract shared by factory boundaries.
## Reports are versioned so a future controller can reject stale evidence.
export let SCHEMA_VERSION = 1

## The report envelope is deliberately small and common to worker, phase, and run reports.
export pure envelope(kind: Str, identity: Any, state: Str, result: Str) -> Any {
  return {
    schema_version: SCHEMA_VERSION,
    kind: kind,
    identity: identity,
    state: state,
    result: result,
    findings: [],
    artifacts: [],
  }
}

## Checks the fields every persisted report must carry.
export pure valid(value: Any, expected_kind: Str) -> Bool {
  let version = json.get(value, ["schema_version"], null)
  let kind = json.get(value, ["kind"], null)
  let identity = json.get(value, ["identity"], null)
  let state = json.get(value, ["state"], null)
  let raw_result = json.get(value, ["result"], null)
  let findings = json.get(value, ["findings"], null)
  let artifacts = json.get(value, ["artifacts"], null)
  var valid_report = false
  match version {
    i is Int => valid_report = i == SCHEMA_VERSION and value_text(kind) == expected_kind and is_record(identity) and value_text(
      state,
    ) != "" and value_text(raw_result) != "" and is_list(findings) and is_list(artifacts)
    _ => {}
  }

  return valid_report
}

## Validates the mode facts that a common envelope must carry without creating
## role-specific report projections.
export pure mode_contract_ok(value: Any, expected_kind: Str, mode: Str) -> Bool {
  if ! valid(value, expected_kind) {
    return false
  }
  if expected_kind == "worker" {
    return true
  }
  let data = json.get(value, ["data"], null)
  let reported_mode = json.get(data, ["mode"], "")
  return reported_mode == mode
}

## Separates product/evaluator success from controller/reporting success.
export pure outcome(product_ok: Bool, evaluator_ok: Bool, infrastructure_ok: Bool) -> Any {
  return {
    product: if product_ok { "pass" } else { "fail" },
    evaluator: if evaluator_ok { "pass" } else { "fail" },
    infrastructure: if infrastructure_ok { "pass" } else { "fail" },
    cycle: if product_ok and evaluator_ok and infrastructure_ok { "pass" } else { "fail" },
  }
}

## Converts a JSON scalar to text for controller diagnostics.
export pure value_text(value: Any) -> Str {
  match value {
    s is Str => s
    i is Int => f"${i}"
    f is Float => f.format(precision: 6)
    b is Bool => {
      if b {
        "true"
      } else {
        "false"
      }
    }
    _ => ""
  }
}

pure is_record(value: Any) -> Bool {
  match value {
    _ is Record => true
    _ => false
  }
}

pure is_list(value: Any) -> Bool {
  match value {
    _ is List[Any] => true
    _ => false
  }
}
