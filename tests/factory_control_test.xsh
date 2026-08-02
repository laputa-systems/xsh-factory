##! Cheap native tests for the deterministic factory control plane.

use factory_control as control
use factory_runtime as runtime

proc test_cycle_request_parsing() [error] {
  let eval_request = "# Cycle\n\n## Active evals\n\n- `task-ecount`\n"
  let planned_request = "# Cycle\n\n## Trial plan\n\n- Count: `2`\n\n## New eval proposals\n\n- Count: `1`\n"
  let ticket_request = "# Cycle\n\n## Mode\n\n- `ticket-implementation`\n\n## Approved tickets\n\n- `task-tags-001`\n- `task-ecount-002`\n"
  let organization_request = "# Cycle\n\n## Mode\n\n- `organization`\n\n## Active evals\n\n- `task-ecount`\n\n## Trial plan\n\n- Count: `1`\n\n## New eval proposals\n\n- Count: `1`\n\n## Approved tickets\n\n- None.\n"
  let design_request = "# Cycle\n\n## Mode\n\n- `eval-design`\n\n## Active evals\n\n- `task-tags`\n\n## New eval proposals\n\n- Count: `1`\n"
  test.eq(control.request_mode(eval_request), "eval")?
  test.eq(control.request_eval(eval_request), "task-ecount")?
  test.eq(control.request_mode(ticket_request), "ticket-implementation")?
  test.eq(control.request_mode(organization_request), "organization")?
  test.eq(control.request_mode(design_request), "eval-design")?
  test.eq(control.request_eval(organization_request), "task-ecount")?
  test.eq(control.request_new_eval_count(organization_request)?, 1)?
  test.eq(control.request_eval(design_request), "task-tags")?
  test.eq(control.request_tickets(ticket_request), ["task-tags-001", "task-ecount-002"])?
  test.eq(control.request_ticket_policy(ticket_request), "explicit")?
  test.eq(control.request_ticket_policy(organization_request), "none")?
  test.eq(control.request_trial_count(planned_request)?, 2)?
  test.eq(control.request_new_eval_count(planned_request)?, 1)?
  test.eq(control.request_trial_count(eval_request)?, 1)?
  test.eq(control.request_new_eval_count(eval_request)?, 0)?
}

proc test_role_configuration_has_one_coded_default() [env, error] {
  test.eq(control.default_cycle_budget(), "0.50")?
  test.eq(control.clamp_cycle_budget("0.50")?, "0.50")?
  test.eq(control.clamp_cycle_budget("0.25")?, "0.25")?
  test.eq(control.clamp_cycle_budget("2.00")?, "0.50")?
  for entry in [
    {role: "director", budget: "0.06"},
    {role: "eval-designer", budget: "0.30"},
    {role: "eval-manager", budget: "0.15"},
    {role: "eval-worker", budget: "0.50"},
    {role: "xsh-swe", budget: "0.25"},
  ] {
    test.ok(control.role_prefix(entry.role) != "")?
    test.eq(control.default_provider(entry.role), "openrouter")?
    test.eq(control.default_model(entry.role), "deepseek/deepseek-v4-flash-0731")?
    test.eq(control.default_thinking(entry.role), "high")?
    test.eq(control.default_budget(entry.role), entry.budget)?
    let expected_tools = if entry.role == "eval-worker" { "read,write,edit,bash" } else { "read,write,edit,bash,grep,find,ls" }
    test.eq(control.default_tools(entry.role), expected_tools)?
  }
  env FACTORY_DIRECTOR_BUDGET_USD="2" {
    test.eq(control.configured_role_setting("director", "BUDGET_USD")?, "0.06")?
  }
  env FACTORY_DIRECTOR_BUDGET_USD="0.01" {
    test.eq(control.configured_role_setting("director", "BUDGET_USD")?, "0.01")?
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
  test.ok(control.ticket_is_accepted("# Ticket\n\n## Status\n\nApproved.\n"))?
  test.ok(! control.ticket_is_accepted("# Ticket\n\n## Status\n\nOpen.\n"))?
  test.ok(control.ticket_is_closed("# Ticket\n\n## Status\n\nClosed.\n"))?
  test.ok(control.eval_is_disabled("# Eval\n\n## Status\n\nDisabled.\n"))?
}

proc test_first_approved_ticket_is_deterministic(ctx: TestContext) [fs, error] {
  let factory = test.temp_dir(ctx, name: "approved-ticket")?
  fs.mkdir(fp"${factory}/tickets")?
  fs.write(fp"${factory}/tickets/z-open.md", "# Ticket\n\n## Status\n\nOpen.\n")?
  fs.write(fp"${factory}/tickets/b-approved.md", "# Ticket\n\n## Status\n\nApproved.\n")?
  fs.write(fp"${factory}/tickets/a-accepted.md", "# Ticket\n\n## Status\n\nAccepted.\n")?
  test.eq(runtime.first_approved_ticket(factory)?, "a-accepted")?
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

proc test_budget_breach_transitions_are_durable_and_idempotent(ctx: TestContext) [fs, error] {
  let factory = test.temp_dir(ctx, name: "budget-transitions")?
  fs.mkdir(fp"${factory}/tickets")?
  fs.mkdir(fp"${factory}/evals/task-tags")?
  fs.mkdir(fp"${factory}/templates")?
  fs.mkdir(fp"${factory}/runs/run-1/workers/xsh-swe/task-tags-002")?
  fs.mkdir(fp"${factory}/runs/run-2/workers/eval-worker/task-tags-1")?
  fs.copy(fp"${fs.cwd()?}/templates/BUDGET-BREACH.md", fp"${factory}/templates/BUDGET-BREACH.md", overwrite: true)?
  fs.write(fp"${factory}/tickets/task-tags-002.md", "# Ticket task-tags-002\n\n## Status\n\nApproved.\n")?
  fs.write(fp"${factory}/evals/task-tags/EVAL.md", "# Eval task-tags\n\n## Status\n\nApproved.\n")?

  let ticket_worker = fp"${factory}/runs/run-1/workers/xsh-swe/task-tags-002"
  let eval_worker = fp"${factory}/runs/run-2/workers/eval-worker/task-tags-1"
  test.ok(runtime.close_ticket_too_difficult(factory, "task-tags-002", ticket_worker)?)?
  let closed = fs.read_text(fp"${factory}/tickets/task-tags-002.md")?
  test.ok(control.ticket_is_closed(closed))?
  test.contains(closed, "Reason: too difficult")?
  test.contains(closed, "runs/run-1/workers/xsh-swe/task-tags-002/WORKER-REPORT.md")?
  let closed_again = runtime.close_ticket_too_difficult(factory, "task-tags-002", ticket_worker)?
  test.ok(closed_again)?
  test.eq(fs.read_text(fp"${factory}/tickets/task-tags-002.md")?, closed)?

  test.ok(runtime.disable_eval(factory, "task-tags", eval_worker)?)?
  let disabled = fs.read_text(fp"${factory}/evals/task-tags/EVAL.md")?
  test.ok(control.eval_is_disabled(disabled))?
  test.contains(disabled, "Reason: eval-worker budget exceeded")?
  test.contains(disabled, "runs/run-2/workers/eval-worker/task-tags-1/WORKER-REPORT.md")?
  test.ok(runtime.disable_eval(factory, "task-tags", eval_worker)?)?
  test.eq(fs.read_text(fp"${factory}/evals/task-tags/EVAL.md")?, disabled)?
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

proc test_reconcile_detects_a_patch_applied_branch(ctx: TestContext) [fs, process, error] {
  let repo = test.temp_dir(ctx, name: "reconcile-patch-repo")?
  let factory = test.temp_dir(ctx, name: "reconcile-patch-factory")?
  let git = process.which("git")?
  test.ok(run_git(git, ["git", "init", "-q", "-b", "main", repo.display()])?)?
  test.ok(run_git(git, ["git", "-C", repo.display(), "config", "user.email", "factory@test"])?)?
  test.ok(run_git(git, ["git", "-C", repo.display(), "config", "user.name", "Factory Test"])?)?
  fs.write(fp"${repo}/README", "base\n")?
  test.ok(run_git(git, ["git", "-C", repo.display(), "add", "README"])?)?
  test.ok(run_git(git, ["git", "-C", repo.display(), "commit", "-qm", "base"])?)?
  let branch = "factory/reconcile-patch/1"
  test.ok(run_git(git, ["git", "-C", repo.display(), "checkout", "-q", "-b", branch])?)?
  fs.write(fp"${repo}/README", "applied change\n")?
  test.ok(run_git(git, ["git", "-C", repo.display(), "add", "README"])?)?
  test.ok(run_git(git, ["git", "-C", repo.display(), "commit", "-qm", "implementation"])?)?
  let implementation = run.text "git" "-C" $repo.display() "rev-parse" "HEAD" ?
  test.ok(run_git(git, ["git", "-C", repo.display(), "checkout", "-q", "main"])?)?
  fs.write(fp"${repo}/README", "applied change\n")?
  test.ok(run_git(git, ["git", "-C", repo.display(), "add", "README"])?)?
  test.ok(run_git(git, ["git", "-C", repo.display(), "commit", "-qm", "applied patch"])?)?
  let head = run.text "git" "-C" $repo.display() "rev-parse" "HEAD" ?

  fs.mkdir(fp"${factory}/tickets")?
  fs.mkdir(fp"${factory}/templates")?
  fs.copy(fp"${fs.cwd()?}/templates/TICKET.md", fp"${factory}/templates/TICKET.md", overwrite: true)?
  fs.write(fp"${factory}/tickets/reconcile-patch.md", f"# Ticket\n\n## Status\n\nApproved.\n\n## Merge record\n\n- Implementation branch: `${branch}`\n- Implementation commit: `${implementation.trim()}`\n")?
  let merged = runtime.reconcile_tickets(factory, repo, head.trim())?
  test.eq(merged.len(), 1, "a patch-applied branch should reconcile as merged")?
  let ticket = fs.read_text(fp"${factory}/tickets/reconcile-patch.md")?
  test.ok(control.ticket_is_merged(ticket))?
  test.contains(ticket, f"Implementation branch: `${branch}`")?
}

proc test_lifecycle_rejects_improvised_transitions() [error] {
  test.ok(control.transition_allowed("created", "admitted"))?
  test.ok(control.transition_allowed("created", "started"))?
  test.ok(control.transition_allowed("admitted", "started"))?
  test.ok(control.transition_allowed("started", "completed"))?
  test.ok(control.transition_allowed("completed", "validated"))?
  test.ok(! control.transition_allowed("started", "validated"))?
  test.ok(control.transition_allowed("validated", "ready-for-review"))?
  test.ok(control.transition_allowed("ready-for-review", "accepted"))?
  test.ok(control.transition_allowed("accepted", "reverted"))?
  test.ok(! control.transition_allowed("ready-for-review", "failed"))?
  test.ok(control.transition_allowed("started", "failed"))?
}

proc test_audit_boundary_completes_before_validation(ctx: TestContext) [fs, error] {
  let root = test.temp_dir(ctx, name: "audit-boundary")?
  let template = fp"${root}/EVENT.md"
  fs.copy(fp"${fs.cwd()?}/templates/EVENT.md", template, overwrite: true)?
  runtime.emit_event(template, root, "00-cycle-started", "phase", "started", 1, "controller", "fixture")?
  runtime.mark_phase_completed(template, root, "85-cycle-audited", "phase", 1, "controller", "fixture")?
  test.eq(fs.read_text(fp"${root}/states/phase.state")?, "completed\n")?
  runtime.emit_event(template, root, "95-cycle-validated", "phase", "validated", 1, "controller", "fixture")?
  test.eq(fs.read_text(fp"${root}/states/phase.state")?, "validated\n")?
  test.ok(fs.exists(fp"${root}/events/85-cycle-audited.md")?)?
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

proc test_eval_overlay_build_uses_local_base_without_pull() {
  let build_args = control.eval_overlay_build_args(
    "xsh-factory-base:latest", "build-1", "xsh-factory-task:latest",
    "linux/arm64", p"evals/Dockerfile", p"evals/task",
  )
  test.ok(! ("--no-cache" in build_args))?
  test.ok(! ("--pull" in build_args))?
  test.ok("BASE_IMAGE=xsh-factory-base:latest" in build_args)?
  let forced_args = control.eval_overlay_build_args(
    "xsh-factory-base:latest", "build-1", "xsh-factory-task:latest",
    "linux/arm64", p"evals/Dockerfile", p"evals/task", true,
  )
  test.ok("--no-cache" in forced_args)?
  test.ok(control.toolchain_cache_valid(false, true, "key", "key", true))?
  test.ok(! control.toolchain_cache_valid(false, true, "old", "key", true))?
  test.ok(! control.toolchain_cache_valid(false, true, "key", "key", false))?
  test.ok(! control.toolchain_cache_valid(true, true, "key", "key", true))?
}

proc test_controller_outputs_and_build_cache_are_explicit() [fs, error] {
  let factory = fs.cwd()?
  let runner = fs.read_text(fp"${factory}/run-agent.xsh")?
  let worker_template = fs.read_text(fp"${factory}/templates/WORKER.md")?
  let eval_controller = fs.read_text(fp"${factory}/run-eval.xsh")?
  let organization = fs.read_text(fp"${factory}/run-organization.xsh")?
  let product_makefile = fs.read_text(fp"${factory}/../xsh/Makefile")?
  let base_dockerfile = fs.read_text(fp"${factory}/evals/Dockerfile.base")?
  test.contains(runner, "FACTORY_REQUIRED_REPORT")?
  test.contains(runner, "REPORT-MISSING")?
  test.contains(worker_template, "Required narrative report")?
  test.contains(eval_controller, "eval-build.lock")?
  test.contains(eval_controller, "XSH_TEST_IMAGE_BUILD")?
  test.contains(eval_controller, "FACTORY_FORCE_XSH_TOOLCHAIN_REBUILD")?
  test.contains(eval_controller, "xsh-build.state")?
  test.contains(eval_controller, "uname")?
  test.contains(organization, "let independent_eval_handle = spawn_child")?
  test.contains(organization, "primary_ok = wait_child(primary_handle)")?
  test.contains(product_makefile, "XSH_TEST_IMAGE_BUILD")?
  test.contains(product_makefile, "docker image inspect")?
  test.ok(base_dockerfile.find("ADD --chmod") < base_dockerfile.find("LABEL org.xsh.factory.build-id"))?
}

proc test_ecount_oracle_command_has_a_fail_closed_awk_boundary() [error] {
  let command = control.ecount_oracle_command()
  test.eq(command[0], "sh")?
  test.eq(command[1], "-c")?
  test.ok(command[2].contains("set -o pipefail"))?
  test.ok(command[2].contains("tolower($NF)"))?
  test.ok(! command[2].contains("\\$NF"))?
  test.ok(control.ecount_oracle_ok(true, "oracle output"))?
  test.ok(! control.ecount_oracle_ok(true, ""))?
  test.ok(! control.ecount_oracle_ok(false, "oracle output"))?
  test.eq(control.ecount_classification(true, true, true, false, false, false), "evaluator_failed")?
  test.eq(control.ecount_classification(true, true, true, true, false, true), "candidate_failed")?
}

proc test_runtime_phase_locks_allow_independent_children(ctx: TestContext) [fs, error] {
  let root = test.temp_dir(ctx, name: "phase-locks")?
  let first_dir = fp"${root}/phase-one"
  let second_dir = fp"${root}/phase-two"
  fs.mkdir(first_dir)?
  fs.mkdir(second_dir)?
  let first = runtime.acquire_run_lock_at(fp"${first_dir}/factory.lock")?
  let second = runtime.acquire_run_lock_at(fp"${second_dir}/factory.lock")?
  test.ok(fs.exists(fp"${first_dir}/factory.lock")?)?
  test.ok(fs.exists(fp"${second_dir}/factory.lock")?)?
}
