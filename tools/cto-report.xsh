##! Render one human briefing from the structured run report and employee narratives.

use factory_control as control
use report_schema as schema

pure text(value: Any, fallback: Str = "unknown") -> Str {
  let result = schema.value_text(value)
  return if result == "" { fallback } else { result }
}

pure relative_path(run_dir: Path, target: Path) -> Str {
  return control.factory_relative_path(run_dir.display(), target)
}

pure worker_identifier(run_dir: Path, report: Path) -> Str {
  let parts = relative_path(run_dir, report).split("/")
  if parts.len() >= 3 and parts[0] == "workers" {
    return f"${parts[1]}/${parts[2]}"
  }
  return relative_path(run_dir, report)
}

pure worker_role(run_dir: Path, report: Path) -> Str {
  let parts = relative_path(run_dir, report).split("/")
  if parts.len() >= 3 and parts[0] == "workers" {
    return parts[1]
  }
  return "unknown"
}

pure narrative_section(text: Str, headings: List[Str], fallback: Str) -> Str {
  for heading in headings {
    let value = control.report_section(text, heading)
    if value != "" {
      return value
    }
  }
  return fallback
}

proc employee_block(run_dir: Path, report: Path, template: Str) [fs, error] -> Result[Str] {
  let narrative = report.read_text()?
  let identifier = worker_identifier(run_dir, report)
  let role = worker_role(run_dir, report)
  let result = text(control.report_field(narrative, "Result"), "not reported")
  return control.fill_template(template, [
    {key: "IDENTIFIER", value: identifier},
    {key: "ROLE", value: role},
    {key: "RESULT", value: result},
    {key: "REPORT", value: relative_path(run_dir, report)},
    {key: "EFFORT", value: narrative_section(narrative, ["Effort metrics", "Cycle", "Session metrics", "Tests"], "not reported")},
    {key: "HANDBOOK", value: narrative_section(narrative, ["Handbook decision", "Proposal"], "not reported")},
    {key: "TICKETS", value: narrative_section(narrative, ["Tickets created", "Post-merge decisions", "Remaining risks"], "not reported")},
    {key: "NEXT", value: narrative_section(narrative, ["Next replay", "Review path", "Required-output status"], "not reported")},
    {key: "IMPACT", value: narrative_section(narrative, ["North-star impact"], "not reported")},
  ])
}

proc worker_block(run_dir: Path, report: Path, template: Str) [fs, error] -> Result[Str] {
  let value = json.read(report)?
  let usage = json.get(value, ["usage"], null)
  let execution = json.get(value, ["execution"], null)
  return control.fill_template(template, [
    {key: "IDENTIFIER", value: worker_identifier(run_dir, report)},
    {key: "ROLE", value: worker_role(run_dir, report)},
    {key: "RESULT", value: text(json.get(value, ["result"], "unknown"))},
    {key: "EXECUTION", value: text(json.get(execution, ["result"], "not recorded"), "not recorded")},
    {key: "CLASSIFICATION", value: text(json.get(execution, ["classification"], "not recorded"), "not recorded")},
    {key: "REPORT", value: relative_path(run_dir, report)},
    {key: "TURNS", value: text(json.get(usage, ["assistant_turns"], 0), "0")},
    {key: "TOKENS", value: text(json.get(usage, ["total_bucket_tokens"], 0), "0")},
    {key: "TOOL_ERRORS", value: text(json.get(usage, ["tool_errors"], 0), "0")},
    {key: "COST", value: text(json.get(usage, ["cost_usd"], "unknown"))},
    {key: "BUDGET", value: text(json.get(usage, ["budget_usd"], "unknown"))},
    {key: "THINKING", value: text(json.get(usage, ["thinking_blocks"], 0), "0")},
  ])
}

proc eval_review_block(run_dir: Path, reviews: List[Path]) [fs, error] -> Result[Str] {
  if reviews.len() == 0 {
    return "No CTO eval review was recorded."
  }
  var result = ""
  for review in reviews {
    result = result + f"`${relative_path(run_dir, review)}`\n\n${review.read_text()?}\n"
  }
  return result
}

proc improvement_block(run_dir: Path) [fs, error] -> Result[Str] {
  let handoff = fp"${run_dir}/CTO-IMPROVEMENT.md"
  if ! fs.exists(handoff)? {
    return f"MISSING: `${relative_path(run_dir, handoff)}`"
  }
  let status = control.report_field(handoff.read_text()?, "Status")
  return if status == "" {
    f"`${relative_path(run_dir, handoff)}` (status not recorded)"
  } else {
    f"`${relative_path(run_dir, handoff)}` status: `${status}`"
  }
}

proc tool_error_blocks(run_dir: Path, reports: List[Path], template: Str) [fs, error] -> Result[Str] {
  var rows = ""
  for report in reports {
    let value = json.read(report)?
    let errors = json.get(value, ["tool_errors"], [])
    match errors {
      values is List[Any] => {
        for error in values {
          rows = rows + control.fill_template(template, [
            {key: "WORKER", value: worker_identifier(run_dir, report)},
            {key: "REPORT", value: relative_path(run_dir, report)},
            {key: "TURN", value: text(json.get(error, ["turn"], "unknown"))},
            {key: "TOOL", value: text(json.get(error, ["tool"], "unknown"))},
            {key: "SUMMARY", value: text(json.get(error, ["summary"], "(no summary)"), "(no summary)")},
          ])
        }
      }
      _ => {}
    }
  }
  return if rows == "" { "No nonzero Pi tool results were recorded." } else { rows }
}

proc phase_blocks(run_dir: Path, reports: List[Path], template: Str) [fs, error] -> Result[Str] {
  var rows = ""
  for report in reports {
    let value = json.read(report)?
    rows = rows + control.fill_template(template, [
      {key: "PATH", value: relative_path(run_dir, report)},
      {key: "RESULT", value: text(json.get(value, ["result"], "unknown"))},
      {key: "MODE", value: text(json.get(value, ["identity", "mode"], "unknown"))},
      {key: "REPORT", value: relative_path(run_dir, report)},
    ])
  }
  return if rows == "" { "This report is already a phase boundary; no child phases." } else { rows }
}

proc main(...argv: List[Str]) [fs, env, error, io] {
  if argv.len() < 6 or argv[0] != "--run-dir" or argv[2] != "--output" or argv[4] != "--result" {
    eprint "usage: cto-report.xsh --run-dir PATH --output PATH --result RESULT"
    abort(2)
  }
  let run_dir = Path(argv[1])
  let output = Path(argv[3])
  let result = argv[5]
  let factory_dir = env.path("FACTORY_DIR", fs.cwd()?)?
  let template = fp"${factory_dir}/templates/CTO-REPORT.md".read_text()?
  let employee_template = fp"${factory_dir}/templates/CTO-EMPLOYEE.md".read_text()?
  let worker_template = fp"${factory_dir}/templates/CTO-WORKER.md".read_text()?
  let error_template = fp"${factory_dir}/templates/CTO-TOOL-ERROR.md".read_text()?
  let phase_template = fp"${factory_dir}/templates/CTO-PHASE.md".read_text()?

  let root_report = fp"${run_dir}/report.json"
  let root_exists = fs.exists(root_report)?
  let root_value = if root_exists { json.read(root_report)? } else { null }
  if ! root_exists or (! schema.valid(root_value, "phase") and ! schema.valid(root_value, "run")) {
    eprint "structured run report is missing or invalid"
    abort(1)
  }
  let root = root_value
  let identity = json.get(root, ["identity"], null)
  let data = json.get(root, ["data"], null)
  let request_path = fp"${run_dir}/CYCLE-REQUEST.md"

  var phase_reports: List[Path] = []
  var employee_reports: List[Path] = []
  var worker_reports: List[Path] = []
  var eval_reviews: List[Path] = []
  for entry in fs.walk(run_dir, gitignore: false, hidden: true)? |> where .kind == "file" {
    if entry.name == "report.json" and entry.path.display().contains("/phases/") {
      phase_reports = phase_reports.push(entry.path)
    }
    if entry.name == "REPORT.md" and entry.path.display().contains("/workers/") {
      employee_reports = employee_reports.push(entry.path)
    }
    if entry.name == "report.json" and entry.path.display().contains("/workers/") {
      worker_reports = worker_reports.push(entry.path)
    }
    if entry.name == "CTO-EVAL-REVIEW.md" {
      eval_reviews = eval_reviews.push(entry.path)
    }
  }
  phase_reports = phase_reports |> sort-by .display()
  employee_reports = employee_reports |> sort-by .display()
  worker_reports = worker_reports |> sort-by .display()
  eval_reviews = eval_reviews |> sort-by .display()

  var employees = ""
  for report in employee_reports {
    employees = employees + employee_block(run_dir, report, employee_template)? + "\n"
  }
  if employees == "" { employees = "No employee narratives were found." }

  var workers = ""
  for report in worker_reports {
    workers = workers + worker_block(run_dir, report, worker_template)?
  }
  if workers == "" { workers = "No worker reports were found." }

  let usage = json.get(data, ["cost"], json.get(data, ["usage"], null))
  let cost_summary = control.fill_template(fp"${factory_dir}/templates/CTO-TOTAL.md".read_text()?, [
    {key: "WORKERS", value: text(json.get(usage, ["workers"], 0), "0")},
    {key: "TURNS", value: text(json.get(usage, ["assistant_turns"], 0), "0")},
    {key: "TOKENS", value: text(json.get(usage, ["total_bucket_tokens"], 0), "0")},
    {key: "COST", value: text(json.get(usage, ["cost_usd"], "unknown"))},
    {key: "TOOL_ERRORS", value: text(json.get(usage, ["tool_errors"], 0), "0")},
    {key: "BUDGET_FAILURES", value: text(json.get(usage, ["budget_failures"], 0), "0")},
  ])

  let values: List[control.TemplateValue] = [
    {key: "RUN_ID", value: run_dir.name()},
    {key: "RESULT", value: result},
    {key: "MODE", value: text(json.get(identity, ["mode"], "unknown"))},
    {key: "REQUEST", value: if fs.exists(request_path)? { relative_path(run_dir, request_path) } else { "missing" }},
    {key: "REPORT_SCHEMA", value: relative_path(run_dir, root_report)},
    {key: "PHASES", value: phase_blocks(run_dir, phase_reports, phase_template)?},
    {key: "WORKERS", value: workers},
    {key: "TOOL_ERRORS", value: tool_error_blocks(run_dir, worker_reports, error_template)?},
    {key: "COST_SUMMARY", value: cost_summary},
    {key: "EMPLOYEE_DECISIONS", value: employees},
    {key: "EVAL_REVIEW", value: eval_review_block(run_dir, eval_reviews)?},
    {key: "IMPROVEMENT", value: improvement_block(run_dir)?},
    {key: "ACTION_QUEUE", value: "Review the structured report and employee narratives before the next paid cycle."},
  ]
  fs.write(output, control.fill_template(template, values))?
  abort(0)
}
