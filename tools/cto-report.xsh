##! Render one deterministic CTO briefing from a completed factory run.

use factory_control as control

pure first_nonempty(text: Str, fallback: Str) -> Str {
  for line in text.lines() {
    let trimmed = line.trim()
    if trimmed != "" {
      return trimmed
    }
  }
  return fallback
}

pure section_value(text: Str, headings: List[Str], fallback: Str) -> Str {
  for heading in headings {
    let value = control.report_section(text, heading)
    if value != "" {
      return value
    }
  }
  return fallback
}

pure relative_path(run_dir: Path, target: Path) -> Str {
  return control.factory_relative_path(run_dir.display(), target)
}

pure report_identifier(run_dir: Path, report: Path) -> Str {
  let relative = relative_path(run_dir, report)
  if report.name() == "DIRECTOR-REPORT.md" {
    return "director"
  }
  let parts = relative.split("/")
  if parts.len() >= 3 and parts[0] == "workers" {
    return f"${parts[1]}/${parts[2]}"
  }
  return relative
}

pure report_role(run_dir: Path, report: Path) -> Str {
  if report.name() == "DIRECTOR-REPORT.md" {
    return "director"
  }
  if report.name() == "MANAGER-REPORT.md" {
    return "eval-manager"
  }
  if report.name() == "DESIGNER-REPORT.md" {
    return "eval-designer"
  }
  if report.name() == "ENGINEER-REPORT.md" {
    return "engineer"
  }
  return "controller"
}

proc employee_decision(
  run_dir: Path,
  report: Path,
  employee_template: Str,
  action_template: Str,
) [fs, error] -> Result[Record] {
  let text = report.read_text()?
  let identifier = report_identifier(run_dir, report)
  let result = first_nonempty(control.report_section(text, "Result"), "not reported")
  let effort = section_value(text, ["Effort metrics", "Cycle", "Session metrics", "Tests"], "not reported")
  let handbook = section_value(text, ["Handbook decision", "Proposal"], "not reported")
  let tickets = section_value(text, ["Tickets created", "Post-merge decisions", "Remaining risks"], "not reported")
  let next = section_value(text, ["Next replay", "Review path", "Required-output status"], "not reported")
  let impact = section_value(text, ["North-star impact"], "not reported")
  let values: List[control.TemplateValue] = [
    {key: "IDENTIFIER", value: identifier},
    {key: "ROLE", value: report_role(run_dir, report)},
    {key: "RESULT", value: result},
    {key: "REPORT", value: relative_path(run_dir, report)},
    {key: "EFFORT", value: effort},
    {key: "HANDBOOK", value: handbook},
    {key: "TICKETS", value: tickets},
    {key: "NEXT", value: next},
    {key: "IMPACT", value: impact},
  ]
  let rendered = control.fill_template(employee_template, values)
  let action = control.fill_template(action_template, [
    {key: "IDENTIFIER", value: identifier},
    {key: "RESULT", value: result},
    {key: "NEXT", value: next},
    {key: "HANDBOOK", value: handbook},
    {key: "TICKETS", value: tickets},
  ])
  return Ok({employee: rendered, action: action})
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
  let action_template = fp"${factory_dir}/templates/CTO-ACTION.md".read_text()?
  let phase_template = fp"${factory_dir}/templates/CTO-PHASE.md".read_text()?

  let request_path = fp"${run_dir}/CYCLE-REQUEST.md"
  let request = if fs.exists(request_path)? { request_path.read_text()? } else { "" }
  let mode = if request == "" { "unknown" } else { control.request_mode(request) }
  let audit_path = fp"${run_dir}/AUDIT.md"
  let audit_text = if fs.exists(audit_path)? { audit_path.read_text()? } else { "" }
  let audit_result = if audit_text == "" { "missing" } else { control.audit_result(audit_text) }
  let provenance_path = fp"${run_dir}/PROVENANCE.md"

  var phase_reports: List[Path] = []
  var employee_reports: List[Path] = []
  for entry in fs.walk(run_dir, gitignore: false, hidden: true)? |> where .kind == "file" {
    if entry.name == "RUN.md" or entry.name == "RUN-DESIGN.md" {
      if entry.path.display() != fp"${run_dir}/RUN.md".display() {
        phase_reports = phase_reports.push(entry.path)
      }
    }
    if entry.name == "DIRECTOR-REPORT.md" or entry.name == "MANAGER-REPORT.md" or
      entry.name == "DESIGNER-REPORT.md" or entry.name == "ENGINEER-REPORT.md" {
      employee_reports = employee_reports.push(entry.path)
    }
  }
  phase_reports = phase_reports |> sort-by .display()
  employee_reports = employee_reports |> sort-by .display()

  var phases = ""
  for report in phase_reports {
    let text = report.read_text()?
    phases = phases + control.fill_template(phase_template, [
      {key: "PATH", value: relative_path(run_dir, report)},
      {key: "RESULT", value: first_nonempty(control.report_section(text, "Result"), "not reported")},
      {key: "REPORT", value: relative_path(run_dir, report)},
    ])
  }
  if phases == "" {
    phases = "No child phase reports were found."
  }

  var employee_decisions = ""
  var action_queue = ""
  for report in employee_reports {
    let decision = employee_decision(run_dir, report, employee_template, action_template)?
    employee_decisions = employee_decisions + decision.employee + "\n"
    action_queue = action_queue + decision.action + "\n"
  }
  if employee_decisions == "" {
    employee_decisions = "No qualitative employee reports were found."
    action_queue = "No employee action items were reported."
  }

  let cost_path = fp"${run_dir}/COST.md"
  let cost = if fs.exists(cost_path)? { cost_path.read_text()? } else { "" }
  let workers = section_value(cost, ["Workers"], "Cost report is unavailable.")
  let role_totals = section_value(cost, ["Role totals"], "Cost report is unavailable.")
  let run_total = section_value(cost, ["Run total"], "Cost report is unavailable.")
  let values: List[control.TemplateValue] = [
    {key: "RUN_ID", value: run_dir.name()},
    {key: "RESULT", value: result},
    {key: "MODE", value: mode},
    {key: "REQUEST", value: if fs.exists(request_path)? { relative_path(run_dir, request_path) } else { "missing" }},
    {key: "AUDIT_RESULT", value: audit_result},
    {key: "PROVENANCE", value: if fs.exists(provenance_path)? { "present" } else { "missing" }},
    {key: "PHASES", value: phases},
    {key: "WORKERS", value: workers},
    {key: "ROLE_TOTALS", value: role_totals},
    {key: "RUN_TOTAL", value: run_total},
    {key: "EMPLOYEE_DECISIONS", value: employee_decisions},
    {key: "ACTION_QUEUE", value: action_queue},
    {key: "RUN_REPORT", value: if fs.exists(fp"${run_dir}/RUN.md")? { "RUN.md" } else { "pending: RUN.md" }},
    {key: "COST_REPORT", value: if fs.exists(cost_path)? { "COST.md" } else { "missing: COST.md" }},
    {key: "AUDIT_REPORT", value: if fs.exists(audit_path)? { "AUDIT.md" } else { "missing: AUDIT.md" }},
    {key: "PROVENANCE_REPORT", value: if fs.exists(provenance_path)? { "PROVENANCE.md" } else { "missing: PROVENANCE.md" }},
  ]
  fs.write(output, control.fill_template(template, values))?
  abort(0)
}
