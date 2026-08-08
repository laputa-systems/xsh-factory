##! Pure contracts shared by the factory controller and its native tests.
## One placeholder value used to fill a checked-in Markdown template.
export type TemplateValue = {key: Str, value: Str}

## Detect forbidden subprocess syntax without treating prose in `#` comments as code.
export pure source_has_forbidden_subprocess(source: Str) -> Bool {
  for line in source.lines() {
    let code = line.split("#").get(0, "")
    if "process." in code or "spawn " in code or "run " in code {
      return true
    }
  }

  return false
}

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

## Reads the repository that owns a ticket implementation.
## Missing or invalid ownership is not dispatchable. The checked-in ticket
## contract must say `product` or `factory` under `## Change target`.
export pure ticket_change_target(text: Str) -> Str {
  let section = section_text(text, "Change target")
  for line in section.lines() {
    let trimmed = line.trim()
    if trimmed == "- `product`" or trimmed == "- product" {
      return "product"
    }

    if trimmed == "- `factory`" or trimmed == "- factory" {
      return "factory"
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
  if role == "director" {
    return "DIRECTOR"
  }

  if role == "eval-designer" {
    return "EVAL_DESIGNER"
  }

  if role == "eval-manager" {
    return "EVAL_MANAGER"
  }

  if role == "eval-worker" {
    return "EVAL_WORKER"
  }

  if role == "engineer" {
    return "ENGINEER"
  }

  return ""
}

## Selects the default provider for a known factory role.
export pure default_provider(role: Str) -> Str {
  if role_prefix(role) != "" {
    return "openrouter"
  }

  return ""
}

## Selects the default model for a known factory role.
export pure default_model(role: Str) -> Str {
  if role == "engineer" {
    return "openai/gpt-5.6-luna"
  }

  if role_prefix(role) != "" {
    return "deepseek/deepseek-v4-flash-0731"
  }

  return ""
}

## Selects the default thinking level for a known factory role.
export pure default_thinking(role: Str) -> Str {
  if role == "eval-manager" {
    return "medium"
  }

  if role_prefix(role) != "" {
    return "high"
  }

  return ""
}

## Selects the default dollar budget for a known factory role.
export pure default_budget(role: Str) -> Str {
  if role == "director" {
    return "0.06"
  }

  if role == "eval-designer" {
    return "0.30"
  }

  if role == "eval-manager" {
    return "0.15"
  }

  if role == "eval-worker" {
    return "0.50"
  }

  if role == "engineer" {
    return "0.35"
  }

  return ""
}

## Hard assistant-turn ceilings keep a stalled worker from consuming a full cycle.
export pure default_max_turns(role: Str) -> Str {
  if role == "director" {
    return "24"
  }

  if role == "eval-designer" {
    return "64"
  }

  if role == "eval-manager" {
    return "24"
  }

  if role == "eval-worker" {
    return "160"
  }

  if role == "engineer" {
    return "220"
  }

  return ""
}

## Hard wall-clock ceilings are enforced by the controller-side session watcher.
## The director coordinates engineer children, so its ceiling must cover the
## same bounded child lifetime instead of expiring while healthy children run.
export pure default_max_wall_seconds(role: Str) -> Str {
  if role == "director" {
    return "1800"
  }

  if role == "eval-designer" {
    return "720"
  }

  if role == "eval-manager" {
    return "1800"
  }

  if role == "eval-worker" {
    return "1800"
  }

  if role == "engineer" {
    return "1800"
  }

  return ""
}

## Clamps a turn or wall-clock limit to the role's hard ceiling.
export pure clamp_session_limit(role: Str, key: Str, configured: Str) -> Result[Str] {
  let ceiling_text = if key == "MAX_TURNS" {
    default_max_turns(role)
  } else if key == "MAX_WALL_SECONDS" {
    default_max_wall_seconds(role)
  } else {
    ""
  }
  if ceiling_text == "" {
    return Ok(configured)
  }

  let requested = configured.parse_int()?
  let ceiling = ceiling_text.parse_int()?
  if requested <= 0 or requested > ceiling {
    return Ok(ceiling_text)
  }

  configured
}

## The hard maximum spend for one factory cycle.
export pure default_cycle_budget() -> Str {
  return "1.00"
}

## Paid admission limit for the total checked-in eval portfolio.
export pure max_eval_contracts() -> Int {
  return 30
}

## Hard ticket-cycle admission limit for concurrently dispatched engineers.
export pure max_concurrent_engineers() -> Int {
  return 2
}

## Maximum concurrent discovery eval phases in a ticketless organization cycle.
export pure max_concurrent_discovery_evals() -> Int {
  return 4
}

## Allocates engineer rows from the approved ready queue, capped by the
## controller's hard concurrency bound. Open tickets are never promoted here.
export pure engineer_target(approved_count: Int) -> Int {
  let bounded = if approved_count < 0 { 0 } else { approved_count }
  return if bounded > max_concurrent_engineers() {
    max_concurrent_engineers()
  } else {
    bounded
  }
}

## Clamps an operator-supplied budget to the role's hard ceiling.
export pure clamp_budget(role: Str, configured: Str) -> Result[Str] {
  let ceiling_text = default_budget(role)
  if ceiling_text == "" {
    return Ok(configured)
  }

  let requested = configured.parse_float()?
  let ceiling = ceiling_text.parse_float()?
  if requested > ceiling {
    return Ok(ceiling_text)
  }

  configured
}

## An operator may lower the cycle cap, but never raise the factory hard ceiling.
export pure clamp_cycle_budget(configured: Str) -> Result[Str] {
  let requested = configured.parse_float()?
  let ceiling_text = default_cycle_budget()
  let ceiling = ceiling_text.parse_float()?
  if requested > ceiling {
    return Ok(ceiling_text)
  }

  configured
}

## Selects the default Pi tool set for a known factory role.
export pure default_tools(role: Str) -> Str {
  if role == "eval-manager" {
    return "read,write,edit"
  }

  if role == "eval-worker" {
    return "read,write,edit,bash"
  }

  if role_prefix(role) != "" {
    return "read,write,edit,bash,grep,find,ls"
  }

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
  } else if key == "MAX_TURNS" {
    default_max_turns(role)
  } else if key == "MAX_WALL_SECONDS" {
    default_max_wall_seconds(role)
  } else if key == "TOOLS" {
    default_tools(role)
  } else {
    ""
  }
  let configured = env.get_or(f"FACTORY_${prefix}_${key}", fallback)?
  if key == "BUDGET_USD" {
    return clamp_budget(role, configured)
  }

  if key == "MAX_TURNS" or key == "MAX_WALL_SECONDS" {
    return clamp_session_limit(role, key, configured)
  }

  configured
}

## Builds an eval overlay from the local base image without a registry pull.
export pure eval_overlay_build_args(
  base_image: Str,
  build_id: Str,
  image: Str,
  platform: Str,
  dockerfile: Path,
  context: Path,
  force_rebuild: Bool = false,
) -> List[Str] {
  var build_args: List[Str] = ["build"]
  if force_rebuild {
    build_args = build_args.push("--no-cache")
  }

  return build_args.extend(
    [
      "--platform",
      platform,
      "--build-arg",
      f"BASE_IMAGE=${base_image}",
      "--build-arg",
      f"FACTORY_BUILD_ID=${build_id}",
      "-t",
      image,
      "-f",
      dockerfile.display(),
      context.display(),
    ],
  )
}

## Accepts a local Docker toolchain only when its keyed image and stamp agree.
export pure toolchain_cache_valid(
  force_rebuild: Bool,
  stamp_exists: Bool,
  cached_key: Str,
  expected_key: Str,
  image_present: Bool,
) -> Bool {
  return ! force_rebuild and stamp_exists and cached_key == expected_key and image_present
}

## A tagged shared eval image is reusable only when no rebuild was requested.
export pure shared_image_cache_valid(force_rebuild: Bool, image_present: Bool) -> Bool {
  return ! force_rebuild and image_present
}

## A cached Docker toolchain is usable only for the platform the build will run.
export pure toolchain_image_platform_matches(actual: Str, expected: Str) -> Bool {
  return actual.trim() == expected.trim()
}

## Creates a stable Docker tag from every input that can change the shared image.
export pure factory_image_tag(
  xsh_commit: Str,
  factory_control_sha: Str,
  factory_runtime_sha: Str,
  factory_schema_sha: Str,
  eval_worker_sha: Str,
  base_dockerfile_sha: Str,
  toolchain_dockerfile_sha: Str,
  toolchain_makefile_sha: Str,
  target: Str,
  platform: Str,
  eval_dockerfile_sha: Str = "",
  eval_dockerignore_sha: Str = "",
) -> Str {
  let identity = [
    "xsh=" + xsh_commit,
    "factory-control=" + factory_control_sha,
    "factory-runtime=" + factory_runtime_sha,
    "factory-schema=" + factory_schema_sha,
    "eval-worker=" + eval_worker_sha,
    "base-dockerfile=" + base_dockerfile_sha,
    "toolchain-dockerfile=" + toolchain_dockerfile_sha,
    "toolchain-makefile=" + toolchain_makefile_sha,
    "target=" + target,
    "platform=" + platform,
    "eval-dockerfile=" + eval_dockerfile_sha,
    "eval-dockerignore=" + eval_dockerignore_sha,
  ].join("\n")
  let digest = hash.sha256(bytes.from_text(identity)).hex()
  return "v" + digest.byte_slice(0, 16)
}

## Builds the pinned task-ecount oracle command and its failure boundary.
export pure ecount_oracle_command() -> List[Str] {
  return [
    "sh",
    "-c",
    "set -o pipefail; fd --color=never -tf . /usr/share | awk -F. 'NF > 1 {print tolower($NF)}' | sort | uniq -c | sort -n",
  ]
}

## An ecount oracle is trusted only when it exits successfully and emits data.
export pure ecount_oracle_ok(status_ok: Bool, output: Str) -> Bool {
  return status_ok and output != ""
}

## Classifies ecount failures without treating a broken oracle as a candidate failure.
export pure ecount_classification(
  artifact_present: Bool,
  review_ok: Bool,
  restriction_ok: Bool,
  oracle_ok: Bool,
  correctness_ok: Bool,
  timing_ok: Bool,
) -> Str {
  if ! artifact_present {
    return "worker_missing_artifact"
  }

  if ! review_ok {
    return "protocol_failed"
  }

  if ! restriction_ok {
    return "restriction_failed"
  }

  if ! oracle_ok {
    return "evaluator_failed"
  }

  if ! correctness_ok {
    return "candidate_failed"
  }

  if ! timing_ok {
    return "timing_failed"
  }

  return "pass"
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

  1
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

  0
}

## Rejects package evaluators that delegate to a host-side evaluator dispatcher.
export pure eval_evaluator_package_owned(source: Str) -> Bool {
  for line in source.lines() {
    let code = line.split("#").get(0, "")
    if "/usr/local/lib/xsh-factory" in code or "FACTORY_EVAL_EVALUATOR" in code {
      return false
    }
  }

  return true
}

## Reject placeholder or truncated XSH binaries before building a paid eval image.
export pure eval_binary_size_ok(size: Int) -> Bool {
  size >= 1024
}

## Only slash-free eval directories may be selected by a cycle request.
export pure valid_eval_id(eval_id: Str) -> Bool {
  return eval_id != "" and ! ("/" in eval_id) and ! (".." in eval_id) and ! ("\\" in eval_id) and ! (" " in eval_id)
}

## Reads the identifier from the first-level heading of a proposed eval.
export pure eval_id_from_contract(text: Str) -> Str {
  for line in text.lines() {
    let trimmed = line.trim()
    if trimmed.starts_with("# Eval ") {
      return trimmed.replace("# Eval ", "").trim()
    }
  }

  return ""
}

## Rejects ticket identifiers that could escape the ticket/worktree namespace.
export pure valid_ticket_id(ticket_id: Str) -> Bool {
  return ticket_id != "" and ! ("/" in ticket_id) and ! (".." in ticket_id) and ! ("\\" in ticket_id) and ! (" " in ticket_id)
}

## Identifies a disabled eval that must not be admitted to a new cycle.
export pure eval_is_disabled(text: Str) -> Bool {
  return ticket_status(text) == "Disabled."
}

## Identifies a ticket closed by a durable factory decision.
export pure ticket_is_closed(text: Str) -> Bool {
  return ticket_status(text) == "Closed."
}

## Requires an explicit alternatives and semantic-novelty review for new API surface.
export pure ticket_api_surface_review_required(text: Str) -> Bool {
  let proposal = section_text(text, "Proposed XSH change")
  return "builtin" in proposal or "keyword" in proposal or "constructor" in proposal or "primitive" in proposal or "syntax" in proposal or "new type" in proposal or "new method" in proposal
}

## Requires an explicit alternatives and semantic-novelty review for new API surface.
export pure ticket_api_surface_gate_ok(text: Str) -> Bool {
  if ! ticket_api_surface_review_required(text) {
    return true
  }

  let justification = section_text(text, "API-surface justification")
  if justification == "" {
    return false
  }

  for placeholder in ["Describe", "State the", "{{"] {
    if placeholder in justification {
      return false
    }
  }

  return "semantic" in justification and "existing" in justification and "evidence" in justification
}

## Requires the checked-in approval state used for cycle admission.
export pure ticket_is_accepted(text: Str) -> Bool {
  return ticket_change_target(text) == "product" and (ticket_status(text) == "Accepted." or ticket_status(text) == "Approved.")
}

## Identifies a ticket waiting for post-merge evaluation.
export pure ticket_is_merged(text: Str) -> Bool {
  return ticket_status(text) == "Merged."
}

## Keeps a completed merge record stable after run evidence is cleaned.
export pure ticket_merge_record_complete(text: Str) -> Bool {
  let merge_record = section_text(text, "Merge record")
  if merge_record == "" {
    return false
  }

  for placeholder in [
    "{{IMPLEMENTATION_BRANCH}}",
    "{{IMPLEMENTATION_COMMIT}}",
    "{{DETECTED_XSH_COMMIT}}",
    "{{IMPLEMENTATION_RUN}}",
  ] {
    if placeholder in merge_record {
      return false
    }
  }

  return true
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

## Reads one first-level report line with a fixed prefix.
export pure report_line_value(text: Str, prefix: Str) -> Str {
  for line in text.lines() {
    let trimmed = line.trim()
    if trimmed.starts_with(prefix) {
      return trimmed.replace(prefix, "").trim().replace("`", "")
    }
  }

  return ""
}

## Matches a report result while allowing a narrative sentence after the status.
export pure report_result_is(text: Str, expected: Str) -> Bool {
  let value = report_field(text, "Result")
  return value == expected or value.starts_with(f"${expected}. ") or value.starts_with(f"${expected} ")
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

    break when in_section and trimmed.starts_with("## ")
    if in_section {
      lines = lines.push(line)
    }
  }

  return lines.join("\n")
}

## Replaces one ticket status value while preserving the ticket body.
export pure replace_status(text: Str, replacement: Str) -> Str {
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

## Replaces one ticket status value while preserving the ticket body.
export pure replace_ticket_status(text: Str, replacement: Str) -> Str {
  return replace_status(text, replacement)
}

## Replaces one eval status value while preserving the eval body.
export pure replace_eval_status(text: Str, replacement: Str) -> Str {
  return replace_status(text, replacement)
}

## Replaces or appends one Markdown section from an on-disk template.
export pure replace_section(text: Str, heading: Str, replacement: Str) -> Str {
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

  return existing + """

""" + clean_replacement + "\n"
}

## Replaces or appends one ticket section from an on-disk template.
export pure replace_ticket_section(text: Str, heading: Str, replacement: Str) -> Str {
  return replace_section(text, heading, replacement)
}

## Produces a Markdown link target relative to the factory root.
export pure factory_relative_path(factory_dir: Str, target: Path) -> Str {
  let root = if factory_dir.ends_with("/") { factory_dir } else { factory_dir + "/" }
  let value = target.display()
  if value.starts_with(root) {
    return value.replace(root, "")
  }

  return value
}

## Defines the controller's legal lifecycle transitions.
export pure transition_allowed(current: Str, next: Str) -> Bool {
  if current == next {
    return true
  }

  if next == "failed" or next == "cancelled" {
    return current != "ready-for-review" and current != "accepted" and current != "reverted"
  }

  if current == "created" and next == "started" {
    return true
  }

  if current == "created" and next == "admitted" {
    return true
  }

  if current == "admitted" and next == "started" {
    return true
  }

  if current == "started" and next == "completed" {
    return true
  }

  if current == "completed" and next == "validated" {
    return true
  }

  if current == "validated" and next == "ready-for-review" {
    return true
  }

  if current == "ready-for-review" and next == "accepted" {
    return true
  }

  if current == "accepted" and next == "reverted" {
    return true
  }

  return false
}

## Permits retries only for bounded transient worker failures.
export pure retry_allowed(failure_class: Str, attempt: Int, max_attempts: Int) -> Bool {
  if attempt < 1 or max_attempts < 1 or attempt >= max_attempts {
    return false
  }

  return failure_class == "worker-failed" or failure_class == "transient-harness" or failure_class == "budget-breach"
}

## Returns the trimmed body of one level-two report section.
export pure report_section(report: Str, heading: Str) -> Str {
  let marker = f"## ${heading}"
  var found = false
  var content = ""
  for line in report.lines() {
    let trimmed = line.trim()
    if trimmed == marker {
      found = true
      continue
    }

    if found and trimmed.starts_with("## ") {
      return content.trim()
    }

    if found {
      content = content + line + "\n"
    }
  }

  return if found { content.trim() } else { "" }
}

## Validates a Markdown report without interpreting its narrative content.
export pure report_contract_ok(report: Str, required_sections: List[Str], expected_result: Str) -> Bool {
  if "{{" in report or "}}" in report {
    return false
  }

  if expected_result != "" and report_section(report, "Result") != expected_result {
    return false
  }

  for section in required_sections {
    if report_section(report, section) == "" {
      return false
    }
  }

  return true
}

## Validates an agent-authored report that must include a substantive result.
export pure narrative_report_contract_ok(report: Str, required_sections: List[Str]) -> Bool {
  return report_section(report, "Result") != "" and report_contract_ok(report, required_sections, "")
}

## Validates every required engineer report heading and result.
export pure engineer_report_contract_ok(report: Str) -> Bool {
  return report_contract_ok(
    report,
    ["Branch", "Commit", "Files changed", "Tests", "North-star impact", "Remaining risks"],
    "ready-for-review",
  )
}

## Validates the evidence headings required from an eval-manager.
export pure manager_report_contract_ok(report: Str) -> Bool {
  return narrative_report_contract_ok(
    report,
    [
      "Effort metrics",
      "Usage and cost",
      "Thinking evidence",
      "Timing evidence",
      "Tool-error findings",
      "Observation classification",
      "Handbook decision",
      "Tickets created",
      "Post-merge decisions",
      "Next replay",
      "North-star impact",
    ],
  )
}

## Requires managers to account for failed Pi tool results explicitly.
export pure manager_tool_error_findings_contract_ok(report: Str) -> Bool {
  let findings = report_section(report, "Tool-error findings")
  return findings != "" and ! ("Fill every current tool error" in findings) and ("None." in findings or "report.json" in findings or "tool_errors" in findings or "No current" in findings or "nonzero" in findings or "tool error" in findings)
}

## A valid manager report remains admissible when worker tool errors were
## classified with the report's supported evidence wording. The controller
## must not require one particular phrase after this contract has passed.
export pure manager_report_gate_ok(report: Str, worker_tool_errors: Bool, manager_tool_errors: Bool) -> Bool {
  return manager_report_contract_ok(report) and manager_tool_error_findings_contract_ok(report) and (! worker_tool_errors and ! manager_tool_errors or manager_tool_error_findings_contract_ok(
    report,
  ))
}

## A Pi process may return nonzero after producing a valid report because of
## an agent-level tool failure. Watchers and report production remain hard
## completion gates; the process result is retained as structured evidence.
export pure agent_completion_ok(watcher_ok: Bool, limit_ok: Bool, report_ok: Bool, required_report_ok: Bool) -> Bool {
  return watcher_ok and limit_ok and report_ok and required_report_ok
}

## Validates the coordination headings required from a director.
export pure director_report_contract_ok(report: Str) -> Bool {
  return narrative_report_contract_ok(
    report,
    ["Cycle", "Children", "Required-output status", "North-star impact"],
  )
}

## Validates the explicit composition and evidence gate for new eval proposals.
export pure eval_difficulty_contract_ok(text: Str) -> Bool {
  let section = section_text(text, "Difficulty justification")
  if section == "" {
    return false
  }

  return "two independent" in section and ("stateful aggregation" in section or "data transformations" in section) and "failure control" in section and "hidden" in section and ("one-liner" in section or "hard-coded" in section)
}

## Validates the concise report written by an eval-designer.
export pure designer_report_contract_ok(report: Str) -> Bool {
  return report_contract_ok(
    report,
    ["Proposal", "Dry run", "North-star impact", "Known risks", "Review path"],
    "ready-for-review",
  )
}

## Fills a checked-in Markdown template without embedding its contract in code.
export pure fill_template(template: Str, values: List[TemplateValue]) -> Str {
  var rendered = template
  for value in values {
    rendered = rendered.replace("{{" + value.key + "}}", value.value)
  }

  return rendered
}

## Verifies that an engineer invocation carries the controller's exact assignment.
export pure engineer_assignment_ok(
  run_dir: Str,
  ticket_id: Str,
  message_file: Str,
  workdir: Str,
  assignment: Str,
) -> Bool {
  let expected_message = run_dir + "/messages/" + ticket_id + ".md"
  return ticket_id != "" and message_file == expected_message and f"- Ticket ID: `${ticket_id}`" in assignment and f"- Dedicated XSH worktree: `${workdir}`" in assignment and "<!-- CONTROLLER_TICKET_SNAPSHOT_BEGIN -->" in assignment and "<!-- CONTROLLER_TICKET_SNAPSHOT_END -->" in assignment and "Do not search for open tickets" in assignment
}

## Parses whether a cycle requires an untried approved eval.
export pure request_allow_measured_eval(text: Str) -> Bool {
  for line in text.lines() {
    if line.trim() == "- Allow measured eval reuse: `yes`" {
      return true
    }
  }

  return false
}
