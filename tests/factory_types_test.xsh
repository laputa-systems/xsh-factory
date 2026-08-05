##! Native tests for canonical factory types, paths, requests, and admission.

use factory.types as types
use factory.paths as paths
use factory.request as request
use factory.policy as policy

proc test_domain_constructors_reject_unsafe_values() [error] {
  match types.make_ticket_id("ticket/escape") {
    Ok(_) => test.fail("unsafe ticket id was accepted")?,
    Err(_) => {},
  }
  match types.make_run_id("run-../escape") {
    Ok(_) => test.fail("unsafe run id was accepted")?,
    Err(_) => {},
  }
  match types.make_trial_count(3) {
    Ok(_) => test.fail("out-of-bound trial count was accepted")?,
    Err(_) => {},
  }
  match types.make_budget(0.60, 0.50) {
    Ok(_) => test.fail("role budget exceeded aggregate budget")?,
    Err(_) => {},
  }
  test.eq(types.role_name(types.make_role("eval-worker")?), "eval-worker")?
  test.eq(types.mode_name(types.make_mode("organization")?), "organization")?
  test.eq(types.ticket_status_name(types.make_ticket_status("too difficult")?), "too difficult")?
}

proc test_paths_are_absolute_and_separator_bounded() [error] {
  let factory = paths.make_factory_root(Path("/srv/factory"))?
  let product = paths.make_product_root(Path("/srv/xsh"), factory)?
  test.ok(paths.within(factory.root_path, Path("/srv/factory/runs/run-1/report.json"))?)
  test.ok(! paths.within(factory.root_path, Path("/srv/factory-old/report.json"))?)
  match paths.make_factory_path(factory, Path("relative/report.json")) {
    Ok(_) => test.fail("relative factory path was accepted")?,
    Err(_) => {},
  }
  match paths.make_product_worktree(product, factory, Path("/srv/factory/worktree"), "factory/task", "abc") {
    Ok(_) => test.fail("factory path was accepted as a product worktree")?,
    Err(_) => {},
  }
  let worktree = paths.make_product_worktree(product, factory, Path("/srv/xsh/worktree"), "factory-task", "abc")?
  test.eq(worktree.worktree_path.display(), "/srv/xsh/worktree")?
}

proc test_cycle_request_is_typed_and_bounded() [error] {
  let text = "# Cycle\n\n## Mode\n\n- `organization`\n\n## Active evals\n\n- `task-ecount`\n\n## Trial plan\n\n- Count: `1`\n\n## New eval proposals\n\n- Count: `1`\n\n## Approved tickets\n\n- `task-a`\n\n## Aggregate budget\n\n- USD: `0.75`\n"
  let cycle = request.parse(text)?
  test.eq(types.mode_name(cycle.mode), "organization")?
  test.eq(cycle.tickets.len(), 1)?
  test.eq(cycle.active_evals[0].value, "task-ecount")?
  test.eq(cycle.trial_count.value, 1)?
  test.eq(cycle.design_count, 1)?
  test.eq(cycle.aggregate_budget, 0.75)?
}

proc test_admission_returns_one_plan_and_rejects_factory_work() [error] {
  let cycle = request.parse("# Cycle\n\n## Mode\n\n- `ticket-implementation`\n\n## Active evals\n\n- `task-ecount`\n\n## Approved tickets\n\n- `task-a`\n")?
  let ticket_id = types.make_ticket_id("task-a")?
  let eval_id = types.make_eval_id("task-ecount")?
  let ticket = {
    id: ticket_id,
    target: types.make_change_target("product")?,
    status: types.make_ticket_status("Approved.")?,
    eval_id: eval_id.value,
    api_surface_ok: true,
    open_branch: "",
  }
  let eval = {id: eval_id, status: types.make_eval_status("Approved.")?}
  let plan = policy.admit(cycle,
    {factory_root_ok: true, product_root_ok: true, product_clean: true, active_run_clear: true, lock_clear: true},
    {eval_count: 1, evals: [eval], tickets: [ticket], handbook_dispositioned: true})?
  test.eq(plan.tickets.len(), 1)?
  test.eq(plan.evals.len(), 1)?

  let factory_ticket = {id: ticket_id, target: types.make_change_target("factory")?, status: types.make_ticket_status("Approved.")?, eval_id: eval_id.value, api_surface_ok: true, open_branch: ""}
  match policy.admit(cycle,
    {factory_root_ok: true, product_root_ok: true, product_clean: true, active_run_clear: true, lock_clear: true},
    {eval_count: 1, evals: [eval], tickets: [factory_ticket], handbook_dispositioned: true}) {
    Ok(_) => test.fail("factory-owned ticket entered engineer admission")?,
    Err(_) => {},
  }
}
