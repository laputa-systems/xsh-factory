##! Pure admission policy and typed portfolio gates.

use factory.types as types
use factory.request as request

## A checked-in ticket candidate supplied by CTO inventory.
export type TicketCandidate = {
  id: Any,
  target: Any,
  status: Any,
  eval_id: Str,
  api_surface_ok: Bool,
  open_branch: Str,
}

## A checked-in eval candidate supplied by portfolio inventory.
export type EvalCandidate = {
  id: Any,
  status: Any,
}

## Repository facts required before paid admission.
export type RepositoryState = {
  factory_root_ok: Bool,
  product_root_ok: Bool,
  product_clean: Bool,
  active_run_clear: Bool,
  lock_clear: Bool,
}

## Portfolio facts required before paid admission.
export type PortfolioState = {
  eval_count: Int,
  evals: List[Any],
  tickets: List[Any],
  handbook_dispositioned: Bool,
}

## A typed reason that blocks admission; prose is never reinterpreted later.
export type AdmissionBlock =
  InvalidRequest(Str)
| RepositoryBoundary(Str)
| RepositoryDirty
| ActiveRun
| LockHeld
| HandbookUndispositioned
| EvalCap(Int)
| MissingEval(Str)
| DisabledEval(Str)
| MissingTicket(Str)
| FactoryTicket(Str)
| TicketStatusBlocked(Str)
| TicketApiSurface(Str)
| OpenBranch(Str)
| DuplicateIdentity(Str)
| BudgetBlocked
| TooManyEngineers(Int)

## The immutable result of admission.
export type AdmissionPlan = {
  request: Any,
  tickets: List[Any],
  evals: List[Any],
  aggregate_budget: Float,
  required_outputs: List[Str],
}

## Hard limits are kept next to admission rather than reconstructed by controllers.
export pure max_eval_contracts() -> Int { return 30 }
## Maximum concurrent engineer rows.
export pure max_concurrent_engineers() -> Int { return 2 }
## Aggregate paid-cycle ceiling.
export pure max_cycle_budget() -> Float { return 1.0 }

pure ticket_is_engineer_dispatchable(ticket: TicketCandidate) -> Bool {
  return ticket.target.value == "product" and
    (ticket.status.value == "Approved." or ticket.status.value == "Accepted.") and
    ticket.eval_id != "" and ticket.api_surface_ok and ticket.open_branch == ""
}

## Factory-owned work is never engineer-dispatchable.
export pure factory_target_rejected(ticket: TicketCandidate) -> Bool {
  return ticket.target.value == "factory"
}

## Tests whether an eval is eligible for paid work.
export pure eval_dispatchable(eval: EvalCandidate) -> Bool {
  return eval.status.value == "Approved."
}

pure find_eval(evals: List[Any], eval_id: Str) -> Any {
  for candidate in evals {
    if candidate.id.value == eval_id { return candidate }
  }
  return {id: {value: ""}, status: {value: "Draft."}}
}

pure find_ticket(tickets: List[Any], ticket_id: Str) -> Any {
  for candidate in tickets {
    if candidate.id.value == ticket_id { return candidate }
  }
  return {id: {value: ""}, target: {value: "factory"}, status: {value: "Closed."}, eval_id: "", api_surface_ok: false, open_branch: ""}
}

pure duplicate_strings(values: List[Str]) -> Str {
  var seen: List[Str] = []
  for value in values {
    for previous in seen {
      if previous == value { return value }
    }
    seen = seen.push(value)
  }
  return ""
}

## Performs every deterministic admission gate and returns one immutable plan.
export pure admit(
  cycle: Any,
  repository: RepositoryState,
  portfolio: PortfolioState,
) -> Result[AdmissionPlan] {
  if ! repository.factory_root_ok or ! repository.product_root_ok {
    return Err(types.DomainError.InvalidCombination(message: "repository roots are not controller-owned"))
  }
  if ! repository.product_clean { return Err(types.DomainError.InvalidCombination(message: "product checkout is dirty")) }
  if ! repository.active_run_clear { return Err(types.DomainError.InvalidCombination(message: "another run is active")) }
  if ! repository.lock_clear { return Err(types.DomainError.InvalidCombination(message: "factory admission lock is held")) }
  if ! portfolio.handbook_dispositioned {
    return Err(types.DomainError.InvalidCombination(message: "handbook candidate lacks a disposition"))
  }
  if portfolio.eval_count > max_eval_contracts() {
    return Err(types.DomainError.InvalidFormat(kind: "eval-cap", value: f"${portfolio.eval_count}"))
  }
  if cycle.aggregate_budget > max_cycle_budget() {
    return Err(types.DomainError.InvalidFormat(kind: "aggregate-budget", value: f"${cycle.aggregate_budget}"))
  }
  let ticket_names = [ticket.value for ticket in cycle.tickets]
  let duplicate_ticket = duplicate_strings(ticket_names)
  if duplicate_ticket != "" {
    return Err(types.DomainError.Duplicate(value: duplicate_ticket))
  }
  if cycle.tickets.len() > max_concurrent_engineers() {
    return Err(types.DomainError.InvalidFormat(kind: "engineer-count", value: f"${cycle.tickets.len()}"))
  }
  var admitted_tickets: List[TicketCandidate] = []
  for ticket_id in cycle.tickets {
    let ticket = find_ticket(portfolio.tickets, ticket_id.value)
    if ticket.id.value == "" {
      return Err(types.DomainError.Missing(value: f"ticket:${ticket_id.value}"))
    }
    let candidate = ticket
    if factory_target_rejected(candidate) { return Err(types.DomainError.InvalidCombination(message: f"factory ticket is CTO-owned: ${ticket_id.value}")) }
    if candidate.status.value != "Approved." and candidate.status.value != "Accepted." {
      return Err(types.DomainError.InvalidCombination(message: f"ticket is not approved: ${ticket_id.value}"))
    }
    if ! candidate.api_surface_ok { return Err(types.DomainError.InvalidCombination(message: f"ticket API-surface gate failed: ${ticket_id.value}")) }
    if candidate.open_branch != "" { return Err(types.DomainError.InvalidCombination(message: f"ticket has an open branch: ${ticket_id.value}")) }
    let linked = find_eval(portfolio.evals, candidate.eval_id)
    if linked.id.value == "" {
      return Err(types.DomainError.Missing(value: f"eval:${candidate.eval_id}"))
    }
    let eval = linked
    if ! eval_dispatchable(eval) { return Err(types.DomainError.InvalidCombination(message: f"linked eval is not approved: ${candidate.eval_id}")) }
    admitted_tickets = admitted_tickets.push(candidate)
  }
  var admitted_evals: List[EvalCandidate] = []
  for eval_id in cycle.active_evals {
    let candidate = find_eval(portfolio.evals, eval_id.value)
    if candidate.id.value == "" {
      return Err(types.DomainError.Missing(value: f"eval:${eval_id.value}"))
    }
    let eval = candidate
    if ! eval_dispatchable(eval) { return Err(types.DomainError.InvalidCombination(message: f"eval is not approved: ${eval_id.value}")) }
    admitted_evals = admitted_evals.push(eval)
  }
  return Ok({request: cycle, tickets: admitted_tickets, evals: admitted_evals, aggregate_budget: cycle.aggregate_budget, required_outputs: cycle.required_outputs})
}
