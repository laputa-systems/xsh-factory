##! Native tests for typed evidence references and exact graph auditing.

use factory.types as types
use factory.graph as graph
use factory.evidence as evidence
use factory.reports as reports
use report_schema as schema

proc test_evidence_refs_are_run_scoped_and_required() [error] {
  let ref = evidence.make_ref("run-1", "node-a", "worker-report", Path("/run-1"), Path("/run-1/workers/a/report.json"), "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", true, "present")?
  evidence.validate_ref(ref, "run-1", "node-a", Path("/run-1"))?
  evidence.validate_set({refs: [ref], required_kinds: ["worker-report"]}, "run-1", "node-a", Path("/run-1"))?
  match evidence.make_ref("run-1", "node-a", "worker-report", Path("/run-1"), Path("/other/report.json"), "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", true, "present") {
    Ok(_) => test.fail("cross-run evidence path was accepted")?,
    Err(_) => {},
  }
  let missing = evidence.make_ref("run-1", "node-a", "session", Path("/run-1"), Path("/run-1/session.jsonl.bz2"), "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", true, "missing")?
  match evidence.validate_ref(missing, "run-1", "node-a", Path("/run-1")) {
    Ok(_) => test.fail("required missing evidence was accepted")?,
    Err(_) => {},
  }
}

proc test_report_identity_is_machine_bound() [error] {
  let expected = {run_id: "run-1", node_id: "node-a", role: "eval-worker", worker_id: "task-a-1", dispatch_id: "dispatch-a"}
  let report = reports.machine_report("worker", {run_id: "run-1", node_id: "node-a", role: "eval-worker", worker_id: "task-a-1", dispatch_id: "dispatch-a"}, "completed", "pass", {result: "pass"}, [], [])
  test.ok(reports.validate_machine_report(report, "worker", expected))
  let forged = reports.machine_report("worker", {run_id: "run-1", node_id: "node-a", role: "engineer", worker_id: "task-a-1", dispatch_id: "dispatch-a"}, "completed", "pass", {result: "pass"}, [], [])
  test.ok(! evidence.report_identity_ok(forged, expected))
  let phase = reports.machine_report("phase", {run_id: "run-1", node_id: "node-a", role: "eval-worker", worker_id: "task-a-1", dispatch_id: "dispatch-a"}, "completed", "pass", {mode: "eval", result: "pass"}, [], [])
  test.ok(schema.mode_contract_ok(phase, "phase", "eval"))
  test.ok(! schema.mode_contract_ok(phase, "phase", "ticket-implementation"))
}

proc test_audit_rejects_missing_and_extra_workers() [error] {
  let first = graph.make_node(types.make_node_id("node-a")?, types.make_role("eval-worker")?, types.make_worker_id("worker-a")?, types.make_dispatch_id("dispatch-a")?, "assignment", ["input"], ["report.json"], types.make_budget(0.5, 1.0)?, ["completed"])?
  let second = graph.make_node(types.make_node_id("node-b")?, types.make_role("eval-manager")?, types.make_worker_id("worker-b")?, types.make_dispatch_id("dispatch-b")?, "assignment", ["input"], ["report.json"], types.make_budget(0.15, 1.0)?, ["completed"])?
  let plan = {run_id: "run-1", mode: "eval", nodes: [first, second], edges: [graph.make_edge(types.make_node_id("node-a")?, types.make_node_id("node-b")?, "hard", "stop-dependents")?], source_hashes: [], required_outputs: ["report.json"], aggregate_budget: 1.0}
  let missing = reports.audit_plan(plan, [{node_id: "node-a", report: true, manifest: true, session: true, narrative: true}])
  test.ok(! missing.pass)
  test.eq(missing.missing_nodes, ["node-b"])?
  let extra = reports.audit_plan(plan, [
    {node_id: "node-a", report: true, manifest: true, session: true, narrative: true},
    {node_id: "node-b", report: true, manifest: true, session: true, narrative: true},
    {node_id: "forged", report: true, manifest: true, session: true, narrative: true},
  ])
  test.ok(! extra.pass)
  test.eq(extra.extra_nodes, ["forged"])?

  let duplicate = reports.audit_plan(plan, [
    {node_id: "node-a", report: true, manifest: true, session: true, narrative: true},
    {node_id: "node-a", report: true, manifest: true, session: true, narrative: true},
    {node_id: "node-b", report: true, manifest: true, session: true, narrative: true},
  ])
  test.ok(! duplicate.pass)
  test.ok(duplicate.invalid_nodes.contains("node-a"))
}
