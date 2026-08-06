##! Behavior-level coverage for typed admission gates.
use factory.policy as policy
use factory.types as types

proc test_admission_accepts_only_a_bounded_owned_plan() [error] {
  let ticket_id = types.make_ticket_id("task-a")?
  let eval_id = types.make_eval_id("task-ecount")?
  let ticket = {id: ticket_id, target: types.make_change_target("product")?, status: types.make_ticket_status("Approved.")?, eval_id: eval_id.value, api_surface_ok: true, open_branch: ""}
  let eval = {id: eval_id, status: types.make_eval_status("Approved.")?}
  let cycle = {
    mode: "organization",
    tickets: [ticket_id],
    active_evals: [eval_id],
    aggregate_budget: 0.75,
    required_outputs: ["report.json"],
  }
  let repository = {factory_root_ok: true, product_root_ok: true, product_clean: true, active_run_clear: true, lock_clear: true}
  let portfolio = {eval_count: 1, evals: [eval], tickets: [ticket], handbook_dispositioned: true}
  let admission = policy.admit(cycle, repository, portfolio)?
  test.eq(admission.tickets.len(), 1)?
  test.eq(admission.evals.len(), 1)?
  test.eq(admission.aggregate_budget, 0.75)?
  test.eq(policy.max_eval_contracts(), 30)?
  test.eq(policy.max_concurrent_engineers(), 2)?
  test.eq(policy.max_cycle_budget(), 1.0)?
  test.ok(policy.eval_dispatchable(eval))?
  test.ok(policy.factory_target_rejected({id: ticket.id, target: types.make_change_target("factory")?, status: ticket.status, eval_id: ticket.eval_id, api_surface_ok: true, open_branch: ""}))?
  test.ok(! policy.eval_dispatchable({id: eval.id, status: types.make_eval_status("Draft.")?}))?

  match policy.admit(cycle, {factory_root_ok: true, product_root_ok: true, product_clean: false, active_run_clear: true, lock_clear: true}, portfolio) {
    Ok(_) => test.fail("a dirty product checkout was admitted")?
    Err(_) => {}
  }
  match policy.admit(cycle, repository, {eval_count: 31, evals: [eval], tickets: [ticket], handbook_dispositioned: true}) {
    Ok(_) => test.fail("an over-cap eval portfolio was admitted")?
    Err(_) => {}
  }
}
