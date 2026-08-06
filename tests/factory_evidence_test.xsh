##! Native tests for typed evidence references and exact graph auditing.

use factory.types as types
use factory.graph as graph
use factory.evidence as evidence
use factory.reports as reports
use factory.schema as schema

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

proc test_audit_and_root_report_accept_complete_evidence() [error] {
  let first = graph.make_node(types.make_node_id("node-a")?, types.make_role("eval-worker")?, types.make_worker_id("worker-a")?, types.make_dispatch_id("dispatch-a")?, "assignment", ["input"], ["report.json"], types.make_budget(0.5, 1.0)?, ["completed"])?
  let second = graph.make_node(types.make_node_id("node-b")?, types.make_role("eval-manager")?, types.make_worker_id("worker-b")?, types.make_dispatch_id("dispatch-b")?, "assignment", ["input"], ["report.json"], types.make_budget(0.15, 1.0)?, ["completed"])?
  let plan = {run_id: "run-1", mode: "eval", nodes: [first, second], edges: [graph.make_edge(types.make_node_id("node-a")?, types.make_node_id("node-b")?, "hard", "stop-dependents")?], source_hashes: [], required_outputs: ["report.json"], aggregate_budget: 1.0}
  let observed = [
    {node_id: "node-a", report: true, manifest: true, session: true, narrative: true},
    {node_id: "node-b", report: true, manifest: true, session: true, narrative: true},
  ]
  let audit = reports.audit_plan(plan, observed)
  test.ok(audit.pass)?
  test.eq(audit.findings.len(), 0)?
  let root = reports.root_report(plan, audit, [{node_id: "node-a", state: "completed"}, {node_id: "node-b", state: "validated"}], ["report.json"])
  test.ok(schema.valid(root, "run"))?
  test.eq(schema.value_text(json.get(root, ["result"], null)), "pass")?
  let expected = {run_id: "run-1", node_id: "node-a", role: "eval-worker", worker_id: "worker-a", dispatch_id: "dispatch-a"}
  let phase = reports.machine_report("phase", expected, "completed", "pass", {mode: "eval"}, [], [])
  test.ok(reports.validate_machine_report(phase, "phase", expected))?
  test.ok(reports.validate_mode_report(phase, "phase", "eval", expected))?
  test.ok(! reports.validate_mode_report(phase, "phase", "ticket-implementation", expected))?
}

proc test_evidence_validation_rejects_duplicates_and_verifies_files(ctx: TestContext) [fs, error] {
  let root = test.temp_dir(ctx, name: "evidence-validation")?
  let report_path = fp"${root}/report.json"
  fs.write(report_path, "evidence\n")?
  let digest = hash.sha256(report_path)?.hex()
  let ref = evidence.make_ref("run-1", "node-a", "report", root, report_path, digest, true, "present")?
  test.ok(evidence.verify_file(ref)?)?
  let missing_path = fp"${root}/missing.json"
  let missing = evidence.make_ref("run-1", "node-a", "session", root, missing_path, digest, false, "missing")?
  test.ok(! evidence.verify_file(missing)?)?
  match evidence.validate_set({refs: [ref, ref], required_kinds: ["report"]}, "run-1", "node-a", root) {
    Ok(_) => test.fail("duplicate evidence kind was accepted")?,
    Err(_) => {},
  }
  match evidence.validate_ref(ref, "run-2", "node-a", root) {
    Ok(_) => test.fail("evidence from another run was accepted")?,
    Err(_) => {},
  }
  match evidence.make_ref("run-1", "node-a", "report", root, report_path, digest, true, "unknown") {
    Ok(_) => test.fail("unknown evidence state was accepted")?,
    Err(_) => {},
  }
}
