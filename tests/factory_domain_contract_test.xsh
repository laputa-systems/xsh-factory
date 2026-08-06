##! Behavior-level coverage for the factory's typed domain boundaries.
use factory.evidence as evidence
use factory.graph as graph
use factory.paths as paths
use factory.reports as reports
use factory.schema as schema
use factory.types as types

proc test_domain_vocabulary_roundtrips_across_boundaries() [error] {
  let digest = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  test.ok(types.valid_identifier("safe-name"))?
  test.ok(! types.valid_identifier("unsafe/name"))?
  test.ok(types.valid_hash_text(digest))?
  test.ok(! types.valid_hash_text("short"))?

  test.eq(types.make_ticket_id("ticket-a")?.value, "ticket-a")?
  test.eq(types.make_eval_id("eval-a")?.value, "eval-a")?
  test.eq(types.make_worker_id("worker-a")?.value, "worker-a")?
  test.eq(types.make_run_id("run-a")?.value, "run-a")?
  test.eq(types.make_phase_id("01-eval")?.value, "01-eval")?
  test.eq(types.make_node_id("node-a")?.value, "node-a")?
  test.eq(types.make_dispatch_id("dispatch-a")?.value, "dispatch-a")?
  test.eq(types.make_content_hash("artifact", digest)?.value, digest)?
  test.eq(types.make_assignment_hash(digest)?.value, digest)?
  test.eq(types.make_prompt_hash(digest)?.value, digest)?
  test.eq(types.make_commit_hash(digest)?.value, digest)?
  test.eq(types.make_trial_count(2)?.value, 2)?
  test.eq(types.make_budget(0.25, 1.0)?.role_limit, 0.25)?

  let role = types.parse_role("engineer")?
  test.eq(types.role_name(role), "engineer")?
  let mode = types.parse_mode("organization")?
  test.eq(types.mode_name(mode), "organization")?
  let target = types.parse_change_target("product")?
  test.eq(types.change_target_name(target), "product")?
  let ticket_status = types.parse_ticket_status("Accepted.")?
  test.eq(types.ticket_status_name(ticket_status), "Accepted.")?
  let eval_status = types.parse_eval_status("Disabled.")?
  test.eq(types.eval_status_name(eval_status), "Disabled.")?
  test.eq(types.lifecycle_name({value: "validated"}), "validated")?

  match types.make_run_id("not-a-run") {
    Ok(_) => test.fail("run IDs without the run- prefix were accepted")?
    Err(_) => {}
  }
  for invalid in ["bad/name", ""] {
    match types.make_eval_id(invalid) {
      Ok(_) => test.fail("unsafe eval ID was accepted")?
      Err(_) => {}
    }
    match types.make_worker_id(invalid) {
      Ok(_) => test.fail("unsafe worker ID was accepted")?
      Err(_) => {}
    }
    match types.make_phase_id(invalid) {
      Ok(_) => test.fail("unsafe phase ID was accepted")?
      Err(_) => {}
    }
    match types.make_node_id(invalid) {
      Ok(_) => test.fail("unsafe node ID was accepted")?
      Err(_) => {}
    }
    match types.make_dispatch_id(invalid) {
      Ok(_) => test.fail("unsafe dispatch ID was accepted")?
      Err(_) => {}
    }
  }
  match types.make_budget(1.1, 1.0) {
    Ok(_) => test.fail("a role budget above the aggregate limit was accepted")?
    Err(_) => {}
  }
  for invalid in ["short", "with space"] {
    match types.make_assignment_hash(invalid) {
      Ok(_) => test.fail("invalid assignment hash was accepted")?
      Err(_) => {}
    }
    match types.make_prompt_hash(invalid) {
      Ok(_) => test.fail("invalid prompt hash was accepted")?
      Err(_) => {}
    }
    match types.make_commit_hash(invalid) {
      Ok(_) => test.fail("invalid commit hash was accepted")?
      Err(_) => {}
    }
  }
  match types.make_trial_count(0) {
    Ok(_) => test.fail("zero trial count was accepted")?
    Err(_) => {}
  }
  match types.make_role("unknown") {
    Ok(_) => test.fail("an unknown role was accepted")?
    Err(_) => {}
  }
  match types.make_mode("unknown") {
    Ok(_) => test.fail("an unknown cycle mode was accepted")?
    Err(_) => {}
  }
  match types.make_change_target("unknown") {
    Ok(_) => test.fail("an unknown change target was accepted")?
    Err(_) => {}
  }
  match types.make_ticket_status("unknown") {
    Ok(_) => test.fail("an unknown ticket status was accepted")?
    Err(_) => {}
  }
  match types.make_eval_status("unknown") {
    Ok(_) => test.fail("an unknown eval status was accepted")?
    Err(_) => {}
  }
}

proc test_repository_and_evidence_paths_keep_ownership_explicit(ctx: TestContext) [fs, error] {
  let root = test.temp_dir(ctx, name: "domain-paths")?
  let factory_path = fp"${root}/factory"
  let product_path = fp"${root}/product"
  let run_path = fp"${factory_path}/runs/run-1"
  let phase_path = fp"${run_path}/01-eval"
  let worker_path = fp"${phase_path}/worker-a"
  for directory in [factory_path, product_path, fp"${factory_path}/runs", run_path, phase_path, worker_path] {
    fs.mkdir(directory)?
  }

  test.eq(paths.canonical_absolute(/srv//factory/)?.display(), "/srv/factory")?
  match paths.canonical_absolute(p"relative") {
    Ok(_) => test.fail("relative path was accepted")?
    Err(_) => {}
  }
  match paths.canonical_absolute(/srv/../factory) {
    Ok(_) => test.fail("traversal path was accepted")?
    Err(_) => {}
  }
  test.ok(paths.within(/, /anything)?)?
  test.ok(! paths.within(/srv/factory, /srv/factory-old/file)?)?
  let factory = paths.make_factory_root(factory_path)?
  let product = paths.make_product_root(product_path, factory)?
  let run_root = paths.make_run_root(factory, run_path)?
  let phase = paths.make_phase_root(run_root, "01-eval", phase_path)?
  let worker = paths.make_worker_root(phase, "worker-a", worker_path)?
  test.eq(run_root.run_id, "run-1")?
  test.eq(phase.phase_id, "01-eval")?
  test.eq(worker.worker_id, "worker-a")?
  test.eq(paths.make_factory_path(factory, fp"${factory_path}/NORTH-STAR.md")?.value.display(), fp"${factory_path}/NORTH-STAR.md".display())?
  test.eq(paths.make_run_path(run_root, fp"${run_path}/report.json")?.value.display(), fp"${run_path}/report.json".display())?
  test.eq(paths.make_phase_path(phase, fp"${phase_path}/report.json")?.value.display(), fp"${phase_path}/report.json".display())?
  test.eq(paths.make_worker_path(worker, fp"${worker_path}/report.json")?.value.display(), fp"${worker_path}/report.json".display())?

  let worktree = paths.make_product_worktree(product, factory, fp"${product_path}/worktree", "factory-ticket-a", "commit-a")?
  test.eq(worktree.branch, "factory-ticket-a")?
  test.ok(paths.real_within(factory_path, fp"${factory_path}/runs")?)?
  test.ok(! paths.real_within(factory_path, product_path)?)?

  let evidence_path = fp"${worker_path}/report.json"
  fs.write(evidence_path, "evidence\n")?
  let digest = hash.sha256(evidence_path)?.hex()
  let ref = evidence.make_ref("run-1", "worker-a", "worker-report", run_path, evidence_path, digest, true, "present")?
  evidence.validate_ref(ref, "run-1", "worker-a", run_path)?
  evidence.validate_set({refs: [ref], required_kinds: ["worker-report"]}, "run-1", "worker-a", run_path)?
  test.ok(evidence.verify_file(ref)?)?
  test.ok(evidence.report_identity_ok(
    {identity: {run_id: "run-1", node_id: "worker-a", role: "engineer", worker_id: "worker-a", dispatch_id: "dispatch-a"}},
    {run_id: "run-1", node_id: "worker-a", role: "engineer", worker_id: "worker-a", dispatch_id: "dispatch-a"},
  ))?

  match paths.make_product_root(factory_path, factory) {
    Ok(_) => test.fail("the factory checkout was accepted as the product root")?
    Err(_) => {}
  }
  match paths.make_factory_root(p"relative") {
    Ok(_) => test.fail("relative factory root was accepted")?
    Err(_) => {}
  }
  match paths.make_factory_path(factory, product_path) {
    Ok(_) => test.fail("outside factory path was accepted")?
    Err(_) => {}
  }
  match paths.make_product_worktree(product, factory, fp"${factory_path}/worktree", "factory-ticket-a", "commit-a") {
    Ok(_) => test.fail("factory worktree was accepted")?
    Err(_) => {}
  }
  match paths.make_product_worktree(product, factory, fp"${product_path}/worktree", "bad/name", "commit-a") {
    Ok(_) => test.fail("unsafe worktree branch was accepted")?
    Err(_) => {}
  }
  match paths.make_product_worktree(product, factory, fp"${product_path}/worktree", "factory-ticket-a", "") {
    Ok(_) => test.fail("worktree without a base commit was accepted")?
    Err(_) => {}
  }
  match paths.make_run_root(factory, fp"${factory_path}/other") {
    Ok(_) => test.fail("run outside the runs root was accepted")?
    Err(_) => {}
  }
  match paths.make_phase_root(run_root, "01-eval", product_path) {
    Ok(_) => test.fail("phase outside its run was accepted")?
    Err(_) => {}
  }
  match paths.make_worker_root(phase, "worker-a", product_path) {
    Ok(_) => test.fail("worker outside its phase was accepted")?
    Err(_) => {}
  }
  match paths.make_worker_path(worker, /outside/report.json) {
    Ok(_) => test.fail("evidence outside the worker root was accepted")?
    Err(_) => {}
  }
  match evidence.validate_set({refs: [ref], required_kinds: ["session"]}, "run-1", "worker-a", run_path) {
    Ok(_) => test.fail("missing required evidence kind was accepted")?
    Err(_) => {}
  }
  test.ok(! evidence.verify_file({run_id: "run-1", node_id: "worker-a", kind: "missing", path: fp"${worker_path}/missing.json", sha256: digest, required: false, state: "missing"})?)?
  test.ok(! evidence.report_identity_ok({identity: {run_id: "run-2"}}, {run_id: "run-1", node_id: "worker-a", role: "engineer", worker_id: "worker-a", dispatch_id: "dispatch-a"}))?
  match evidence.make_ref("", "worker-a", "report", run_path, evidence_path, digest, true, "present") {
    Ok(_) => test.fail("incomplete evidence identity was accepted")?
    Err(_) => {}
  }
  match evidence.make_ref("run-1", "worker-a", "report", run_path, evidence_path, digest, true, "unknown") {
    Ok(_) => test.fail("unknown evidence state was accepted")?
    Err(_) => {}
  }
  match evidence.validate_ref(ref, "run-2", "worker-a", run_path) {
    Ok(_) => test.fail("evidence for another run was accepted")?
    Err(_) => {}
  }
}

proc test_graph_audit_and_root_report_follow_the_same_plan() [error] {
  let first = graph.make_node(
    types.make_node_id("implementation")?,
    types.make_role("engineer")?,
    types.make_worker_id("worker-a")?,
    types.make_dispatch_id("dispatch-a")?,
    "implement the assigned change",
    ["ticket"],
    ["report.json"],
    types.make_budget(0.35, 1.0)?,
    ["completed", "validated", "failed"],
  )?
  let second = graph.make_node(
    types.make_node_id("replay")?,
    types.make_role("eval-manager")?,
    types.make_worker_id("worker-replay")?,
    types.make_dispatch_id("dispatch-replay")?,
    "replay the linked evidence",
    ["report.json"],
    ["replay.json"],
    types.make_budget(0.15, 1.0)?,
    ["completed", "validated", "failed"],
  )?
  let edge = graph.make_edge(types.make_node_id("implementation")?, types.make_node_id("replay")?, "replay", "stop-dependents")?
  let plan = {
    run_id: "run-1",
    mode: "organization",
    nodes: [first, second],
    edges: [edge],
    source_hashes: [],
    required_outputs: ["report.json", "replay.json"],
    aggregate_budget: 1.0,
  }
  graph.validate(plan)?
  test.ok(! graph.startable(plan, "replay", [{node_id: "implementation", state: "started"}]))?
  test.ok(graph.startable(plan, "replay", [{node_id: "implementation", state: "validated"}]))?
  test.eq(graph.root_result(plan, [{node_id: "implementation", state: "validated"}, {node_id: "replay", state: "validated"}], ["report.json", "replay.json"]), "pass")?
  test.eq(graph.root_result(plan, [{node_id: "implementation", state: "failed"}, {node_id: "replay", state: "validated"}], ["report.json", "replay.json"]), "fail")?

  let observed = [
    {node_id: "implementation", report: true, manifest: true, session: true, narrative: true},
    {node_id: "replay", report: true, manifest: true, session: false, narrative: true},
    {node_id: "unexpected", report: true, manifest: true, session: true, narrative: true},
  ]
  let audit = reports.audit_plan(plan, observed)
  test.eq(audit.pass, false)?
  test.eq(audit.extra_nodes[0], "unexpected")?
  test.eq(audit.invalid_nodes.len(), 1)?
  let root = reports.root_report(plan, audit, [{node_id: "implementation", state: "validated"}, {node_id: "replay", state: "validated"}], ["report.json", "replay.json"])
  test.ok(schema.valid(root, "run"))?
  test.eq(json.get(root, ["result"], ""), "fail")?

  let identity = {run_id: "run-1", node_id: "implementation", role: "engineer", worker_id: "worker-a", dispatch_id: "dispatch-a"}
  let report = reports.machine_report("worker", identity, "completed", "pass", {mode: "organization"}, [], [])
  test.ok(reports.validate_machine_report(report, "worker", identity))?
  test.ok(reports.validate_mode_report(report, "worker", "organization", identity))?
  test.ok(! reports.validate_machine_report(report, "worker", {run_id: "run-2", node_id: "implementation", role: "engineer", worker_id: "worker-a", dispatch_id: "dispatch-a"}))?
}
