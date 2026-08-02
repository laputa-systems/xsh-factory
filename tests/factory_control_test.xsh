##! Cheap native tests for the deterministic factory control plane.

use factory_control as control

proc test_cycle_request_parsing() [error] {
  let eval_request = "# Cycle\n\n## Active evals\n\n- `task-ecount`\n"
  let ticket_request = "# Cycle\n\n## Mode\n\n- `ticket-implementation`\n\n## Approved tickets\n\n- `task-tags-001`\n- `task-ecount-002`\n"
  test.eq(control.request_mode(eval_request), "eval")?
  test.eq(control.request_eval(eval_request), "task-ecount")?
  test.eq(control.request_mode(ticket_request), "ticket-implementation")?
  test.eq(control.request_tickets(ticket_request), ["task-tags-001", "task-ecount-002"])?
}

proc test_admission_contracts() [error] {
  test.ok(control.valid_ticket_id("task-tags-001"))?
  test.ok(! control.valid_ticket_id("../escape"))?
  test.ok(! control.valid_ticket_id("task/tags"))?
  test.ok(! control.valid_ticket_id("task tags"))?
  test.ok(control.ticket_is_accepted("# Ticket\n\n## Status\n\nAccepted.\n"))?
  test.ok(! control.ticket_is_accepted("# Ticket\n\n## Status\n\nOpen.\n"))?
}

proc test_lifecycle_rejects_improvised_transitions() [error] {
  test.ok(control.transition_allowed("created", "admitted"))?
  test.ok(control.transition_allowed("created", "started"))?
  test.ok(control.transition_allowed("admitted", "started"))?
  test.ok(control.transition_allowed("started", "completed"))?
  test.ok(control.transition_allowed("completed", "validated"))?
  test.ok(control.transition_allowed("validated", "ready-for-review"))?
  test.ok(control.transition_allowed("ready-for-review", "accepted"))?
  test.ok(control.transition_allowed("accepted", "reverted"))?
  test.ok(! control.transition_allowed("ready-for-review", "failed"))?
  test.ok(control.transition_allowed("started", "failed"))?
}

proc test_retry_policy_is_bounded_and_classified() [error] {
  test.ok(control.retry_allowed("transient-harness", 1, 2))?
  test.ok(! control.retry_allowed("transient-harness", 2, 2))?
  test.ok(control.retry_allowed("worker-failed", 1, 3))?
  test.ok(control.retry_allowed("budget-breach", 1, 2))?
  test.ok(! control.retry_allowed("candidate-failed", 1, 3))?
  test.ok(! control.retry_allowed("evaluator-failed", 1, 3))?
  test.ok(! control.retry_allowed("worker-failed", 0, 3))?
}

proc test_report_contract_checks_sections_only() [error] {
  let report = "# Report\n\n## Result\n\nready-for-review\n\n## Branch\n\nfactory/task/1\n\n## North-star impact\n\nExplicit boundary.\n"
  test.ok(control.report_contract_ok(report, ["Branch", "North-star impact"], "ready-for-review"))?
  test.ok(! control.report_contract_ok(report, ["Tests"], "ready-for-review"))?
  test.ok(! control.report_contract_ok(report, ["Branch"], "failed"))?
}

proc test_checked_in_templates_are_the_provenance_source(ctx: TestContext) [fs, error] {
  let template_path = fp"${fs.cwd()?}/templates/PROVENANCE.md"
  let template = fs.read_text(template_path)?
  let values: List[control.TemplateValue] = [
    {key: "RUN_ID", value: "run-test"},
    {key: "MODE", value: "ticket-implementation"},
  ]
  let rendered = control.fill_template(template, values)
  test.ok(rendered.contains("run-test"))?
  test.ok(rendered.contains("ticket-implementation"))?
  test.ok(rendered.contains("{{XSH_COMMIT}}"))?
  let _ = ctx
}

proc test_controller_assignment_inlines_one_ticket_and_forbids_selection(ctx: TestContext) [fs, error] {
  let template_path = fp"${fs.cwd()?}/templates/XSH-SWE-ASSIGNMENT.md"
  let template = fs.read_text(template_path)?
  let values: List[control.TemplateValue] = [
    {key: "TICKET_ID", value: "task-tags-001"},
    {key: "TICKET_PATH", value: "/factory/runs/run-test/tickets/task-tags-001.md"},
    {key: "TICKET_SHA", value: "ticket-sha"},
    {key: "WORKTREE", value: "/xsh-worktree"},
    {key: "BRANCH", value: "factory/task-tags-001/run-test"},
    {key: "XSH_COMMIT", value: "xsh-sha"},
    {key: "SWE_REPORT", value: "/factory/runs/run-test/workers/xsh-swe/task-tags-001/SWE-REPORT.md"},
    {key: "FACTORY_DIR", value: "/factory"},
    {key: "FACTORY_RUN_DIR", value: "/factory/runs/run-test"},
    {key: "NORTH_STAR_FILE", value: "/factory/NORTH-STAR.md"},
    {key: "HANDBOOK_FILE", value: "/factory/runtime/handbook.md"},
    {key: "XSH_AGENTS_FILE", value: "/xsh-worktree/AGENTS.md"},
    {key: "XSH_RATIONALE_FILE", value: "/xsh-worktree/docs/CHAPTER-01-why-xsh.md"},
    {key: "TICKET_TEXT", value: "## Observation\n\nThe controller chose this exact ticket."},
  ]
  let rendered = control.fill_template(template, values)
  test.ok(rendered.contains("Ticket ID: `task-tags-001`"))?
  test.ok(rendered.contains("The controller chose this exact ticket."))?
  test.ok(rendered.contains("Do not search for open tickets"))?
  test.ok(rendered.contains("choose another ticket"))?
  test.ok(rendered.contains("/factory/runtime/handbook.md"))?
  test.ok(! rendered.contains("{{TICKET_TEXT}}"))?
  let message_path = "/factory/runs/run-test/messages/task-tags-001.md"
  test.ok(control.xsh_swe_assignment_ok(
    "/factory/runs/run-test", "task-tags-001", message_path, "/xsh-worktree", rendered
  ))?
  test.ok(! control.xsh_swe_assignment_ok(
    "/factory/runs/run-test", "task-tags-002", message_path, "/xsh-worktree", rendered
  ))?
  let _ = ctx
}
