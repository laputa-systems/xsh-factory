##! Typed parsing for the Markdown cycle request boundary.
use factory.types as types

## The parsed request is the only request representation admission consumes.
export type CycleRequest = {
  mode: types.CycleMode,
  tickets: List[types.TicketId],
  ticket_policy: Str,
  active_evals: List[types.EvalId],
  trial_count: types.TrialCount,
  design_count: Int,
  allow_measured_reuse: Bool,
  role_overrides: List[Any],
  required_outputs: List[Str],
  aggregate_budget: Float,
}

## Scalar request facts exposed to effectful entrypoints without weakening the
## domain-typed parser or leaking nested module types across the boundary.
export type RequestFacts = {
  mode: Str,
  tickets: List[Str],
  ticket_policy: Str,
  active_evals: List[Str],
  trial_count: Int,
  design_count: Int,
  allow_measured_reuse: Bool,
  aggregate_budget: Float,
}

pure section_lines(text: Str, heading: Str) -> List[Str] {
  var in_section = false
  var lines: List[Str] = []
  for line in text.lines() {
    let trimmed = line.trim()
    if trimmed == f"## ${heading}" {
      in_section = true
      continue
    }

    if in_section and trimmed.starts_with("## ") {
      return lines
    }

    if in_section {
      lines = lines.push(trimmed)
    }
  }

  return lines
}

pure first_quoted(lines: List[Str]) -> Str {
  for line in lines {
    if line.starts_with("- `") {
      let parts = line.split("`")
      if parts.len() >= 2 {
        return parts[1]
      }
    }
  }

  return ""
}

pure list_quoted(lines: List[Str]) -> List[Str] {
  var values: List[Str] = []
  for line in lines {
    if line.starts_with("- `") {
      let parts = line.split("`")
      if parts.len() >= 2 {
        values = values.push(parts[1])
      }
    }
  }

  return values
}

pure count_value(lines: List[Str], fallback: Int) -> Result[Int] {
  for line in lines {
    if line.starts_with("- Count:") {
      let quoted = line.split("`")
      if quoted.len() >= 2 {
        return quoted[1].parse_int()
      }

      let parts = line.split(":")
      if parts.len() >= 2 {
        return parts[1].trim().parse_int()
      }
    }
  }

  fallback
}

pure parsed_ticket_policy(text: Str) -> Str {
  for line in section_lines(text, "Approved tickets") {
    if line == "- None." or line == "- None" {
      return "none"
    }

    if line.starts_with("- `") {
      return "explicit"
    }
  }

  return "auto"
}

## Parses all explicitly named approved tickets.
export pure parse_ticket_ids(text: Str) -> Result[List[types.TicketId]] {
  var values = [types.make_ticket_id(raw)? for raw in list_quoted(section_lines(text, "Approved tickets"))]
  values
}

## Parses the selected active eval identifiers.
export pure parse_eval_ids(text: Str) -> Result[List[types.EvalId]] {
  var values = [types.make_eval_id(raw)? for raw in list_quoted(section_lines(text, "Active evals"))]
  values
}

## Parses the bounded trial count.
export pure parse_trial_count(text: Str) -> Result[types.TrialCount] {
  let count = count_value(section_lines(text, "Trial plan"), 1)?
  return types.make_trial_count(count)
}

## Parses the bounded number of design proposals.
export pure parse_design_count(text: Str) -> Result[Int] {
  let count = count_value(section_lines(text, "New eval proposals"), 0)?
  if count < 0 or count > 1 {
    return Err(types.DomainError.InvalidFormat(kind: "design-count", value: f"${count}"))
  }

  count
}

## Parses the explicit measured-reuse opt-in.
export pure parse_measured_reuse(text: Str) -> Bool {
  for line in text.lines() {
    if "Allow measured eval reuse" in line and ("`yes`" in line or "`true`" in line) {
      return true
    }
  }

  return false
}

## Parses an optional aggregate budget, keeping the hard ceiling in policy.
export pure parse_aggregate_budget(text: Str) -> Result[Float] {
  for line in section_lines(text, "Aggregate budget") {
    if line.starts_with("- USD:") {
      let quoted = line.split("`")
      if quoted.len() >= 2 {
        return quoted[1].parse_float()
      }

      let parts = line.split(":")
      if parts.len() >= 2 {
        return parts[1].trim().parse_float()
      }
    }
  }

  1.0
}

## Parses one immutable CycleRequest before any run directory is created.
export pure parse(text: Str) -> Result[CycleRequest] {
  let parsed_mode_value = first_quoted(section_lines(text, "Mode"))
  if parsed_mode_value == "" {
    return Err(types.DomainError.Missing(value: "Mode"))
  }

  let mode = types.parse_mode(parsed_mode_value)?
  let tickets = parse_ticket_ids(text)?
  let evals = parse_eval_ids(text)?
  let ticket_policy = parsed_ticket_policy(text)
  let design_count = parse_design_count(text)?
  let aggregate_budget = parse_aggregate_budget(text)?
  if aggregate_budget <= 0.0 {
    return Err(types.DomainError.InvalidFormat(kind: "aggregate-budget", value: f"${aggregate_budget}"))
  }

  return Ok({
    mode: mode,
    tickets: tickets,
    ticket_policy: ticket_policy,
    active_evals: evals,
    trial_count: parse_trial_count(text)?,
    design_count: design_count,
    allow_measured_reuse: parse_measured_reuse(text),
    role_overrides: [],
    required_outputs: ["report.json", "events.jsonl"],
    aggregate_budget: aggregate_budget,
  })
}

## Returns the primitive values needed by the stable launcher after parsing.
export pure facts(text: Str) -> Result[RequestFacts] {
  let cycle = parse(text)?
  return Ok({
    mode: types.mode_name(cycle.mode),
    tickets: [ticket.value for ticket in cycle.tickets],
    ticket_policy: cycle.ticket_policy,
    active_evals: [eval_id.value for eval_id in cycle.active_evals],
    trial_count: cycle.trial_count.value,
    design_count: cycle.design_count,
    allow_measured_reuse: cycle.allow_measured_reuse,
    aggregate_budget: cycle.aggregate_budget,
  })
}

## Primitive accessors for effectful entrypoints that cannot import nested
## nominal record fields through the current XSH module boundary.
export pure mode_value(text: Str) -> Result[Str] {
  let cycle = parse(text)?
  types.mode_name(cycle.mode)
}

## Returns explicitly named ticket values.
export pure ticket_values(text: Str) -> Result[List[Str]] {
  let cycle = parse(text)?
  [ticket.value for ticket in cycle.tickets]
}

## Returns the controller ticket-selection policy.
export pure ticket_policy_value(text: Str) -> Result[Str] {
  let cycle = parse(text)?
  cycle.ticket_policy
}

## Returns selected active eval values.
export pure eval_values(text: Str) -> Result[List[Str]] {
  let cycle = parse(text)?
  [eval_id.value for eval_id in cycle.active_evals]
}

## Returns the bounded trial count.
export pure trial_value(text: Str) -> Result[Int] {
  let cycle = parse(text)?
  cycle.trial_count.value
}

## Returns the bounded eval-design count.
export pure design_value(text: Str) -> Result[Int] {
  let cycle = parse(text)?
  cycle.design_count
}

## Returns the explicit measured-reuse permission.
export pure measured_reuse_value(text: Str) -> Result[Bool] {
  let cycle = parse(text)?
  cycle.allow_measured_reuse
}
