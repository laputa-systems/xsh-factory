##! Native tests for canonical factory types, paths, requests, and admission.
use factory.paths as paths
use factory.policy as policy
use factory.request as request
use factory.types as types

proc test_domain_constructors_reject_unsafe_values() [error] {
  match types.make_ticket_id("ticket/escape") {
    Ok(_) => test.fail("unsafe ticket id was accepted")?
    Err(_) => {}
  }

  match types.make_run_id("run-../escape") {
    Ok(_) => test.fail("unsafe run id was accepted")?
    Err(_) => {}
  }

  match types.make_trial_count(3) {
    Ok(_) => test.fail("out-of-bound trial count was accepted")?
    Err(_) => {}
  }

  match types.make_budget(0.60, 0.50) {
    Ok(_) => test.fail("role budget exceeded aggregate budget")?
    Err(_) => {}
  }

  test.eq(types.role_name(types.make_role("eval-worker")?), "eval-worker")?
  test.eq(types.mode_name(types.make_mode("organization")?), "organization")?
  test.eq(types.ticket_status_name(types.make_ticket_status("too difficult")?), "too difficult")?
}

proc test_domain_vocabulary_round_trips_and_boundaries() [error] {
  let digest = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  test.ok(types.valid_identifier("task-a"))?
  test.ok(! types.valid_identifier("task/a"))?
  test.ok(types.valid_hash_text(digest))?
  test.ok(! types.valid_hash_text("short"))?
  test.eq(types.make_ticket_id("task-a")?.value, "task-a")?
  test.eq(types.make_eval_id("task-eval")?.value, "task-eval")?
  test.eq(types.make_worker_id("worker-1")?.value, "worker-1")?
  test.eq(types.make_run_id("run-1")?.value, "run-1")?
  test.eq(types.make_phase_id("01-eval")?.value, "01-eval")?
  test.eq(types.make_node_id("node-a")?.value, "node-a")?
  test.eq(types.make_dispatch_id("dispatch-a")?.value, "dispatch-a")?
  test.eq(types.make_content_hash("session", digest)?.value, digest)?
  test.eq(types.make_assignment_hash(digest)?.value, digest)?
  test.eq(types.make_prompt_hash(digest)?.value, digest)?
  test.eq(types.make_commit_hash(digest)?.value, digest)?
  test.eq(types.make_trial_count(2)?.value, 2)?
  test.eq(types.make_budget(0.0, 1.0)?.aggregate_limit, 1.0)?
  test.eq(types.role_name(types.parse_role("CTO")?), "CTO")?
  test.eq(types.mode_name(types.parse_mode("eval")?), "eval")?
  test.eq(types.change_target_name(types.parse_change_target("factory")?), "factory")?
  test.eq(types.ticket_status_name(types.parse_ticket_status("Merged.")?), "Merged.")?
  test.eq(types.eval_status_name(types.parse_eval_status("Disabled.")?), "Disabled.")?
  test.eq(types.lifecycle_name({value: "validated"}), "validated")?
  match types.make_budget(-0.1, 1.0) {
    Ok(_) => test.fail("negative role budget was accepted")?
    Err(_) => {}
  }

  match types.make_content_hash("session", "short") {
    Ok(_) => test.fail("short content hash was accepted")?
    Err(_) => {}
  }
}

proc test_paths_are_absolute_and_separator_bounded() [error] {
  let factory = paths.make_factory_root(/srv/factory)?
  let product = paths.make_product_root(/srv/xsh, factory)?
  test.ok(paths.within(factory.root_path, /srv/factory/runs/run-1/report.json)?)
  test.ok(! paths.within(factory.root_path, /srv/factory-old/report.json)?)
  match paths.make_factory_path(factory, p"relative/report.json") {
    Ok(_) => test.fail("relative factory path was accepted")?
    Err(_) => {}
  }

  match paths.make_product_worktree(product, factory, /srv/factory/worktree, "factory/task", "abc") {
    Ok(_) => test.fail("factory path was accepted as a product worktree")?
    Err(_) => {}
  }

  let worktree = paths.make_product_worktree(product, factory, /srv/xsh/worktree, "factory-task", "abc")?
  test.eq(worktree.worktree_path.display(), "/srv/xsh/worktree")?
}

proc test_scoped_paths_preserve_repository_boundaries(ctx: TestContext) [fs, error] {
  let root = test.temp_dir(ctx, name: "scoped-paths")?
  let factory_path = fp"${root}/factory"
  let product_path = fp"${root}/product"
  let runs_path = fp"${factory_path}/runs"
  let run_path = fp"${runs_path}/run-1"
  let phase_path = fp"${run_path}/01-ticket"
  let worker_path = fp"${phase_path}/worker-a"
  for directory in [factory_path, product_path, runs_path, run_path, phase_path, worker_path] {
    fs.mkdir(directory)?
  }

  test.eq(paths.canonical_absolute(/srv//factory/)?.display(), "/srv/factory")?
  test.ok(paths.within(/, /anything)?)?
  test.ok(paths.real_within(factory_path, run_path)?)?
  let factory = paths.make_factory_root(factory_path)?
  let _ = paths.make_product_root(product_path, factory)?
  let run_root = paths.make_run_root(factory, run_path)?
  let phase = paths.make_phase_root(run_root, "01-ticket", phase_path)?
  let worker = paths.make_worker_root(phase, "worker-a", worker_path)?
  test.eq(run_root.run_id, "run-1")?
  test.eq(phase.phase_id, "01-ticket")?
  test.eq(worker.worker_id, "worker-a")?
  let run_report = fp"${run_path}/report.json"
  let phase_report = fp"${phase_path}/report.json"
  let worker_report = fp"${worker_path}/report.json"
  let run_evidence = paths.make_run_path(run_root, run_report)?
  let phase_evidence = paths.make_phase_path(phase, phase_report)?
  let worker_evidence = paths.make_worker_path(worker, worker_report)?
  test.eq(run_evidence.value.display(), run_report.display())?
  test.eq(phase_evidence.value.display(), phase_report.display())?
  test.eq(worker_evidence.value.display(), worker_report.display())?
  match paths.canonical_absolute(p"relative") {
    Ok(_) => test.fail("relative path was canonicalized")?
    Err(_) => {}
  }

  match paths.canonical_absolute(/srv/../factory) {
    Ok(_) => test.fail("traversal path was canonicalized")?
    Err(_) => {}
  }

  match paths.make_product_root(factory_path, factory) {
    Ok(_) => test.fail("factory checkout was accepted as product root")?
    Err(_) => {}
  }

  match paths.make_run_root(factory, /outside/run-1) {
    Ok(_) => test.fail("outside run root was accepted")?
    Err(_) => {}
  }

  match paths.make_worker_path(worker, /outside/report.json) {
    Ok(_) => test.fail("outside worker path was accepted")?
    Err(_) => {}
  }
}

proc test_cycle_request_is_typed_and_bounded() [error] {
  let text = """# Cycle

## Mode

- `organization`

## Active evals

- `task-ecount`

## Trial plan

- Count: `1`

## New eval proposals

- Count: `1`

## Approved tickets

- `task-a`

## Aggregate budget

- USD: `0.75`
"""
  let cycle = request.parse(text)?
  test.eq(types.mode_name(cycle.mode), "organization")?
  test.eq(cycle.tickets.len(), 1)?
  test.eq(cycle.active_evals[0].value, "task-ecount")?
  test.eq(cycle.trial_count.value, 1)?
  test.eq(cycle.design_count, 1)?
  test.eq(cycle.aggregate_budget, 0.75)?
}

proc test_cycle_request_defaults_and_scalar_accessors() [error] {
  let text = """# Cycle

## Mode

- `eval`

## Approved tickets

- None.

## Aggregate budget

- USD: 0.50
"""
  let facts = request.facts(text)?
  test.eq(facts.mode, "eval")?
  test.eq(facts.tickets, [])?
  test.eq(facts.ticket_policy, "none")?
  test.eq(facts.active_evals, [])?
  test.eq(facts.trial_count, 1)?
  test.eq(facts.design_count, 0)?
  test.ok(! facts.allow_measured_reuse)?
  test.eq(facts.aggregate_budget, 0.50)?
  test.eq(request.mode_value(text)?, "eval")?
  test.eq(request.ticket_values(text)?, [])?
  test.eq(request.ticket_policy_value(text)?, "none")?
  test.eq(request.eval_values(text)?, [])?
  test.eq(request.trial_value(text)?, 1)?
  test.eq(request.design_value(text)?, 0)?
  test.ok(! request.measured_reuse_value(text)?)
  let colon = """# Cycle

## Mode

- `eval`

## Trial plan

- Count: 2

## New eval proposals

- Count: 1

## Aggregate budget

- USD: 0.25
"""
  test.eq(request.parse_trial_count(colon)?.value, 2)?
  test.eq(request.parse_design_count(colon)?, 1)?
}

proc test_admission_returns_one_plan_and_rejects_factory_work() [error] {
  let cycle = request.parse("""# Cycle

## Mode

- `ticket-implementation`

## Active evals

- `task-ecount`

## Approved tickets

- `task-a`
""")?
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
  let plan = policy.admit(
    cycle,
    {factory_root_ok: true, product_root_ok: true, product_clean: true, active_run_clear: true, lock_clear: true},
    {eval_count: 1, evals: [eval], tickets: [ticket], handbook_dispositioned: true},
  )?
  test.eq(plan.tickets.len(), 1)?
  test.eq(plan.evals.len(), 1)?

  let factory_ticket = {
    id: ticket_id,
    target: types.make_change_target("factory")?,
    status: types.make_ticket_status("Approved.")?,
    eval_id: eval_id.value,
    api_surface_ok: true,
    open_branch: "",
  }
  match policy.admit(
    cycle,
    {factory_root_ok: true, product_root_ok: true, product_clean: true, active_run_clear: true, lock_clear: true},
    {eval_count: 1, evals: [eval], tickets: [factory_ticket], handbook_dispositioned: true},
  ) {
    Ok(_) => test.fail("factory-owned ticket entered engineer admission")?
    Err(_) => {}
  }
}

proc test_admission_fails_closed_for_portfolio_and_repository_boundaries() [error] {
  let cycle = request.parse("""# Cycle

## Mode

- `ticket-implementation`

## Approved tickets

- `task-a`
""")?
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
  let repository = {
    factory_root_ok: true,
    product_root_ok: true,
    product_clean: true,
    active_run_clear: true,
    lock_clear: true,
  }
  let portfolio = {eval_count: 1, evals: [eval], tickets: [ticket], handbook_dispositioned: true}
  let accepted = policy.admit(cycle, repository, portfolio)?
  test.eq(accepted.tickets.len(), 1)?
  let no_factory_root = {
    factory_root_ok: false,
    product_root_ok: true,
    product_clean: true,
    active_run_clear: true,
    lock_clear: true,
  }
  let dirty_product = {
    factory_root_ok: true,
    product_root_ok: true,
    product_clean: false,
    active_run_clear: true,
    lock_clear: true,
  }
  let active_run = {
    factory_root_ok: true,
    product_root_ok: true,
    product_clean: true,
    active_run_clear: false,
    lock_clear: true,
  }
  let held_lock = {
    factory_root_ok: true,
    product_root_ok: true,
    product_clean: true,
    active_run_clear: true,
    lock_clear: false,
  }
  match policy.admit(cycle, no_factory_root, portfolio) {
    Ok(_) => test.fail("invalid factory root entered admission")?
    Err(_) => {}
  }

  match policy.admit(cycle, dirty_product, portfolio) {
    Ok(_) => test.fail("dirty product checkout entered admission")?
    Err(_) => {}
  }

  match policy.admit(cycle, active_run, portfolio) {
    Ok(_) => test.fail("active run did not block admission")?
    Err(_) => {}
  }

  match policy.admit(cycle, held_lock, portfolio) {
    Ok(_) => test.fail("held admission lock did not block admission")?
    Err(_) => {}
  }

  let no_handbook = {eval_count: 1, evals: [eval], tickets: [ticket], handbook_dispositioned: false}
  let too_many_evals = {eval_count: 31, evals: [eval], tickets: [ticket], handbook_dispositioned: true}
  let no_ticket = {eval_count: 1, evals: [eval], tickets: [], handbook_dispositioned: true}
  match policy.admit(cycle, repository, no_handbook) {
    Ok(_) => test.fail("undispositioned handbook entered admission")?
    Err(_) => {}
  }

  match policy.admit(cycle, repository, too_many_evals) {
    Ok(_) => test.fail("eval portfolio cap was ignored")?
    Err(_) => {}
  }

  match policy.admit(cycle, repository, no_ticket) {
    Ok(_) => test.fail("missing ticket was admitted")?
    Err(_) => {}
  }

  let duplicate_cycle = {
    mode: cycle.mode,
    tickets: [
      ticket_id,
      ticket_id,
    ],
    ticket_policy: cycle.ticket_policy,
    active_evals: cycle.active_evals,
    trial_count: cycle.trial_count,
    design_count: cycle.design_count,
    allow_measured_reuse: cycle.allow_measured_reuse,
    role_overrides: cycle.role_overrides,
    required_outputs: cycle.required_outputs,
    aggregate_budget: cycle.aggregate_budget,
  }
  match policy.admit(duplicate_cycle, repository, portfolio) {
    Ok(_) => test.fail("duplicate ticket entered admission")?
    Err(_) => {}
  }

  let factory_ticket = {
    id: ticket_id,
    target: types.make_change_target("factory")?,
    status: types.make_ticket_status("Approved.")?,
    eval_id: eval_id.value,
    api_surface_ok: true,
    open_branch: "",
  }
  let factory_portfolio = {eval_count: 1, evals: [eval], tickets: [factory_ticket], handbook_dispositioned: true}
  match policy.admit(cycle, repository, factory_portfolio) {
    Ok(_) => test.fail("factory ticket entered engineer admission")?
    Err(_) => {}
  }
}
