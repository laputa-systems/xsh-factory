##! Behavior-level coverage for ticket ownership and eval package gates.
use factory.tickets as tickets
use factory.types as types

proc test_ticket_and_eval_policy_preserves_ownership_and_status() [fs, error] {
  let ticket_text = """# Ticket

## Status

Approved.

## Change target

- `product`

## Source eval and manager

- Eval: `task-ecount`

## Proposed XSH change

Improve an existing behavior.
"""
  let parsed = tickets.parse("task-a", ticket_text)?
  test.ok(tickets.engineer_dispatchable(parsed))?
  test.eq(parsed.eval_id, "task-ecount")?
  test.ok(! tickets.engineer_dispatchable(tickets.parse("task-a", ticket_text, "factory/task-a")?))?
  test.eq(types.ticket_status_name(tickets.reconciled_status(types.make_ticket_status("Approved.")?, true)?), "Merged.")?
  test.eq(types.ticket_status_name(tickets.reconciled_status(types.make_ticket_status("Merged.")?, false)?), "Merged.")?
  match tickets.reconciled_status(types.make_ticket_status("Approved.")?, false) {
    Ok(_) => test.fail("unproven merge was accepted")?
    Err(_) => {}
  }

}
