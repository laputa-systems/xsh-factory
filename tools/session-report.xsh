##! Render Pi session JSONL as Markdown reports using only XSH.

use factory_control as control

type Usage = {
  input_tokens: Float,
  output_tokens: Float,
  cache_read_tokens: Float,
  cache_write_tokens: Float,
  reasoning_tokens: Float,
  reasoning_seen: Bool,
  provider_total_tokens: Float,
  provider_total_seen: Bool,
  input_cost_usd: Float,
  output_cost_usd: Float,
  cache_read_cost_usd: Float,
  cache_write_cost_usd: Float,
  cost_components_seen: Bool,
  cost_usd: Float,
  total_tokens: Float,
}

type UsageDelta = {
  input_tokens: Float,
  output_tokens: Float,
  cache_read_tokens: Float,
  cache_write_tokens: Float,
  reasoning_tokens: Float,
  reasoning_seen: Bool,
  provider_total_tokens: Float,
  provider_total_seen: Bool,
  input_cost_usd: Float,
  output_cost_usd: Float,
  cache_read_cost_usd: Float,
  cache_write_cost_usd: Float,
  cost_usd: Float,
  cost_seen: Bool,
  cost_components_seen: Bool,
}

type ThinkingBlock = {turn: Int, text: Str}

type WorkerIdentity = {role: Str, worker_id: Str}

type SessionReport = {
  path: Str,
  assistant_turns: Int,
  user_messages: Int,
  tool_calls: Int,
  tool_results: Int,
  tool_errors: Int,
  thinking_blocks: Int,
  malformed_lines: Int,
  models: List[Str],
  stop_reasons: Map[Int],
  tool_names: Map[Int],
  usage: Usage,
  cost_seen: Bool,
  session_span_ms: Int,
  thinking: List[ThinkingBlock],
}

pure json_text(value: Any, fallback: Str = "") -> Str {
  match value {
    s is Str => return s
    i is Int => return f"${i}"
    f is Float => return f.format(precision: 6)
    b is Bool => return if b { "true" } else { "false" }
    _ => return fallback
  }
}

pure json_number(value: Any) -> Float {
  match value {
    i is Int => return i.float()
    f is Float => return f
    _ => return 0.0
  }
}

pure json_is_number(value: Any) -> Bool {
  match value {
    _ is Int => return true
    _ is Float => return true
    _ => return false
  }
}

pure usage_delta(value: Any) -> UsageDelta {
  match value {
    usage is Record => {
      let raw_reasoning = json.get(usage, ["reasoning"], null)
      let raw_provider_total = json.get(usage, ["totalTokens"], null)
      let input = json_number(json.get(usage, ["input"], null))
      let output = json_number(json.get(usage, ["output"], null))
      let cache_read = json_number(json.get(usage, ["cacheRead"], null))
      let cache_write = json_number(json.get(usage, ["cacheWrite"], null))
      let reasoning_seen = json_is_number(raw_reasoning)
      let provider_total_seen = json_is_number(raw_provider_total)
      match json.get(usage, ["cost"], null) {
        cost is Record => {
          let raw_input = json.get(cost, ["input"], null)
          let raw_output = json.get(cost, ["output"], null)
          let raw_cache_read = json.get(cost, ["cacheRead"], null)
          let raw_cache_write = json.get(cost, ["cacheWrite"], null)
          let raw_total = json.get(cost, ["total"], null)
          return {
            input_tokens: input,
            output_tokens: output,
            cache_read_tokens: cache_read,
            cache_write_tokens: cache_write,
            reasoning_tokens: json_number(raw_reasoning),
            reasoning_seen: reasoning_seen,
            provider_total_tokens: json_number(raw_provider_total),
            provider_total_seen: provider_total_seen,
            input_cost_usd: json_number(raw_input),
            output_cost_usd: json_number(raw_output),
            cache_read_cost_usd: json_number(raw_cache_read),
            cache_write_cost_usd: json_number(raw_cache_write),
            cost_usd: json_number(raw_total),
            cost_seen: json_is_number(raw_total),
            cost_components_seen: json_is_number(raw_input) or
              json_is_number(raw_output) or json_is_number(raw_cache_read) or
              json_is_number(raw_cache_write),
          }
        }
        _ => return {
          input_tokens: input,
          output_tokens: output,
          cache_read_tokens: cache_read,
          cache_write_tokens: cache_write,
          reasoning_tokens: json_number(raw_reasoning),
          reasoning_seen: reasoning_seen,
          provider_total_tokens: json_number(raw_provider_total),
          provider_total_seen: provider_total_seen,
          input_cost_usd: 0.0,
          output_cost_usd: 0.0,
          cache_read_cost_usd: 0.0,
          cache_write_cost_usd: 0.0,
          cost_usd: 0.0,
          cost_seen: false,
          cost_components_seen: false,
        }
      }
    }
    _ => return {
      input_tokens: 0.0,
      output_tokens: 0.0,
      cache_read_tokens: 0.0,
      cache_write_tokens: 0.0,
      reasoning_tokens: 0.0,
      reasoning_seen: false,
      provider_total_tokens: 0.0,
      provider_total_seen: false,
      input_cost_usd: 0.0,
      output_cost_usd: 0.0,
      cache_read_cost_usd: 0.0,
      cache_write_cost_usd: 0.0,
      cost_usd: 0.0,
      cost_seen: false,
      cost_components_seen: false,
    }
  }
}

proc iso_component(value: Str, offset: Int, length: Int) [error] -> Result[Int] {
  return value.byte_slice(offset, length).parse_int()
}

proc iso_millis(value: Str) [error] -> Result[Int] {
  if value.byte_len() < 20 or value.byte_slice(10, 1) != "T" {
    return "invalid".parse_int()
  }
  let year = iso_component(value, 0, 4)?
  let month = iso_component(value, 5, 2)?
  let day = iso_component(value, 8, 2)?
  let hour = iso_component(value, 11, 2)?
  let minute = iso_component(value, 14, 2)?
  let second = iso_component(value, 17, 2)?
  var millis = 0
  if value.byte_len() >= 24 and value.byte_slice(19, 1) == "." {
    millis = iso_component(value, 20, 3)?
  }

  # Howard Hinnant's civil-date conversion, valid for Pi's modern UTC dates.
  let adjusted_year = year - if month <= 2 { 1 } else { 0 }
  let era = adjusted_year / 400
  let year_of_era = adjusted_year - era * 400
  let month_prime = month + if month > 2 { -3 } else { 9 }
  let day_of_year = (153 * month_prime + 2) / 5 + day - 1
  let day_of_era = year_of_era * 365 + year_of_era / 4 - year_of_era / 100 + day_of_year
  let days = era * 146097 + day_of_era - 719468
  return Ok(days * 86400000 + hour * 3600000 + minute * 60000 + second * 1000 + millis)
}

proc read_session(session_path: Path) [fs, error] -> Result[SessionReport] {
  var assistant_turns = 0
  var user_messages = 0
  var tool_calls = 0
  var tool_results = 0
  var tool_errors = 0
  var thinking_blocks = 0
  var malformed_lines = 0
  var models: List[Str] = []
  var stop_reasons: Map[Int] = {}
  var tool_names: Map[Int] = {}
  var input_tokens = 0.0
  var output_tokens = 0.0
  var cache_read_tokens = 0.0
  var cache_write_tokens = 0.0
  var reasoning_tokens = 0.0
  var reasoning_seen = false
  var provider_total_tokens = 0.0
  var provider_total_seen = false
  var input_cost_usd = 0.0
  var output_cost_usd = 0.0
  var cache_read_cost_usd = 0.0
  var cache_write_cost_usd = 0.0
  var cost_components_seen = false
  var cost_usd = 0.0
  var cost_seen = false
  var start_ms = -1
  var end_ms = -1
  var thinking: List[ThinkingBlock] = []

  for line in session_path.read_text()?.lines() {
    if line.trim() != "" {
      match json.decode(line) {
        Err(_) => malformed_lines += 1
        Ok(entry) => {
          let raw_timestamp = json.get(entry, ["timestamp"], null)
          match raw_timestamp {
            value is Str => {
              match iso_millis(value) {
                Ok(timestamp) => {
                  if start_ms < 0 or timestamp < start_ms { start_ms = timestamp }
                  if timestamp > end_ms { end_ms = timestamp }
                }
                Err(_) => {}
              }
            }
            _ => {}
          }

          if json_text(json.get(entry, ["type"], null)) == "message" {
            let raw_message = json.get(entry, ["message"], null)
            match raw_message {
              message is Record => {
                let role = json_text(json.get(message, ["role"], null))
                if role == "user" {
                  user_messages += 1
                } else if role == "toolResult" {
                  tool_results += 1
                  if json_text(json.get(message, ["isError"], false)) == "true" {
                    tool_errors += 1
                  }
                  let delta = usage_delta(json.get(message, ["usage"], null))
                  input_tokens += delta.input_tokens
                  output_tokens += delta.output_tokens
                  cache_read_tokens += delta.cache_read_tokens
                  cache_write_tokens += delta.cache_write_tokens
                  reasoning_tokens += delta.reasoning_tokens
                  if delta.reasoning_seen { reasoning_seen = true }
                  provider_total_tokens += delta.provider_total_tokens
                  if delta.provider_total_seen { provider_total_seen = true }
                  input_cost_usd += delta.input_cost_usd
                  output_cost_usd += delta.output_cost_usd
                  cache_read_cost_usd += delta.cache_read_cost_usd
                  cache_write_cost_usd += delta.cache_write_cost_usd
                  if delta.cost_components_seen { cost_components_seen = true }
                  cost_usd += delta.cost_usd
                  if delta.cost_seen { cost_seen = true }
                } else if role == "assistant" {
                  assistant_turns += 1
                  let turn = assistant_turns
                  let stop = json_text(json.get(message, ["stopReason"], null))
                  if stop != "" {
                    stop_reasons = stop_reasons.set(stop, stop_reasons.get(stop, 0) + 1)
                  }
                  let provider = json_text(json.get(message, ["provider"], null))
                  let model = json_text(json.get(message, ["model"], null))
                  if provider != "" and model != "" {
                    let label = f"${provider}/${model}"
                    if ! models.contains(label) { models = models.push(label) }
                  }

                  match json.get(message, ["content"], null) {
                    blocks is List[Any] => {
                      for block in blocks {
                        match block {
                          block_record is Record => {
                            let block_type = json_text(json.get(block_record, ["type"], null))
                            if block_type == "thinking" {
                              thinking_blocks += 1
                              let text = json_text(
                                json.get(block_record, ["thinking"], json.get(block_record, ["text"], "")),
                              )
                              thinking = thinking.push({turn: turn, text: text})
                            } else if block_type == "toolCall" {
                              tool_calls += 1
                              let name = json_text(json.get(block_record, ["name"], null))
                              if name != "" {
                                tool_names = tool_names.set(name, tool_names.get(name, 0) + 1)
                              }
                            }
                          }
                          _ => {}
                        }
                      }
                    }
                    _ => {}
                  }

                  let delta = usage_delta(json.get(message, ["usage"], null))
                  input_tokens += delta.input_tokens
                  output_tokens += delta.output_tokens
                  cache_read_tokens += delta.cache_read_tokens
                  cache_write_tokens += delta.cache_write_tokens
                  reasoning_tokens += delta.reasoning_tokens
                  if delta.reasoning_seen { reasoning_seen = true }
                  provider_total_tokens += delta.provider_total_tokens
                  if delta.provider_total_seen { provider_total_seen = true }
                  input_cost_usd += delta.input_cost_usd
                  output_cost_usd += delta.output_cost_usd
                  cache_read_cost_usd += delta.cache_read_cost_usd
                  cache_write_cost_usd += delta.cache_write_cost_usd
                  if delta.cost_components_seen { cost_components_seen = true }
                  cost_usd += delta.cost_usd
                  if delta.cost_seen { cost_seen = true }
                }
              }
              _ => malformed_lines += 1
            }
          }
          let entry_type = json_text(json.get(entry, ["type"], null))
          if entry_type == "compaction" or entry_type == "branch_summary" {
            let delta = usage_delta(json.get(entry, ["usage"], null))
            input_tokens += delta.input_tokens
            output_tokens += delta.output_tokens
            cache_read_tokens += delta.cache_read_tokens
            cache_write_tokens += delta.cache_write_tokens
            reasoning_tokens += delta.reasoning_tokens
            if delta.reasoning_seen { reasoning_seen = true }
            provider_total_tokens += delta.provider_total_tokens
            if delta.provider_total_seen { provider_total_seen = true }
            input_cost_usd += delta.input_cost_usd
            output_cost_usd += delta.output_cost_usd
            cache_read_cost_usd += delta.cache_read_cost_usd
            cache_write_cost_usd += delta.cache_write_cost_usd
            if delta.cost_components_seen { cost_components_seen = true }
            cost_usd += delta.cost_usd
            if delta.cost_seen { cost_seen = true }
          }
        }
      }
    }
  }

  let span = if start_ms < 0 or end_ms < 0 { -1 } else { end_ms - start_ms }
  return Ok({
    path: session_path.display(),
    assistant_turns: assistant_turns,
    user_messages: user_messages,
    tool_calls: tool_calls,
    tool_results: tool_results,
    tool_errors: tool_errors,
    thinking_blocks: thinking_blocks,
    malformed_lines: malformed_lines,
    models: models,
    stop_reasons: stop_reasons,
    tool_names: tool_names,
    usage: {
      input_tokens: input_tokens,
      output_tokens: output_tokens,
      cache_read_tokens: cache_read_tokens,
      cache_write_tokens: cache_write_tokens,
      reasoning_tokens: reasoning_tokens,
      reasoning_seen: reasoning_seen,
      provider_total_tokens: provider_total_tokens,
      provider_total_seen: provider_total_seen,
      input_cost_usd: input_cost_usd,
      output_cost_usd: output_cost_usd,
      cache_read_cost_usd: cache_read_cost_usd,
      cache_write_cost_usd: cache_write_cost_usd,
      cost_components_seen: cost_components_seen,
      cost_usd: cost_usd,
      total_tokens: input_tokens + output_tokens + cache_read_tokens + cache_write_tokens,
    },
    cost_seen: cost_seen,
    session_span_ms: span,
    thinking: thinking,
  })
}

pure render_counts(counts: Map[Int]) -> Str {
  var items: List[Str] = []
  for key in counts.keys() {
    items = items.push(f"'${key}': ${counts.get(key, 0)}")
  }
  if items.len() == 0 { return "none" }
  return "{" + items.join(", ") + "}"
}

proc render_thinking(report: SessionReport, output: Path) [fs, error] -> Result[Unit] {
  var lines: List[Str] = [
    "# Thinking transcript",
    "",
    "This is the complete thinking-block extraction from the canonical Pi session JSONL.",
    "",
  ]
  if report.thinking.len() == 0 {
    lines = lines.push("No thinking blocks were reported.")
  } else {
    var index = 1
    for block in report.thinking {
      lines = lines.push(f"## Block ${index} (assistant turn ${block.turn})")
      lines = lines.push("")
      lines = lines.push(if block.text == "" { "(empty)" } else { block.text })
      lines = lines.push("")
      index += 1
    }
  }
  fs.write(output, lines.join("\n") + "\n")?
  return Ok()
}

proc render_worker(
  report: SessionReport,
  output: Path,
  role: Str,
  worker_id: Str,
  budget: Float,
) [fs, error] -> Result[Int] {
  let usage = report.usage
  let model_text = if report.models.len() == 0 { "unknown" } else { report.models.join(", ") }
  let span_text = if report.session_span_ms < 0 { "unknown" } else { f"${report.session_span_ms} ms" }
  let stop_text = render_counts(report.stop_reasons)
  let tools_text = render_counts(report.tool_names)
  let cost_text = if report.cost_seen { "$" + usage.cost_usd.format(precision: 6) } else { "unknown" }
  let provider_total_text = if usage.provider_total_seen {
    usage.provider_total_tokens.format(precision: 0)
  } else {
    "unknown"
  }
  let reasoning_text = if usage.reasoning_seen {
    usage.reasoning_tokens.format(precision: 0)
  } else {
    "unknown (provider did not report)"
  }
  let visible_output_text = if usage.reasoning_seen {
    f"${(usage.output_tokens - usage.reasoning_tokens).format(precision: 0)} (derived)"
  } else {
    "unknown (reasoning unavailable)"
  }
  let input_cost_text = if usage.cost_components_seen { "$" + usage.input_cost_usd.format(precision: 6) } else { "unknown" }
  let output_cost_text = if usage.cost_components_seen { "$" + usage.output_cost_usd.format(precision: 6) } else { "unknown" }
  let cache_read_cost_text = if usage.cost_components_seen { "$" + usage.cache_read_cost_usd.format(precision: 6) } else { "unknown" }
  let cache_write_cost_text = if usage.cost_components_seen { "$" + usage.cache_write_cost_usd.format(precision: 6) } else { "unknown" }
  let budget_text = "$" + budget.format(precision: 2)
  let budget_status = if report.cost_seen and usage.cost_usd <= budget { "pass" } else { "fail-closed" }
  let lines: List[Str] = [
    f"# Worker report: ${worker_id}",
    "",
    "## Identity",
    "",
    f"- Role: `${role}`",
    f"- Worker: `${worker_id}`",
    f"- Session: `${report.path}`",
    f"- Model: ${model_text}",
    "",
    "## Session metrics",
    "",
    f"- Assistant turns: ${report.assistant_turns}",
    f"- Tool calls: ${report.tool_calls}",
    f"- Tool results: ${report.tool_results}",
    f"- Tool errors: ${report.tool_errors}",
    f"- Thinking blocks: ${report.thinking_blocks}",
    f"- Session span: ${span_text}",
    f"- Stop reasons: ${stop_text}",
    "",
    "## Usage and cost",
    "",
    f"- Input tokens: ${usage.input_tokens.format(precision: 0)}",
    f"- Output tokens: ${usage.output_tokens.format(precision: 0)}",
    f"- Cache-read tokens: ${usage.cache_read_tokens.format(precision: 0)}",
    f"- Cache-write tokens: ${usage.cache_write_tokens.format(precision: 0)}",
    f"- Provider-reported total tokens: ${provider_total_text}",
    f"- Reasoning/thinking tokens (provider subset of output): ${reasoning_text}",
    f"- Visible output estimate: ${visible_output_text}",
    f"- Total bucket tokens: ${usage.total_tokens.format(precision: 0)}",
    f"- Input cost: ${input_cost_text}",
    f"- Output cost: ${output_cost_text}",
    f"- Cache-read cost: ${cache_read_cost_text}",
    f"- Cache-write cost: ${cache_write_cost_text}",
    f"- Provider cost: ${cost_text}",
    f"- Budget: ${budget_text}",
    f"- Budget status: ${budget_status}",
    "",
    "## Tool profile",
    "",
    f"- Tools: ${tools_text}",
    "",
    "The complete thinking transcript is in `thinking.md` beside this report.",
  ]
  fs.write(output, lines.join("\n") + "\n")?
  if ! report.cost_seen { return Ok(2) }
  if usage.cost_usd > budget { return Ok(3) }
  return Ok(0)
}

pure worker_identity(session_path: Str) -> WorkerIdentity {
  let marker = session_path.find("workers/")
  if marker >= 0 {
    let suffix = session_path.byte_slice(marker, session_path.byte_len() - marker)
    let parts = suffix.split("/")
    if parts.len() >= 3 {
      return {role: parts[1], worker_id: parts[2]}
    }
  }
  return {role: "unknown", worker_id: "unknown"}
}

proc report_budget(report: SessionReport, role: Str) [fs, error] -> Result[Str] {
  let session = Path.parse_bytes(bytes.from_text(report.path))?
  let worker_report = fp"${session.parent()}/WORKER-REPORT.md"
  if fs.exists(worker_report)? {
    for line in worker_report.read_text()?.lines() {
      let trimmed = line.trim()
      if trimmed.starts_with("- Budget:") {
        return trimmed.replace("- Budget:", "").trim().replace("$", "")
      }
    }
  }
  return control.default_budget(role)
}

proc render_cost(run_dir: Path, output: Path, reports: List[SessionReport]) [fs, error] -> Result[Int] {
  var lines: List[Str] = [
    "# Run cost report",
    "",
    f"Run directory: `${run_dir.display()}`",
    "",
    "## Workers",
    "",
    "| Role | Worker | Model | Turns | Thinking blocks | Reasoning tokens | Provider total | Bucket total | Tool errors | Cost | Budget |",
    "| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |",
  ]
  var roles: List[Str] = []
  var total_cost = 0.0
  var total_tokens = 0.0
  var total_provider_tokens = 0.0
  var total_reasoning_tokens = 0.0
  var provider_total_unknown = 0
  var reasoning_unknown = 0
  var total_input_cost = 0.0
  var total_output_cost = 0.0
  var total_cache_read_cost = 0.0
  var total_cache_write_cost = 0.0
  var cost_components_unknown = 0
  var failed = 0
  for report in reports {
    let identity = worker_identity(report.path)
    if ! roles.contains(identity.role) { roles = roles.push(identity.role) }
    let usage = report.usage
    let budget_text = report_budget(report, identity.role)?
    let budget = if budget_text == "" { -1.0 } else { budget_text.parse_float()? }
    let cost_text = if report.cost_seen { "$" + usage.cost_usd.format(precision: 6) } else { "unknown" }
    if ! report.cost_seen or budget < 0.0 or usage.cost_usd > budget { failed += 1 }
    total_cost += usage.cost_usd
    total_tokens += usage.total_tokens
    if usage.provider_total_seen {
      total_provider_tokens += usage.provider_total_tokens
    } else {
      provider_total_unknown += 1
    }
    if usage.reasoning_seen {
      total_reasoning_tokens += usage.reasoning_tokens
    } else {
      reasoning_unknown += 1
    }
    if usage.cost_components_seen {
      total_input_cost += usage.input_cost_usd
      total_output_cost += usage.output_cost_usd
      total_cache_read_cost += usage.cache_read_cost_usd
      total_cache_write_cost += usage.cache_write_cost_usd
    } else {
      cost_components_unknown += 1
    }
    let model_text = if report.models.len() == 0 { "unknown" } else { report.models.join(", ") }
    let provider_total_text = if usage.provider_total_seen { usage.provider_total_tokens.format(precision: 0) } else { "unknown" }
    let reasoning_text = if usage.reasoning_seen { usage.reasoning_tokens.format(precision: 0) } else { "unknown" }
    let budget_display = if budget_text == "" { "unknown" } else { "$" + budget_text }
    lines = lines.push(
      f"| `${identity.role}` | `${identity.worker_id}` | ${model_text} | ${report.assistant_turns} | ${report.thinking_blocks} | ${reasoning_text} | ${provider_total_text} | ${usage.total_tokens.format(precision: 0)} | ${report.tool_errors} | ${cost_text} | ${budget_display} |",
    )
  }
  lines = lines.push("")
  lines = lines.push("## Role totals")
  lines = lines.push("")
  lines = lines.push("| Role | Workers | Provider total | Reasoning tokens | Bucket total | Cost |")
  lines = lines.push("| --- | ---: | ---: | ---: | ---: | ---: |")
  for role in roles {
    var workers = 0
    var role_tokens = 0.0
    var role_provider_tokens = 0.0
    var role_reasoning_tokens = 0.0
    var role_provider_unknown = false
    var role_reasoning_unknown = false
    var role_cost = 0.0
    for report in reports {
      if worker_identity(report.path).role == role {
        workers += 1
        role_tokens += report.usage.total_tokens
        if report.usage.provider_total_seen {
          role_provider_tokens += report.usage.provider_total_tokens
        } else {
          role_provider_unknown = true
        }
        if report.usage.reasoning_seen {
          role_reasoning_tokens += report.usage.reasoning_tokens
        } else {
          role_reasoning_unknown = true
        }
        role_cost += report.usage.cost_usd
      }
    }
    let role_cost_text = "$" + role_cost.format(precision: 6)
    let role_provider_text = if role_provider_unknown { "unknown" } else { role_provider_tokens.format(precision: 0) }
    let role_reasoning_text = if role_reasoning_unknown { "unknown" } else { role_reasoning_tokens.format(precision: 0) }
    lines = lines.push(f"| `${role}` | ${workers} | ${role_provider_text} | ${role_reasoning_text} | ${role_tokens.format(precision: 0)} | ${role_cost_text} |")
  }
  lines = lines.push("")
  lines = lines.push("## Run total")
  lines = lines.push("")
  lines = lines.push(f"- Workers: ${reports.len()}")
  let provider_total_text = if provider_total_unknown == 0 { total_provider_tokens.format(precision: 0) } else { f"unknown (${provider_total_unknown} worker(s) did not report it)" }
  let reasoning_total_text = if reasoning_unknown == 0 { total_reasoning_tokens.format(precision: 0) } else { f"unknown (${reasoning_unknown} worker(s) did not report it)" }
  lines = lines.push(f"- Provider-reported total tokens: ${provider_total_text}")
  lines = lines.push(f"- Provider-reported reasoning/thinking tokens: ${reasoning_total_text}")
  lines = lines.push(f"- Total bucket tokens: ${total_tokens.format(precision: 0)}")
  let total_cost_text = "$" + total_cost.format(precision: 6)
  lines = lines.push(f"- Total provider cost: ${total_cost_text}")
  if cost_components_unknown == 0 {
    lines = lines.push(f"- Input cost: ${total_input_cost.format(precision: 6)}")
    lines = lines.push(f"- Output cost: ${total_output_cost.format(precision: 6)}")
    lines = lines.push(f"- Cache-read cost: ${total_cache_read_cost.format(precision: 6)}")
    lines = lines.push(f"- Cache-write cost: ${total_cache_write_cost.format(precision: 6)}")
  } else {
    lines = lines.push(f"- Cost component breakdown: unknown (${cost_components_unknown} worker(s) did not report components)")
  }
  lines = lines.push(f"- Budget failures or unknown costs: ${failed}")
  fs.write(output, lines.join("\n") + "\n")?
  return Ok(if failed == 0 { 0 } else { 2 })
}

proc parse_budget(value: Str) [error] -> Result[Float] {
  let parts = value.split(".", maxsplit: 1)
  let whole_text = if parts[0] == "" or parts[0] == "-" { "0" } else { parts[0] }
  let whole = whole_text.parse_int()?
  if parts.len() == 1 { return Ok(whole.float()) }
  let fraction_text = parts[1]
  if fraction_text == "" { return Ok(whole.float()) }
  let fraction = fraction_text.parse_int()?
  var divisor = 1
  for _ in range(fraction_text.count_chars()) {
    divisor *= 10
  }
  let magnitude = whole.float() + fraction.float() / divisor.float()
  return Ok(if whole < 0 { whole.float() - fraction.float() / divisor.float() } else { magnitude })
}

proc run_worker(argv: List[Str]) [fs, error] -> Result[Int] {
  if argv.len() < 9 {
    eprint "usage: session-report.xsh worker --session PATH --output PATH --role ROLE --worker-id ID --budget-usd USD"
    return Ok(2)
  }
  let session = Path(argv[2])
  let output = Path(argv[4])
  let role = argv[6]
  let worker_id = argv[8]
  let requested_budget = if argv.len() > 10 { argv[10] } else { control.default_budget(role) }
  let budget = parse_budget(control.clamp_budget(role, requested_budget)?)?
  if ! fs.exists(session)? {
    eprint f"missing session: ${session.display()}"
    return Ok(1)
  }
  let report = read_session(session)?
  render_thinking(report, fp"${output.parent()}/thinking.md")?
  return render_worker(report, output, role, worker_id, budget)
}

proc run_aggregate(argv: List[Str]) [fs, error] -> Result[Int] {
  if argv.len() < 5 {
    eprint "usage: session-report.xsh run --run-dir PATH --output PATH"
    return Ok(2)
  }
  let run_dir = Path(argv[2])
  let output = Path(argv[4])
  var sessions: List[Path] = []
  for entry in fs.files(run_dir, gitignore: false, hidden: true)? {
    if entry.name == "session.jsonl" { sessions = sessions.push(entry.path) }
  }
  sessions = sessions |> sort-by .display()
  var reports: List[SessionReport] = []
  for session in sessions { reports = reports.push(read_session(session)?) }
  return render_cost(run_dir, output, reports)
}

proc main(...argv: List[Str]) [fs, error, io] {
  if argv.len() == 0 {
    eprint "usage: session-report.xsh worker|run ..."
    abort(2)
  }
  var status = 2
  if argv[0] == "worker" {
    status = run_worker(argv)?
  } else if argv[0] == "run" {
    status = run_aggregate(argv)?
  } else {
    eprint f"unknown session report command: ${argv[0]}"
  }
  abort(status)
}
