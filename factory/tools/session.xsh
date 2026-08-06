##! Normalize Pi session JSONL into the factory's structured report schema.

use factory.control as control
use factory.runtime as runtime
use factory.schema as schema

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

type ToolError = {turn: Int, tool: Str, text: Str}

type ProviderTelemetry = {
  events_path: Str,
  present: Bool,
  retry_count: Int,
  retry_delay_ms: Int,
  retry_errors: List[Str],
  provider_errors: List[Str],
  retry_successes: Int,
  retry_failures: Int,
  event_turns: Int,
  response_elapsed_ms: Int,
  output_tokens_per_second: Float,
}

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
  tool_error_details: List[ToolError],
  provider_telemetry: ProviderTelemetry,
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

pure content_text(value: Any) -> Str {
  match value {
    text is Str => return text
    blocks is List[Any] => {
      var parts: List[Str] = []
      for block in blocks {
        match block {
          block_record is Record => {
            let text = json_text(json.get(block_record, ["text"], ""))
            if text != "" { parts = parts.push(text) }
          }
          _ => {}
        }
      }
      return parts.join("\n")
    }
    _ => return ""
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
  days * 86400000 + hour * 3600000 + minute * 60000 + second * 1000 + millis
}

proc read_session(session_path: Path) [fs, process, error] -> Result[SessionReport] {
  let session_text = runtime.session_text(session_path)?
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
  var tool_error_details: List[ToolError] = []

  for line in session_text.lines() {
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
                    let tool = json_text(json.get(message, ["toolName"], "unknown"))
                    let detail = content_text(json.get(message, ["content"], ""))
                    tool_error_details = tool_error_details.push({
                      turn: assistant_turns,
                      tool: if tool == "" { "unknown" } else { tool },
                      text: if detail == "" { "(no tool error text reported)" } else { detail },
                    })
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
                  let stop = json_text(json.get(message, ["stopReason"], null))
                  if stop != "" {
                    stop_reasons = stop_reasons.set(stop, stop_reasons.get(stop, 0) + 1)
                  }
                  let provider = json_text(json.get(message, ["provider"], null))
                  let model = json_text(json.get(message, ["model"], null))
                  if provider != "" and model != "" {
                    let label = f"${provider}/${model}"
                    if label not in models { models = models.push(label) }
                  }

                  match json.get(message, ["content"], null) {
                    blocks is List[Any] => {
                      for block in blocks {
                        match block {
                          block_record is Record => {
                            let block_type = json_text(json.get(block_record, ["type"], null))
                            if block_type == "thinking" {
                              thinking_blocks += 1
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
    tool_error_details: tool_error_details,
    provider_telemetry: {
      events_path: "",
      present: false,
      retry_count: 0,
      retry_delay_ms: 0,
      retry_errors: [],
      provider_errors: [],
      retry_successes: 0,
      retry_failures: 0,
      event_turns: 0,
      response_elapsed_ms: 0,
      output_tokens_per_second: 0.0,
    },
  })
}

pure count_rows(counts: Map[Int]) -> List[Any] {
  [{name: key, count: counts.get(key, 0)} for key in counts.keys()]
}

proc parse_pi_events(events_path: Path) [fs, process, error] -> Result[ProviderTelemetry] {
  let empty: ProviderTelemetry = {
    events_path: events_path.display(),
    present: false,
    retry_count: 0,
    retry_delay_ms: 0,
    retry_errors: [],
    provider_errors: [],
    retry_successes: 0,
    retry_failures: 0,
    event_turns: 0,
    response_elapsed_ms: 0,
    output_tokens_per_second: 0.0,
  }
  if ! fs.exists(events_path)? { return empty }
  var retries = 0
  var retry_delay = 0
  var errors: List[Str] = []
  var provider_errors: List[Str] = []
  var retry_successes = 0
  var retry_failures = 0
  var turns = 0
  var response_elapsed = 0
  var output_tokens = 0.0
  var turn_start = -1
  let event_text = runtime.session_text(events_path)?
  for line in event_text.lines() {
    match json.decode(line) {
      Err(_) => {}
      Ok(event) => {
        let kind = json_text(json.get(event, ["type"], ""))
        if kind == "auto_retry_start" {
          retries += 1
          retry_delay += json_text(json.get(event, ["delayMs"], "0")).parse_int()?
          let message = json_text(json.get(event, ["errorMessage"], ""))
          if message != "" { errors = errors.push(message) }
        } else if kind == "auto_retry_end" {
          if json_text(json.get(event, ["success"], false)) == "true" {
            retry_successes += 1
          } else {
            retry_failures += 1
          }
        } else if kind == "turn_start" {
          turn_start = json_text(json.get(event, ["timestamp"], "-1")).parse_int()?
        } else if kind == "turn_end" {
          turns += 1
          let message = json.get(event, ["message"], null)
          match message {
            message_record is Record => {
              let end = json_text(json.get(message_record, ["timestamp"], "-1")).parse_int()?
              if turn_start >= 0 and end >= turn_start {
                response_elapsed += end - turn_start
              }
              output_tokens += json_number(json.get(message_record, ["usage", "output"], null))
            }
            _ => {}
          }
          turn_start = -1
        } else if kind == "message_end" {
          let message = json.get(event, ["message"], null)
          match message {
            message_record is Record => {
              if json_text(json.get(message_record, ["role"], "")) == "assistant" and
                json_text(json.get(message_record, ["stopReason"], "")) == "error" {
                let error = json_text(json.get(message_record, ["errorMessage"], ""))
                if error != "" { provider_errors = provider_errors.push(error) }
              }
            }
            _ => {}
          }
        }
      }
    }
  }
  return {
    events_path: events_path.display(),
    present: true,
    retry_count: retries,
    retry_delay_ms: retry_delay,
    retry_errors: errors,
    provider_errors: provider_errors,
    retry_successes: retry_successes,
    retry_failures: retry_failures,
    event_turns: turns,
    response_elapsed_ms: response_elapsed,
    output_tokens_per_second: if response_elapsed > 0 { output_tokens / response_elapsed.float() * 1000.0 } else { 0.0 },
  }
}

pure optional_number(value: Float, seen: Bool) -> Any {
  var result: Any = null
  if seen { result = value }
  return result
}

pure optional_int(value: Int, seen: Bool) -> Any {
  var result: Any = null
  if seen { result = value }
  return result
}

pure session_report_json(report: SessionReport, role: Str, worker_id: Str, budget: Float) -> Any {
  let usage = report.usage
  let errors = [{
      turn: error.turn,
      tool: error.tool,
      summary: error.text,
      raw_session: report.path,
    } for error in report.tool_error_details]
  var findings: List[Any] = []
  if report.tool_errors > 0 {
    findings = findings.push({kind: "tool-error", severity: "warning", count: report.tool_errors})
  }
  if report.malformed_lines > 0 {
    findings = findings.push({kind: "malformed-session-line", severity: "error", count: report.malformed_lines})
  }
  let result = if ! report.cost_seen { "unknown" } else if usage.cost_usd > budget { "fail" } else { "pass" }
  return {
    schema_version: schema.SCHEMA_VERSION,
    kind: "worker",
    identity: {role: role, worker_id: worker_id},
    state: "completed",
    result: result,
    session: report.path,
    models: report.models,
    timing: {session_span_ms: optional_int(report.session_span_ms, report.session_span_ms >= 0)},
    provider_telemetry: report.provider_telemetry,
    usage: {
      assistant_turns: report.assistant_turns,
      user_messages: report.user_messages,
      tool_calls: report.tool_calls,
      tool_results: report.tool_results,
      tool_errors: report.tool_errors,
      thinking_blocks: report.thinking_blocks,
      malformed_lines: report.malformed_lines,
      input_tokens: usage.input_tokens,
      output_tokens: usage.output_tokens,
      cache_read_tokens: usage.cache_read_tokens,
      cache_write_tokens: usage.cache_write_tokens,
      total_bucket_tokens: usage.total_tokens,
      provider_total_tokens: optional_number(usage.provider_total_tokens, usage.provider_total_seen),
      reasoning_tokens: optional_number(usage.reasoning_tokens, usage.reasoning_seen),
      input_cost_usd: optional_number(usage.input_cost_usd, usage.cost_components_seen),
      output_cost_usd: optional_number(usage.output_cost_usd, usage.cost_components_seen),
      cache_read_cost_usd: optional_number(usage.cache_read_cost_usd, usage.cost_components_seen),
      cache_write_cost_usd: optional_number(usage.cache_write_cost_usd, usage.cost_components_seen),
      cost_usd: optional_number(usage.cost_usd, report.cost_seen),
      budget_usd: budget,
    },
    stop_reasons: count_rows(report.stop_reasons),
    tools: count_rows(report.tool_names),
    tool_errors: errors,
    findings: findings,
    artifacts: [{kind: "pi-session", path: report.path}],
  }
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
  return if whole < 0 { whole.float() - fraction.float() / divisor.float() } else { magnitude }
}

proc run_worker(argv: List[Str]) [fs, process, env, error] -> Result[Int] {
  if argv.len() < 9 {
    eprint "usage: session-report.xsh worker --session PATH --output PATH --role ROLE --worker-id ID --budget-usd USD"
    return Ok(2)
  }
  let session = fp"${argv[2]}"
  let output = fp"${argv[4]}"
  let role = argv[6]
  let worker_id = argv[8]
  let requested_budget = if argv.len() > 10 { argv[10] } else { control.default_budget(role) }
  let budget = parse_budget(control.clamp_budget(role, requested_budget)?)?
  if ! fs.exists(session)? {
    eprint f"missing session: ${session.display()}"
    return Ok(1)
  }
  let report = read_session(session)?
  let events_path = if argv.len() > 12 { fp"${argv[12]}" } else { fp"${session.display()}.events.jsonl" }
  let telemetry = parse_pi_events(events_path)?
  let enriched = {
    path: report.path,
    assistant_turns: report.assistant_turns,
    user_messages: report.user_messages,
    tool_calls: report.tool_calls,
    tool_results: report.tool_results,
    tool_errors: report.tool_errors,
    thinking_blocks: report.thinking_blocks,
    malformed_lines: report.malformed_lines,
    models: report.models,
    stop_reasons: report.stop_reasons,
    tool_names: report.tool_names,
    usage: report.usage,
    cost_seen: report.cost_seen,
    session_span_ms: report.session_span_ms,
    tool_error_details: report.tool_error_details,
    provider_telemetry: telemetry,
  }
  json.write(output, session_report_json(enriched, role, worker_id, budget), pretty: true)?
  if ! report.cost_seen { return Ok(2) }
  if report.usage.cost_usd > budget { return Ok(3) }
  0
}

proc main(...argv: List[Str]) [fs, error, io] {
  if argv.len() == 0 {
    eprint "usage: session-report.xsh worker ..."
    abort(2)
  }
  var status = 2
  if argv[0] == "worker" {
    status = run_worker(argv)?
  } else {
    eprint f"unknown session report command: ${argv[0]}"
  }
  abort(status)
}
