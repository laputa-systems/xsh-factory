##! Pure contracts shared by the factory controller and its native tests.

## One placeholder value used to fill a checked-in Markdown template.
export type TemplateValue = {key: Str, value: Str}

## Reads the current lifecycle marker from a ticket.
export pure ticket_status(text: Str) -> Str {
  var in_status = false
  for line in text.lines() {
    let trimmed = line.trim()
    if trimmed == "## Status" {
      in_status = true
      continue
    }
    if in_status and trimmed.starts_with("## ") {
      return ""
    }
    if in_status and trimmed != "" {
      return trimmed
    }
  }
  return ""
}

## Reads the eval identifier linked from a ticket.
export pure ticket_eval(text: Str) -> Str {
  var in_source = false
  for line in text.lines() {
    let trimmed = line.trim()
    if trimmed == "## Source eval and manager" {
      in_source = true
      continue
    }
    if in_source and trimmed.starts_with("## ") {
      return ""
    }
    if in_source and trimmed.starts_with("- Eval:") {
      let parts = trimmed.split("`")
      if parts.len() >= 2 {
        return parts[1]
      }
      return trimmed.replace("- Eval:", "").trim()
    }
  }
  return ""
}

## The role names and defaults are the single launcher configuration source.
export pure role_prefix(role: Str) -> Str {
  if role == "director" { return "DIRECTOR" }
  if role == "eval-designer" { return "EVAL_DESIGNER" }
  if role == "eval-manager" { return "EVAL_MANAGER" }
  if role == "eval-worker" { return "EVAL_WORKER" }
  if role == "xsh-swe" { return "XSH_SWE" }
  return ""
}

## Selects the default provider for a known factory role.
export pure default_provider(role: Str) -> Str {
  if role_prefix(role) != "" { return "openrouter" }
  return ""
}

## Selects the default model for a known factory role.
export pure default_model(role: Str) -> Str {
  if role_prefix(role) != "" { return "deepseek/deepseek-v4-flash-0731" }
  return ""
}

## Selects the default thinking level for a known factory role.
export pure default_thinking(role: Str) -> Str {
  if role_prefix(role) != "" { return "high" }
  return ""
}

## Selects the default dollar budget for a known factory role.
export pure default_budget(role: Str) -> Str {
  if role_prefix(role) != "" { return "2" }
  return ""
}

## Selects the default Pi tool set for a known factory role.
export pure default_tools(role: Str) -> Str {
  if role == "eval-worker" { return "read,write,edit,bash" }
  if role_prefix(role) != "" { return "read,write,edit,bash,grep,find,ls" }
  return ""
}

## Reads one configured role setting, falling back to the codified default.
export proc configured_role_setting(role: Str, key: Str) [env, error] -> Result[Str] {
  let prefix = role_prefix(role)
  if prefix == "" {
    return Ok("")
  }
  let fallback = if key == "PROVIDER" {
    default_provider(role)
  } else if key == "MODEL" {
    default_model(role)
  } else if key == "THINKING" {
    default_thinking(role)
  } else if key == "BUDGET_USD" {
    default_budget(role)
  } else if key == "TOOLS" {
    default_tools(role)
  } else {
    ""
  }
  return env.get_or(f"FACTORY_${prefix}_${key}", fallback)
}

## Builds an eval overlay from the local base image without a registry pull.
export pure eval_overlay_build_args(
  base_image: Str,
  build_id: Str,
  image: Str,
  platform: Str,
  dockerfile: Path,
  context: Path,
) -> List[Str] {
  return [
    "build",
    "--no-cache",
    "--platform", platform,
    "--build-arg", f"BASE_IMAGE=${base_image}",
    "--build-arg", f"FACTORY_BUILD_ID=${build_id}",
    "-t", image,
    "-f", dockerfile.display(),
    context.display(),
  ]
}

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

## Reads whether an organization cycle should auto-select an approved ticket.
export pure request_ticket_policy(text: Str) -> Str {
  var in_tickets = false
  for line in text.lines() {
    let trimmed = line.trim()
    if trimmed == "## Approved tickets" {
      in_tickets = true
      continue
    }
    if in_tickets and trimmed.starts_with("## ") {
      return "auto"
    }
    if in_tickets and (trimmed == "- None." or trimmed == "- None") {
      return "none"
    }
    if in_tickets and trimmed.starts_with("- `") {
      return "explicit"
    }
  }
  return "auto"
}

## Reads the controller-owned trial count from a cycle request.
export pure request_trial_count(text: Str) -> Result[Int] {
  var in_plan = false
  for line in text.lines() {
    let trimmed = line.trim()
    if trimmed == "## Trial plan" or trimmed == "## Trial count" {
      in_plan = true
      continue
    }
    if in_plan and trimmed.starts_with("## ") {
      return Ok(1)
    }
    if in_plan and trimmed.starts_with("- Count:") {
      let quoted = trimmed.split("`")
      if quoted.len() >= 2 {
        return quoted[1].parse_int()
      }
      let parts = trimmed.split(":")
      if parts.len() >= 2 {
        return parts[1].trim().parse_int()
      }
    }
  }
  return Ok(1)
}

## Reads the number of new eval proposals the controller must dispatch.
export pure request_new_eval_count(text: Str) -> Result[Int] {
  var in_proposals = false
  for line in text.lines() {
    let trimmed = line.trim()
    if trimmed == "## New eval proposals" {
      in_proposals = true
      continue
    }
    if in_proposals and trimmed.starts_with("## ") {
      return Ok(0)
    }
    if in_proposals and trimmed.starts_with("- Count:") {
      let quoted = trimmed.split("`")
      if quoted.len() >= 2 {
        return quoted[1].parse_int()
      }
      let parts = trimmed.split(":")
      if parts.len() >= 2 {
        return parts[1].trim().parse_int()
      }
    }
  }
  return Ok(0)
}

## Only slash-free eval directories may be selected by a cycle request.
export pure valid_eval_id(eval_id: Str) -> Bool {
  return eval_id != "" and ! eval_id.contains("/") and ! eval_id.contains("..") and
    ! eval_id.contains("\\") and ! eval_id.contains(" ")
}

## Rejects ticket identifiers that could escape the ticket/worktree namespace.
export pure valid_ticket_id(ticket_id: Str) -> Bool {
  return ticket_id != "" and ! ticket_id.contains("/") and ! ticket_id.contains("..") and
    ! ticket_id.contains("\\") and ! ticket_id.contains(" ")
}

## Requires the checked-in approval state used for cycle admission.
export pure ticket_is_accepted(text: Str) -> Bool {
  return ticket_status(text) == "Accepted." or ticket_status(text) == "Approved."
}

## Identifies a ticket waiting for post-merge evaluation.
export pure ticket_is_merged(text: Str) -> Bool {
  return ticket_status(text) == "Merged."
}

## Reads the first value below one exact report heading.
export pure report_field(text: Str, heading: Str) -> Str {
  var in_section = false
  for line in text.lines() {
    let trimmed = line.trim()
    if trimmed == f"## ${heading}" {
      in_section = true
      continue
    }
    if in_section and trimmed.starts_with("## ") {
      return ""
    }
    if in_section and trimmed != "" {
      return trimmed.replace("`", "")
    }
  }
  return ""
}

## Extracts one exact Markdown section from a checked-in template.
export pure section_text(text: Str, heading: Str) -> Str {
  let marker = f"## ${heading}"
  var in_section = false
  var lines: List[Str] = []
  for line in text.lines() {
    let trimmed = line.trim()
    if trimmed == marker {
      in_section = true
      lines = lines.push(line)
      continue
    }
    if in_section and trimmed.starts_with("## ") {
      break
    }
    if in_section {
      lines = lines.push(line)
    }
  }
  return lines.join("\n")
}

## Replaces one ticket status value while preserving the ticket body.
export pure replace_ticket_status(text: Str, replacement: Str) -> Str {
  let current = ticket_status(text)
  if current == "" {
    return text
  }
  let clean_replacement = replacement.trim()
  if current == clean_replacement {
    return text
  }
  var in_status = false
  var lines: List[Str] = []
  for line in text.lines() {
    let trimmed = line.trim()
    if trimmed == "## Status" {
      in_status = true
      lines = lines.push(line)
      continue
    }
    if in_status and trimmed.starts_with("## ") {
      in_status = false
      lines = lines.push(line)
      continue
    }
    if in_status and trimmed == current {
      lines = lines.push(clean_replacement)
      in_status = false
      continue
    }
    lines = lines.push(line)
  }
  return lines.join("\n") + "\n"
}

## Replaces or appends one ticket section from an on-disk template.
export pure replace_ticket_section(text: Str, heading: Str, replacement: Str) -> Str {
  let marker = f"## ${heading}"
  let clean_replacement = replacement.trim()
  var in_section = false
  var found = false
  var lines: List[Str] = []
  for line in text.lines() {
    let trimmed = line.trim()
    if ! in_section and trimmed == marker {
      lines = lines.push(clean_replacement)
      in_section = true
      found = true
      continue
    }
    if in_section and trimmed.starts_with("## ") {
      in_section = false
      lines = lines.push("")
      lines = lines.push(line)
      continue
    }
    if ! in_section {
      lines = lines.push(line)
    }
  }
  if found {
    return lines.join("\n") + "\n"
  }
  let existing = lines.join("\n").trim()
  if existing == "" {
    return clean_replacement + "\n"
  }
  return existing + "\n\n" + clean_replacement + "\n"
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

## Validates every required xsh-swe report heading and result.
export pure swe_report_contract_ok(report: Str) -> Bool {
  return report_contract_ok(report,
    ["Branch", "Commit", "Files changed", "Tests", "North-star impact", "Remaining risks"],
    "ready-for-review")
}

## Validates the evidence headings required from an eval-manager.
export pure manager_report_contract_ok(report: Str) -> Bool {
  return report_contract_ok(report,
    ["Effort metrics", "Usage and cost", "Thinking evidence", "Timing evidence",
      "Observation classification", "Handbook decision", "Tickets created",
      "Post-merge decisions", "Next replay", "North-star impact"], "")
}

## Validates the coordination headings required from a director.
export pure director_report_contract_ok(report: Str) -> Bool {
  return report_contract_ok(report,
    ["Cycle", "Children", "Required-output status", "North-star impact"], "")
}

## Validates the deterministic executor summary written for one trial.
export pure executor_report_contract_ok(report: Str) -> Bool {
  return report_contract_ok(report,
    ["Failure classification", "Trial", "Artifact", "Evidence"], "pass")
}

## Validates the concise report written by an eval-designer.
export pure designer_report_contract_ok(report: Str) -> Bool {
  return report_contract_ok(report,
    ["Proposal", "Dry run", "North-star impact", "Known risks", "Review path"],
    "ready-for-review")
}

## Validates the deterministic run audit produced from raw evidence.
export pure audit_report_contract_ok(report: Str) -> Bool {
  let result = report_field(report, "Result")
  return (result == "pass" or result == "fail") and
    report_contract_ok(report,
      ["Scope", "Integrity", "Evidence", "Findings"], "") and
    ! report.contains("{{") and ! report.contains("}}")
}

## Reads the normalized result from a run audit.
export pure audit_result(report: Str) -> Str {
  return report_field(report, "Result")
}

## Validates the worker report generated from one canonical Pi session.
export pure worker_report_contract_ok(report: Str) -> Bool {
  return report_contract_ok(report,
    ["Identity", "Session metrics", "Usage and cost", "Tool profile"], "") and
    report.contains("The complete thinking transcript is in `thinking.md`")
}

## Fills a checked-in Markdown template without embedding its contract in code.
export pure fill_template(template: Str, values: List[TemplateValue]) -> Str {
  var rendered = template
  for value in values {
    rendered = rendered.replace("{{" + value.key + "}}", value.value)
  }
  return rendered
}

## Verifies that an xsh-swe invocation carries the controller's exact assignment.
export pure xsh_swe_assignment_ok(
  run_dir: Str,
  ticket_id: Str,
  message_file: Str,
  workdir: Str,
  assignment: Str,
) -> Bool {
  let expected_message = run_dir + "/messages/" + ticket_id + ".md"
  return ticket_id != "" and message_file == expected_message and
    assignment.contains(f"- Ticket ID: `${ticket_id}`") and
    assignment.contains(f"- Dedicated XSH worktree: `${workdir}`") and
    assignment.contains("<!-- CONTROLLER_TICKET_SNAPSHOT_BEGIN -->") and
    assignment.contains("<!-- CONTROLLER_TICKET_SNAPSHOT_END -->") and
    assignment.contains("Do not search for open tickets")
}
