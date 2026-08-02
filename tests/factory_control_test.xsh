##! Cheap native tests for the deterministic factory control plane.

use factory_control as control
use factory_runtime as runtime

proc test_cycle_request_parsing() [error] {
  let eval_request = "# Cycle\n\n## Active evals\n\n- `task-ecount`\n"
  let planned_request = "# Cycle\n\n## Trial plan\n\n- Count: `2`\n\n## New eval proposals\n\n- Count: `1`\n"
  let ticket_request = "# Cycle\n\n## Mode\n\n- `ticket-implementation`\n\n## Approved tickets\n\n- `task-tags-001`\n- `task-ecount-002`\n"
  test.eq(control.request_mode(eval_request), "eval")?
  test.eq(control.request_eval(eval_request), "task-ecount")?
  test.eq(control.request_mode(ticket_request), "ticket-implementation")?
  test.eq(control.request_tickets(ticket_request), ["task-tags-001", "task-ecount-002"])?
  test.eq(control.request_trial_count(planned_request)?, 2)?
  test.eq(control.request_new_eval_count(planned_request)?, 1)?
  test.eq(control.request_trial_count(eval_request)?, 1)?
  test.eq(control.request_new_eval_count(eval_request)?, 0)?
}

proc test_role_configuration_has_one_coded_default() [error] {
  for role in ["director", "eval-designer", "eval-manager", "eval-worker", "xsh-swe"] {
    test.ok(control.role_prefix(role) != "")?
    test.eq(control.default_provider(role), "openrouter")?
    test.eq(control.default_model(role), "deepseek/deepseek-v4-flash-0731")?
    test.eq(control.default_thinking(role), "high")?
    test.eq(control.default_budget(role), "2")?
    let expected_tools = if role == "eval-worker" { "read,write,edit,bash" } else { "read,write,edit,bash,grep,find,ls" }
    test.eq(control.default_tools(role), expected_tools)?
  }
  test.eq(control.role_prefix("unknown"), "")?
  test.eq(control.default_model("unknown"), "")?
}

proc test_admission_contracts() [error] {
  test.ok(control.valid_ticket_id("task-tags-001"))?
  test.ok(! control.valid_ticket_id("../escape"))?
  test.ok(! control.valid_ticket_id("task/tags"))?
  test.ok(! control.valid_ticket_id("task tags"))?
  test.ok(control.ticket_is_accepted("# Ticket\n\n## Status\n\nAccepted.\n"))?
  test.ok(! control.ticket_is_accepted("# Ticket\n\n## Status\n\nOpen.\n"))?
}

proc test_ticket_merge_fields_are_idempotent(ctx: TestContext) [fs, error] {
  let accepted = "# Ticket\n\n## Status\n\nAccepted.\n\n## Source eval and manager\n\n- Eval: `task-tags`\n"
  test.eq(control.ticket_status(accepted), "Accepted.")?
  test.eq(control.ticket_eval(accepted), "task-tags")?
  let template = fs.read_text(fp"${fs.cwd()?}/templates/TICKET.md")?
  let merge_template = control.section_text(template, "Merge record")
  let replacement = control.fill_template(merge_template, [
    {key: "IMPLEMENTATION_BRANCH", value: "factory/task-tags-001/run"},
    {key: "IMPLEMENTATION_COMMIT", value: "impl-sha"},
    {key: "DETECTED_XSH_COMMIT", value: "merge-sha"},
    {key: "IMPLEMENTATION_RUN", value: "/factory/runs/run"},
  ])
  var merged = control.replace_ticket_status(accepted, "Merged.")
  merged = control.replace_ticket_section(merged, "Merge record", replacement)
  test.ok(control.ticket_is_merged(merged))?
  test.contains(merged, "Implementation commit: `impl-sha`")?
  test.eq(control.replace_ticket_status(merged, "Merged."), merged)?
  test.eq(control.replace_ticket_section(merged, "Merge record", replacement), merged)?
  let _ = ctx
}

proc run_git(git: Path, args: List[Str]) [process, error] -> Result[Bool] {
  let status = process.run(process.command_argv(git, args))?
  return status.ok
}

proc test_reconcile_detects_a_merged_provenance_branch(ctx: TestContext) [fs, process, error] {
  let repo = test.temp_dir(ctx, name: "reconcile-repo")?
  let factory = test.temp_dir(ctx, name: "reconcile-factory")?
  let git = process.which("git")?
  test.ok(run_git(git, ["git", "init", "-q", repo.display()])?)?
  test.ok(run_git(git, ["git", "-C", repo.display(), "config", "user.email", "factory@test"])?)?
  test.ok(run_git(git, ["git", "-C", repo.display(), "config", "user.name", "Factory Test"])?)?
  fs.write(fp"${repo}/README", "base\n")?
  test.ok(run_git(git, ["git", "-C", repo.display(), "add", "README"])?)?
  test.ok(run_git(git, ["git", "-C", repo.display(), "commit", "-qm", "base"])?)?
  let base_branch = run.text "git" "-C" $repo.display() "branch" "--show-current" ?
  let branch = "factory/reconcile-ticket/1"
  test.ok(run_git(git, ["git", "-C", repo.display(), "checkout", "-q", "-b", branch])?)?
  fs.write(fp"${repo}/README", "implementation\n")?
  test.ok(run_git(git, ["git", "-C", repo.display(), "add", "README"])?)?
  test.ok(run_git(git, ["git", "-C", repo.display(), "commit", "-qm", "implementation"])?)?
  test.ok(run_git(git, ["git", "-C", repo.display(), "checkout", "-q", base_branch.trim()])?)?
  test.ok(run_git(git, ["git", "-C", repo.display(), "merge", "-q", "--no-ff", branch, "-m", "merge"])?)?
  let head = run.text "git" "-C" $repo.display() "rev-parse" "HEAD" ?

  fs.mkdir(fp"${factory}/tickets")?
  fs.mkdir(fp"${factory}/templates")?
  fs.copy(fp"${fs.cwd()?}/templates/TICKET.md", fp"${factory}/templates/TICKET.md", overwrite: true)?
  fs.write(fp"${factory}/tickets/reconcile-ticket.md", "# Ticket\n\n## Status\n\nAccepted.\n")?
  let merged = runtime.reconcile_tickets(factory, repo, head.trim())?
  test.eq(merged.len(), 1)?
  let ticket = fs.read_text(fp"${factory}/tickets/reconcile-ticket.md")?
  test.ok(control.ticket_is_merged(ticket))?
  test.contains(ticket, "Implementation branch: `factory/reconcile-ticket/1`")?
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

proc test_role_report_contracts_are_fail_closed() [error] {
  let swe = "# SWE\n\n## Result\n\nready-for-review\n\n## Branch\n\nbranch\n\n## Commit\n\ncommit\n\n## Files changed\n\nfiles\n\n## Tests\n\npass\n\n## North-star impact\n\nimpact\n\n## Remaining risks\n\nNone.\n"
  let manager = "## Effort metrics\n\n## Usage and cost\n\n## Thinking evidence\n\n## Timing evidence\n\n## Observation classification\n\n## Handbook decision\n\n## Tickets created\n\n## Post-merge decisions\n\n## Next replay\n\n## North-star impact\n"
  let director = "## Result\n\npass\n\n## Cycle\n\ncycle\n\n## Children\n\nchildren\n\n## Required-output status\n\nstatus\n\n## North-star impact\n\nimpact\n"
  let executor = "## Result\n\npass\n\n## Failure classification\n\npass\n\n## Trial\n\n1\n\n## Artifact\n\npresent\n\n## Evidence\n\npaths\n"
  let designer = "## Result\n\nready-for-review\n\n## Proposal\n\nproposal\n\n## Dry run\n\npass\n\n## North-star impact\n\nimpact\n\n## Known risks\n\nNone.\n\n## Review path\n\npath\n"
  test.ok(control.swe_report_contract_ok(swe))?
  test.ok(! control.swe_report_contract_ok(swe.replace("## Tests", "## Missing")))?
  test.ok(control.manager_report_contract_ok(manager))?
  test.ok(control.director_report_contract_ok(director))?
  test.ok(control.executor_report_contract_ok(executor))?
  test.ok(control.designer_report_contract_ok(designer))?
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

proc test_runtime_lock_and_handbook_admission_are_deterministic(ctx: TestContext) [fs, error] {
  let root = test.temp_dir(ctx, name: "runtime-contract")?
  let lock = runtime.acquire_run_lock(root)?
  test.ok(fs.exists(fp"${root}/runs/factory.lock")?)?
  fs.mkdir(fp"${root}/runtime")?
  let handbook = fp"${root}/runtime/handbook.md"
  fs.write(handbook, "approved handbook\n")?
  let sha = hash.sha256(handbook)?.hex()
  test.ok(runtime.verify_factory_handbook(root, sha)?)?
  fs.write(handbook, "changed handbook\n")?
  test.ok(! runtime.verify_factory_handbook(root, sha)?)?
  let _ = lock
}
