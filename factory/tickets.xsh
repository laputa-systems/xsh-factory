##! Ticket ownership and merge-reconciliation policy.
use factory.control as legacy
use factory.types as types

## Parsed ticket facts used by admission and reconciliation.
export type TicketRecord = {
  id: Any,
  target: Any,
  status: Any,
  eval_id: Str,
  api_surface_ok: Bool,
  open_branch: Str,
}

## Parses one checked-in ticket into typed ownership facts.
export pure parse(ticket_id: Str, text: Str, open_branch: Str = "") -> Result[TicketRecord] {
  let id = types.make_ticket_id(ticket_id)?
  let target = types.parse_change_target(legacy.ticket_change_target(text))?
  let status = types.parse_ticket_status(legacy.ticket_status(text))?
  let eval_id = legacy.ticket_eval(text)
  let api_surface_ok = legacy.ticket_api_surface_gate_ok(text)
  return Ok({
    id: id,
    target: target,
    status: status,
    eval_id: eval_id,
    api_surface_ok: api_surface_ok,
    open_branch: open_branch,
  })
}

## Only product tickets with an accepted status may enter engineer admission.
export pure engineer_dispatchable(ticket: TicketRecord) -> Bool {
  return ticket.target.value == "product" and (ticket.status.value == "Approved." or ticket.status.value == "Accepted.") and ticket.eval_id != "" and ticket.api_surface_ok and ticket.open_branch == ""
}

## A worker may report recommendations, but only CTO reconciliation changes status.
export pure reconciled_status(current: types.TicketStatus, merge_proven: Bool) -> Result[types.TicketStatus] {
  if current.value == "Merged." {
    return Ok(current)
  }
  if merge_proven {
    return types.make_ticket_status("Merged.")
  }
  return Err(types.DomainError.InvalidCombination(message: "ticket merge status requires proven product HEAD"))
}
