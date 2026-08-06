##! Typed lifecycle transitions and event-ledger validation.
use factory.types as types

## A state transition accepted by the lifecycle machine.
export type Transition = {
  subject: Str,
  previous: Str,
  next: Str,
  attempt: Int,
  caused_by: Str,
  evidence_ok: Bool,
}

## One canonical lifecycle event.
export type Event = {
  event_id: Str,
  run_id: Str,
  node_id: Str,
  attempt: Int,
  caused_by: Str,
  previous: Str,
  next: Str,
  content_sha256: Str,
}

## The three states remain separate: desired, observed, and validated.
export type NodeObservation = {
  desired: Str,
  process: Str,
  evidence: Str,
}

## Terminal finalization outcome.
export type Finalization = {
  state: Str,
  result: Str,
  evidence_required: Bool,
}

## Checks the single legal transition relation.
export pure transition_allowed(previous: Str, next: Str) -> Bool {
  if previous == next {
    return true
  }

  if next == "failed" or next == "cancelled" or next == "budget-breached" {
    return previous != "accepted" and previous != "reverted"
  }

  if previous == "created" and (next == "admitted" or next == "started") {
    return true
  }

  if previous == "admitted" and next == "started" {
    return true
  }

  if previous == "started" and next == "completed" {
    return true
  }

  if previous == "completed" and next == "validated" {
    return true
  }

  return false
}

## Creates a transition and rejects missing actor/evidence for completion.
export pure transition(
  subject: Str,
  previous: Str,
  next: Str,
  attempt: Int,
  caused_by: Str,
  evidence_ok: Bool,
) -> Result[Transition] {
  if subject == "" or caused_by == "" or attempt < 1 or ! transition_allowed(previous, next) {
    return Err(types.DomainError.InvalidTransition(subject: subject, current: previous, next: next))
  }

  if next == "completed" and ! evidence_ok {
    return Err(types.DomainError.InvalidCombination(message: "completion requires validated evidence"))
  }

  return Ok({
    subject: subject,
    previous: previous,
    next: next,
    attempt: attempt,
    caused_by: caused_by,
    evidence_ok: evidence_ok,
  })
}

pure duplicate_event(events: List[Event]) -> Str {
  var seen: List[Str] = []
  for event in events {
    for prior in seen {
      if prior == event.event_id {
        return prior
      }
    }

    seen = seen.push(event.event_id)
  }

  return ""
}

## Proves uniqueness, attempt monotonicity, legal state movement, and identity.
export pure validate_events(events: List[Event]) -> Result[Unit] {
  if events.len() == 0 {
    return Err(types.DomainError.Missing(value: "lifecycle-events"))
  }

  let duplicate = duplicate_event(events)
  if duplicate != "" {
    return Err(types.DomainError.Duplicate(value: f"event:${duplicate}"))
  }

  var current_subject = ""
  var current_state = "created"
  var current_attempt = 0
  var current_run = ""
  var current_node = ""
  for event in events {
    if event.run_id == "" or event.node_id == "" or event.caused_by == "" or event.event_id == "" {
      return Err(types.DomainError.InvalidCombination(message: "event is missing subject identity"))
    }

    if current_run == "" {
      current_run = event.run_id
      current_node = event.node_id
      current_subject = event.node_id
    }

    if event.run_id != current_run or event.node_id != current_node {
      return Err(types.DomainError.InvalidCombination(message: "event ledger mixes run or node identities"))
    }

    if event.previous != current_state {
      return Err(
        types.DomainError.InvalidTransition(subject: current_subject, current: current_state, next: event.next),
      )
    }

    if ! types.valid_hash_text(event.content_sha256) {
      return Err(types.DomainError.InvalidFormat(kind: "event-content-hash", value: event.content_sha256))
    }

    if event.attempt < current_attempt or event.attempt > current_attempt + 1 {
      return Err(types.DomainError.InvalidCombination(message: "event attempt is not monotonic"))
    }

    if event.attempt == current_attempt + 1 and event.next != "started" and current_attempt > 0 {
      return Err(types.DomainError.InvalidCombination(message: "new attempts must begin at started"))
    }

    if ! transition_allowed(current_state, event.next) {
      return Err(
        types.DomainError.InvalidTransition(subject: current_subject, current: current_state, next: event.next),
      )
    }

    current_state = event.next
    current_attempt = event.attempt
  }

  if current_state != "completed" and current_state != "validated" and current_state != "failed" and current_state != "cancelled" and current_state != "budget-breached" {
    return Err(types.DomainError.InvalidCombination(message: "lifecycle ledger has no terminal event"))
  }
}

## Finalizes only after process observation and evidence validation agree.
export pure finalize(observation: NodeObservation, cancellation: Bool, budget_breach: Bool) -> Result[Finalization] {
  if budget_breach {
    return Ok({state: "budget-breached", result: "fail", evidence_required: false})
  }

  if cancellation {
    return Ok({state: "cancelled", result: "fail", evidence_required: false})
  }

  if observation.process != "exited" {
    return Err(types.DomainError.InvalidCombination(message: "cannot finalize a live process"))
  }

  if observation.evidence != "valid" {
    return Ok({state: "failed", result: "fail", evidence_required: true})
  }

  return Ok({state: "completed", result: "pass", evidence_required: true})
}
