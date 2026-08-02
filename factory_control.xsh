##! Pure contracts shared by the factory controller and its native tests.

## One placeholder value used to fill a checked-in Markdown template.
export type TemplateValue = {key: Str, value: Str}

## Reads the deterministic workflow mode from a cycle request.
export pure request_mode(text: Str) -> Str {
  var in_mode = false
  for line in text.lines() {
    let trimmed = line.trim()
    if trimmed == "## Mode" {
      in_mode = true
      continue
    }
    if in_mode and trimmed.starts_with("## ") {
      return "eval"
    }
    if in_mode and trimmed.starts_with("- `") {
      let parts = trimmed.split("`")
      if parts.len() >= 2 {
        return parts[1]
      }
    }
    if in_mode and trimmed.starts_with("- ") {
      let parts = trimmed.split(" ")
      if parts.len() >= 2 {
        return parts[1]
      }
    }
  }
  return "eval"
}

## Reads the first active eval identifier from a cycle request.
export pure request_eval(text: Str) -> Str {
  var in_active_evals = false
  for line in text.lines() {
    let trimmed = line.trim()
    if trimmed == "## Active evals" {
      in_active_evals = true
      continue
    }
    if in_active_evals and trimmed.starts_with("## ") {
      return ""
    }
    if in_active_evals and trimmed.starts_with("- `") {
      let parts = trimmed.split("`")
      if parts.len() >= 2 {
        return parts[1]
      }
    }
  }
  return ""
}

## Reads the explicitly approved ticket identifiers from a cycle request.
export pure request_tickets(text: Str) -> List[Str] {
  var in_tickets = false
  var tickets: List[Str] = []
  for line in text.lines() {
    let trimmed = line.trim()
    if trimmed == "## Approved tickets" {
      in_tickets = true
      continue
    }
    if in_tickets and trimmed.starts_with("## ") {
      return tickets
    }
    if in_tickets and trimmed.starts_with("- `") {
      let parts = trimmed.split("`")
      if parts.len() >= 2 {
        tickets = tickets.push(parts[1])
      }
    }
  }
  return tickets
}

## Rejects ticket identifiers that could escape the ticket/worktree namespace.
export pure valid_ticket_id(ticket_id: Str) -> Bool {
  return ticket_id != "" and ! ticket_id.contains("/") and ! ticket_id.contains("..") and
    ! ticket_id.contains("\\") and ! ticket_id.contains(" ")
}

## Requires the checked-in approval state used for cycle admission.
export pure ticket_is_accepted(text: Str) -> Bool {
  return text.contains("## Status\n\nAccepted.")
}

## Defines the controller's legal lifecycle transitions.
export pure transition_allowed(current: Str, next: Str) -> Bool {
  if current == next {
    return true
  }
  if next == "failed" or next == "cancelled" {
    return current != "ready-for-review" and current != "accepted" and current != "reverted"
  }
  if current == "created" and next == "started" { return true }
  if current == "created" and next == "admitted" { return true }
  if current == "admitted" and next == "started" { return true }
  if current == "started" and next == "completed" { return true }
  if current == "completed" and next == "validated" { return true }
  if current == "validated" and next == "ready-for-review" { return true }
  if current == "ready-for-review" and next == "accepted" { return true }
  if current == "accepted" and next == "reverted" { return true }
  return false
}

## Permits retries only for bounded transient worker failures.
export pure retry_allowed(failure_class: Str, attempt: Int, max_attempts: Int) -> Bool {
  if attempt < 1 or max_attempts < 1 or attempt >= max_attempts {
    return false
  }
  return failure_class == "worker-failed" or failure_class == "transient-harness" or
    failure_class == "budget-breach"
}

## Validates a Markdown report without interpreting its narrative content.
export pure report_contract_ok(report: Str, required_sections: List[Str], expected_result: Str) -> Bool {
  if expected_result != "" and ! report.contains(f"## Result\n\n${expected_result}") {
    return false
  }
  for section in required_sections {
    if ! report.contains(f"## ${section}") {
      return false
    }
  }
  return true
}

## Fills a checked-in Markdown template without embedding its contract in code.
export pure fill_template(template: Str, values: List[TemplateValue]) -> Str {
  var rendered = template
  for value in values {
    rendered = rendered.replace("{{" + value.key + "}}", value.value)
  }
  return rendered
}
