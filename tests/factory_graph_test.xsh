##! Native tests for graph ordering, exclusivity, and dispatch authority.
use factory.dispatch as dispatch
use factory.graph as graph
use factory.types as types

proc fixture_node(
  node_text: Str,
  worker_text: Str,
  dispatch_text: Str,
  role_text: Str,
) [error] -> Result[graph.GraphNode] {
  return graph.make_node(
    types.make_node_id(node_text)?,
    types.make_role(role_text)?,
    types.make_worker_id(worker_text)?,
    types.make_dispatch_id(dispatch_text)?,
    "controller assignment",
    ["input"],
    ["report.json"],
    types.make_budget(0.25, 1.0)?,
    ["completed", "failed", "cancelled", "budget-breached", "skipped"],
  )
}

proc test_graph_validation_rejects_cycles_and_duplicates() [error] {
  let first = fixture_node("implementation", "task-a", "dispatch-a", "engineer")?
  let second = fixture_node("replay", "task-a-replay", "dispatch-b", "eval-manager")?
  let a = types.make_node_id("implementation")?
  let b = types.make_node_id("replay")?
  let run_id = types.make_run_id("run-1")?
  let mode = types.make_mode("organization")?
  let plan = {
    run_id: run_id.value,
    mode: mode.value,
    nodes: [
      first,
      second,
    ],
    edges: [
      graph.make_edge(a, b, "replay", "stop-dependents")?,
    ],
    source_hashes: [],
    required_outputs: [
      "report.json",
    ],
    aggregate_budget: 1.0,
  }
  graph.validate(plan)?
  test.ok(graph.startable(plan, "replay", [{node_id: "implementation", state: "started"}]) == false)
  test.ok(graph.startable(plan, "replay", [{node_id: "implementation", state: "completed"}]))

  let cycle = {
    run_id: run_id.value,
    mode: mode.value,
    nodes: [
      first,
      second,
    ],
    edges: [
      graph.make_edge(a, b, "hard", "stop-dependents")?,
      graph.make_edge(b, a, "hard", "stop-dependents")?,
    ],
    source_hashes: [],
    required_outputs: [
      "report.json",
    ],
    aggregate_budget: 1.0,
  }
  match graph.validate(cycle) {
    Ok(_) => test.fail("cyclic workflow was accepted")?
    Err(_) => {}
  }

  let duplicate = fixture_node("extra", "task-a", "dispatch-c", "engineer")?
  let duplicate_plan = {
    run_id: run_id.value,
    mode: mode.value,
    nodes: [
      first,
      duplicate,
    ],
    edges: [],
    source_hashes: [],
    required_outputs: [
      "report.json",
    ],
    aggregate_budget: 1.0,
  }
  match graph.validate(duplicate_plan) {
    Ok(_) => test.fail("duplicate worker identity was accepted")?
    Err(_) => {}
  }
}

proc test_graph_readiness_and_results_follow_plan_contract() [error] {
  let first = fixture_node("implementation", "task-a", "dispatch-a", "engineer")?
  let second = fixture_node("replay", "task-a-replay", "dispatch-b", "eval-manager")?
  let a = types.make_node_id("implementation")?
  let b = types.make_node_id("replay")?
  let edge = graph.make_edge(a, b, "hard", "stop-dependents")?
  let run_id = types.make_run_id("run-2")?
  let mode = types.make_mode("organization")?
  let plan = {
    run_id: run_id.value,
    mode: mode.value,
    nodes: [
      first,
      second,
    ],
    edges: [
      edge,
    ],
    source_hashes: [],
    required_outputs: [
      "report.json",
    ],
    aggregate_budget: 1.0,
  }
  test.ok(! graph.startable(plan, "missing", []))?
  test.ok(! graph.startable(plan, "replay", [{node_id: "implementation", state: "started"}]))?
  test.ok(! graph.startable(plan, "replay", [{node_id: "implementation", state: "failed"}]))?
  let continue_plan = {
    run_id: run_id.value,
    mode: mode.value,
    nodes: [
      first,
      second,
    ],
    edges: [
      graph.make_edge(a, b, "replay", "continue-on-failure")?,
    ],
    source_hashes: [],
    required_outputs: [],
    aggregate_budget: 1.0,
  }
  test.ok(graph.startable(continue_plan, "replay", [{node_id: "implementation", state: "failed"}]))?
  test.eq(
    graph.root_result(
      plan,
      [{node_id: "implementation", state: "completed"}, {node_id: "replay", state: "validated"}],
      ["report.json"],
    ),
    "pass",
  )?
  test.eq(
    graph.root_result(plan, [{node_id: "implementation", state: "completed"}, {node_id: "replay", state: "validated"}], []),
    "fail",
  )?
  test.eq(
    graph.root_result(
      plan,
      [{node_id: "implementation", state: "failed"}, {node_id: "replay", state: "validated"}],
      ["report.json"],
    ),
    "fail",
  )?
  match graph.make_node(
    a,
    types.make_role("engineer")?,
    types.make_worker_id("worker")?,
    types.make_dispatch_id("dispatch")?,
    "",
    [],
    [],
    types.make_budget(0.1, 1.0)?,
    [],
  ) {
    Ok(_) => test.fail("incomplete graph node was accepted")?
    Err(_) => {}
  }

  match graph.make_edge(a, a, "hard", "stop-dependents") {
    Ok(_) => test.fail("self-referential graph edge was accepted")?
    Err(_) => {}
  }

  let missing_edge = {
    run_id: run_id.value,
    mode: mode.value,
    nodes: [
      first,
      second,
    ],
    edges: [
      graph.make_edge(a, types.make_node_id("missing")?, "hard", "stop-dependents")?,
    ],
    source_hashes: [],
    required_outputs: [],
    aggregate_budget: 1.0,
  }
  match graph.validate(missing_edge) {
    Ok(_) => test.fail("graph edge to missing node was accepted")?
    Err(_) => {}
  }

  let orphan = {
    run_id: run_id.value,
    mode: mode.value,
    nodes: [
      first,
      second,
    ],
    edges: [],
    source_hashes: [],
    required_outputs: [],
    aggregate_budget: 1.0,
  }
  match graph.validate(orphan) {
    Ok(_) => test.fail("orphan graph node was accepted")?
    Err(_) => {}
  }
}

proc fixture_dispatch() [error] -> Result[dispatch.DispatchSpec] {
  return {
    run_id: types.make_run_id("run-1")?,
    phase_id: types.make_phase_id("01-ticket")?,
    node_id: types.make_node_id("task-a")?,
    dispatch_id: types.make_dispatch_id("dispatch-a")?,
    role: types.make_role("engineer")?,
    worker_id: types.make_worker_id("task-a")?,
    mode: types.make_mode("ticket-implementation")?,
    ticket_id: "task-a",
    eval_id: "task-ecount",
    change_target: "product",
    system_prompt_path: /factory/roles/engineer.md,
    system_prompt_sha256: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    message_path: /factory/runs/run-1/messages/task-a.md,
    message_sha256: "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
    workdir: /product/worktrees/task-a,
    factory_root: /factory,
    product_root: /product,
    handbook_path: /factory/runtime/handbook.md,
    handbook_sha256: "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
    north_star_path: /factory/NORTH-STAR.md,
    north_star_sha256: "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
    source_commit: "source-commit",
    image_id: "not-used",
    budget: types.make_budget(0.35, 1.0)?,
    max_turns: 220,
    max_wall_seconds: 1800,
    parent_controller: "ticket-controller",
    state: "planned",
    claim_token: "claim-a",
  }
}

proc test_dispatch_requires_exact_identity_and_single_claim(ctx: TestContext) [fs, error] {
  let spec = fixture_dispatch()?
  let plan = {run_id: spec.run_id, controller_identity: "controller-1", controller_token: "run-token", specs: [spec]}
  dispatch.validate_plan(plan)?
  let manifest = dispatch.manifest_value(spec)
  test.eq(json.get(manifest, ["dispatch_id"], ""), "dispatch-a")?
  test.eq(json.get(manifest, ["aggregate_budget"], 0.0), 1.0)?
  let invocation = {
    run_id: spec.run_id,
    phase_id: spec.phase_id,
    node_id: spec.node_id,
    dispatch_id: spec.dispatch_id,
    role: spec.role,
    worker_id: spec.worker_id,
    mode: spec.mode,
    ticket_id: spec.ticket_id,
    eval_id: spec.eval_id,
    change_target: spec.change_target,
    system_prompt_path: spec.system_prompt_path,
    system_prompt_sha256: spec.system_prompt_sha256,
    message_path: spec.message_path,
    message_sha256: spec.message_sha256,
    workdir: spec.workdir,
    parent_controller: spec.parent_controller,
  }
  test.ok(dispatch.invocation_authorized(plan, invocation))
  let altered = {
    run_id: spec.run_id,
    phase_id: spec.phase_id,
    node_id: spec.node_id,
    dispatch_id: spec.dispatch_id,
    role: spec.role,
    worker_id: spec.worker_id,
    mode: spec.mode,
    ticket_id: spec.ticket_id,
    eval_id: spec.eval_id,
    change_target: spec.change_target,
    system_prompt_path: spec.system_prompt_path,
    system_prompt_sha256: "altered-prompt",
    message_path: spec.message_path,
    message_sha256: spec.message_sha256,
    workdir: spec.workdir,
    parent_controller: spec.parent_controller,
  }
  test.ok(! dispatch.invocation_authorized(plan, altered))
  let claim = dispatch.claim(spec, "claim-a", "runner-1", "planned")?
  test.eq(claim.state, "claimed")?
  match dispatch.claim(spec, "claim-a", "runner-2", "claimed") {
    Ok(_) => test.fail("dispatch was claimed twice")?
    Err(_) => {}
  }

  let factory_spec = {
    run_id: spec.run_id,
    phase_id: spec.phase_id,
    node_id: spec.node_id,
    dispatch_id: spec.dispatch_id,
    role: spec.role,
    worker_id: spec.worker_id,
    mode: spec.mode,
    ticket_id: spec.ticket_id,
    eval_id: spec.eval_id,
    change_target: "factory",
    system_prompt_path: spec.system_prompt_path,
    system_prompt_sha256: spec.system_prompt_sha256,
    message_path: spec.message_path,
    message_sha256: spec.message_sha256,
    workdir: spec.workdir,
    factory_root: spec.factory_root,
    product_root: spec.product_root,
    handbook_path: spec.handbook_path,
    handbook_sha256: spec.handbook_sha256,
    north_star_path: spec.north_star_path,
    north_star_sha256: spec.north_star_sha256,
    source_commit: spec.source_commit,
    image_id: spec.image_id,
    budget: spec.budget,
    max_turns: spec.max_turns,
    max_wall_seconds: spec.max_wall_seconds,
    parent_controller: spec.parent_controller,
    state: spec.state,
    claim_token: spec.claim_token,
  }
  match dispatch.validate_spec(factory_spec) {
    Ok(_) => test.fail("factory target entered an engineer dispatch")?
    Err(_) => {}
  }

  let root = test.temp_dir(ctx, name: "dispatch-plan")?
  dispatch.persist_plan(root, plan)?
  test.ok(fs.exists(fp"${root}/dispatch/PLAN.json")?)?
  let claim_once = dispatch.claim_once(root, spec, "runner-0")?
  test.eq(claim_once.claimed_by, "runner-0")?
  match dispatch.claim_once(root, spec, "runner-1") {
    Ok(_) => test.fail("dispatch claim was duplicated")?
    Err(_) => {}
  }

  let persisted = test.temp_dir(ctx, name: "persisted-dispatch")?
  dispatch.persist_spec(persisted, spec)?
  test.ok(fs.exists(fp"${persisted}/dispatch/dispatch-a.json")?)?
  dispatch.claim_persisted_once(persisted, "dispatch-a", "claim-a", "runner-1")?
  test.ok(fs.exists(fp"${persisted}/dispatch/dispatch-a.claim.json")?)?
  match dispatch.claim_persisted_once(persisted, "dispatch-a", "claim-a", "runner-2") {
    Ok(_) => test.fail("persisted dispatch was claimed twice")?
    Err(_) => {}
  }
}
