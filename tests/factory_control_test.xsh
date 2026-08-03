##! Native tests for factory contracts and lifecycle state.

use factory_control as control
use factory_runtime as runtime
use report_schema as schema

proc test_cycle_request_parsing() [error] {
  let request = "# Cycle\n\n## Mode\n\n- `organization`\n\n## Active evals\n\n- `task-tags`\n\n## Trial plan\n\n- Count: `1`\n\n## New eval proposals\n\n- Count: `1`\n\n## Approved tickets\n\n- `task-tags-001`\n"
  test.eq(control.request_mode(request), "organization")?
  test.eq(control.request_eval(request), "task-tags")?
  test.eq(control.request_tickets(request), ["task-tags-001"])?
  test.eq(control.request_trial_count(request)?, 1)?
  test.eq(control.request_new_eval_count(request)?, 1)?
  test.eq(control.request_ticket_policy(request), "explicit")?
}

proc test_role_defaults_are_coded_and_capped() [env, error] {
  test.eq(control.default_cycle_budget(), "1.00")?
  test.eq(control.clamp_cycle_budget("2.00")?, "1.00")?
  test.eq(control.max_concurrent_engineers(), 2)?
  for role in ["director", "eval-designer", "eval-manager", "eval-worker", "engineer"] {
    test.eq(control.default_provider(role), "openrouter")?
    test.eq(control.default_model(role), "deepseek/deepseek-v4-flash-0731")?
    test.eq(control.default_thinking(role), "high")?
    test.ok(control.default_budget(role) != "")?
    test.ok(control.default_max_turns(role) != "")?
  }
  test.eq(control.default_max_turns("eval-designer"), "64")?
  test.eq(control.default_max_wall_seconds("eval-designer"), "720")?
  test.eq(control.default_max_wall_seconds("eval-manager"), "900")?
  test.eq(control.default_max_wall_seconds("eval-worker"), "1800")?
  test.eq(control.default_max_wall_seconds("engineer"), "1800")?
  env FACTORY_ENGINEER_BUDGET_USD="2" {
    test.eq(control.configured_role_setting("engineer", "BUDGET_USD")?, control.default_budget("engineer"))?
  }
  env FACTORY_ENGINEER_BUDGET_USD="0.01" {
    test.eq(control.configured_role_setting("engineer", "BUDGET_USD")?, "0.01")?
  }
}

proc test_north_star_contains_rationale_without_factory_symlink() [fs, error] {
  let root = fs.cwd()?
  let north_star = fs.read_text(fp"${root}/NORTH-STAR.md")?
  test.contains(north_star, "## XSH rationale")?
  test.contains(north_star, "The Archaeological Site")?
  test.contains(north_star, "next century")?
  test.ok(! fs.exists(fp"${root}/docs/CHAPTER-01-why-xsh.md")?)?
}

proc test_admission_and_report_contracts() [error] {
  test.ok(control.valid_eval_id("task-tags"))?
  test.eq(control.eval_id_from_contract("# Eval task-probe\n\n## Status\n\nDraft.\n"), "task-probe")?
  test.eq(control.eval_id_from_contract("# Proposal\n"), "")?
  test.ok(! control.valid_eval_id("../escape"))?
  test.ok(control.valid_ticket_id("task-tags-001"))?
  test.ok(! control.valid_ticket_id("task/tags"))?
  test.ok(control.ticket_is_accepted("# Ticket\n\n## Status\n\nApproved.\n"))?
  test.ok(control.eval_is_disabled("# Eval\n\n## Status\n\nDisabled.\n"))?
  test.ok(! control.ticket_is_closed("# Ticket\n\n## Status\n\nApproved.\n"))?
  test.ok(control.report_contract_ok("# Report\n\n## Result\n\npass\n\n## Evidence\n\nready\n", ["Evidence"], "pass"))?
  test.ok(! control.report_contract_ok("# Report\n\n## Result\n\npass\n", ["Evidence"], "pass"))?
  test.ok(control.manager_tool_error_findings_contract_ok("## Tool-error findings\n\nreport.json\n"))?
  test.eq(control.report_section("# Report\n\n## Result\n\npass\n\nDetails.\n\n## Evidence\n\nready\n", "Result"), "pass\n\nDetails.")?
  test.eq(control.report_field("# Report\n\n## Result\n\npass\n\nDetails.\n\n## Evidence\n\nready\n", "Result"), "pass")?
}

proc test_eval_proposal_is_promoted_without_acceptance(ctx: TestContext) [fs, error] {
  let factory = test.temp_dir(ctx, name: "eval-promotion")?
  let proposal = fp"${factory}/runs/run-1/proposals/proposal-1"
  fs.mkdir(fp"${proposal}/runtime")?
  fs.mkdir(fp"${factory}/evals")?
  fs.write(fp"${proposal}/EVAL.md", "# Eval task-probe\n\n## Status\n\nDraft.\n")?
  for relative in ["executor.xsh", "evaluate.xsh", "evaluator.xsh", "runtime/task.md", "runtime/artifact.md"] {
    fs.write(fp"${proposal}/${relative}", f"${relative}\n")?
  }
  let run_dir = fp"${factory}/runs/run-1"
  test.ok(runtime.promote_eval_proposal(factory, proposal, run_dir, "rejected")?)?
  let promoted = fp"${factory}/evals/task-probe"
  test.ok(fs.exists(fp"${promoted}/evaluator.xsh")?)?
  let contract = fs.read_text(fp"${promoted}/EVAL.md")?
  test.contains(contract, "## CTO review")?
  test.contains(contract, "Result: `rejected`")?
  test.contains(contract, "Package: `complete`")?
  test.contains(contract, "Status: `Draft.`")?
  test.ok(! runtime.promote_eval_proposal(factory, proposal, run_dir, "accepted")?)?

  let partial = fp"${factory}/runs/run-2/proposals/proposal-1"
  fs.mkdir(fp"${partial}/runtime")?
  fs.write(fp"${partial}/EVAL.md", "# Eval task-legacy\n\n## Status\n\nDraft.\n")?
  for relative in ["executor.xsh", "evaluate.xsh", "runtime/task.md", "runtime/artifact.md"] {
    fs.write(fp"${partial}/${relative}", f"${relative}\n")?
  }
  test.ok(runtime.promote_eval_proposal(factory, partial, fp"${factory}/runs/run-2", "rejected")?)?
  let partial_contract = fs.read_text(fp"${factory}/evals/task-legacy/EVAL.md")?
  test.contains(partial_contract, "Package: `incomplete`")?
  test.contains(partial_contract, "evaluator.xsh")?

  let accepted = fp"${factory}/runs/run-3/proposals/proposal-1"
  fs.mkdir(fp"${accepted}/runtime")?
  fs.write(fp"${accepted}/EVAL.md", "# Eval task-accepted\n\n## Status\n\nDraft.\n")?
  for relative in ["executor.xsh", "evaluate.xsh", "evaluator.xsh", "runtime/task.md", "runtime/artifact.md"] {
    fs.write(fp"${accepted}/${relative}", f"${relative}\n")?
  }
  test.ok(runtime.promote_eval_proposal(factory, accepted, fp"${factory}/runs/run-3", "accepted")?)?
  test.eq(control.ticket_status(fs.read_text(fp"${factory}/evals/task-accepted/EVAL.md")?), "Approved.")?
}

proc test_role_report_skeletons_are_fail_closed() [fs, error] {
  let root = fs.cwd()?
  let manager = fs.read_text(fp"${root}/templates/EVAL-MANAGER-REPORT.md")?
  let director = fs.read_text(fp"${root}/templates/DIRECTOR-REPORT.md")?
  let engineer = fs.read_text(fp"${root}/templates/ENGINEER-REPORT.md")?
  for report in [manager, director, engineer] {
    test.contains(report, "## Result")?
    test.contains(report, "not-ready")?
  }
  test.contains(manager, "## Tool-error findings")?
  test.contains(manager, "## Next replay")?
  test.contains(director, "## Required-output status")?
  test.contains(engineer, "## Commit")?
  let runner = fs.read_text(fp"${root}/run-agent.xsh")?
  test.contains(runner, "EVAL-MANAGER-REPORT.md")?
  test.contains(runner, "DIRECTOR-REPORT.md")?
  test.contains(runner, "ENGINEER-REPORT.md")?
}

proc test_standard_cycle_uses_diverse_active_eval() [fs, error] {
  let request = fs.read_text(fp"${fs.cwd()?}/cycle-organization.md")?
  let task_tags = fs.read_text(fp"${fs.cwd()?}/evals/task-tags/EVAL.md")?
  let improvement = fs.read_text(fp"${fs.cwd()?}/templates/CTO-IMPROVEMENT.md")?
  let launcher = fs.read_text(fp"${fs.cwd()?}/run.xsh")?
  test.contains(request, "`task-envcfg`")?
  test.ok(! request.contains("`task-tags`"))?
  test.ok(control.eval_is_disabled(task_tags))?
  test.contains(task_tags, "special exception")?
  test.contains(improvement, "## Baseline metric")?
  test.contains(improvement, "## Revert condition")?
  test.contains(launcher, "templates/CTO-IMPROVEMENT.md")?
}

proc test_agent_completion_is_report_bound() [error] {
  test.ok(control.agent_completion_ok(true, true, true, true))?
  test.ok(! control.agent_completion_ok(false, true, true, true))?
  test.ok(! control.agent_completion_ok(true, false, true, true))?
  test.ok(! control.agent_completion_ok(true, true, false, true))?
  test.ok(! control.agent_completion_ok(true, true, true, false))?
}

proc test_report_schema_is_single_machine_contract(ctx: TestContext) [fs, error] {
  let root = test.temp_dir(ctx, name: "report-schema")?
  let worker = fp"${root}/worker.json"
  json.write(worker, {
    schema_version: 1, kind: "worker", identity: {role: "engineer", worker_id: "fixture"},
    state: "completed", result: "pass", data: {usage: {assistant_turns: 1}},
    findings: [], artifacts: [{kind: "session", path: "session.jsonl"}]
  }, pretty: true)?
  let value = json.read(worker)?
  test.ok(schema.valid(value, "worker"))?
  test.ok(! schema.valid(value, "phase"))?
  test.eq(schema.value_text(json.get(value, ["result"], null)), "pass")?
}

proc test_lifecycle_rejects_improvised_transitions() [error] {
  test.ok(control.transition_allowed("created", "started"))?
  test.ok(control.transition_allowed("started", "completed"))?
  test.ok(control.transition_allowed("started", "failed"))?
  test.ok(control.transition_allowed("completed", "validated"))?
  test.ok(! control.transition_allowed("created", "validated"))?
  test.ok(! control.transition_allowed("completed", "started"))?
}

proc test_event_ledger_is_jsonl_and_stateful(ctx: TestContext) [fs, error] {
  let root = test.temp_dir(ctx, name: "event-ledger")?
  runtime.emit_event(root, root, "01-start", "worker", "started", 1, "controller", "assigned")?
  runtime.emit_event(root, root, "02-complete", "worker", "completed", 1, "worker", "returned")?
  let events = fp"${root}/events.jsonl"
  test.ok(fs.exists(events)?)?
  let text = fs.read_text(events)?
  test.contains(text, "\"kind\":\"event\"")?
  test.contains(text, "\"event_id\":\"02-complete\"")?
  test.eq(fs.read_text(fp"${root}/states/worker.state")?.trim(), "completed")?
  test.ok(! fs.exists(fp"${root}/events/02-complete.md")?)?
}

proc test_budget_consequences_are_durable(ctx: TestContext) [fs, error] {
  let factory = test.temp_dir(ctx, name: "budget-consequences")?
  fs.mkdir(fp"${factory}/tickets")?
  fs.mkdir(fp"${factory}/evals/task-tags")?
  fs.mkdir(fp"${factory}/templates")?
  fs.copy(fp"${fs.cwd()?}/templates/TICKET.md", fp"${factory}/templates/TICKET.md", overwrite: true)?
  fs.copy(fp"${fs.cwd()?}/templates/BUDGET-BREACH.md", fp"${factory}/templates/BUDGET-BREACH.md", overwrite: true)?
  fs.write(fp"${factory}/tickets/task-tags-002.md", "# Ticket\n\n## Status\n\nApproved.\n")?
  fs.write(fp"${factory}/evals/task-tags/EVAL.md", "# Eval\n\n## Status\n\nApproved.\n")?
  let engineer_report = fp"${factory}/runs/run-1/workers/engineer/task-tags-002/report.json"
  let eval_report = fp"${factory}/runs/run-2/workers/eval-worker/task-tags-1/report.json"
  fs.mkdir(engineer_report.parent())?
  fs.mkdir(eval_report.parent())?
  json.write(engineer_report, {schema_version: 1, kind: "worker", identity: {role: "engineer", worker_id: "task-tags-002"}, state: "completed", result: "fail", findings: [], artifacts: []}, pretty: true)?
  json.write(eval_report, {schema_version: 1, kind: "worker", identity: {role: "eval-worker", worker_id: "task-tags-1"}, state: "completed", result: "fail", findings: [], artifacts: []}, pretty: true)?
  test.ok(runtime.close_ticket_too_difficult(factory, "task-tags-002", engineer_report.parent())?)?
  let closed = fs.read_text(fp"${factory}/tickets/task-tags-002.md")?
  test.ok(control.ticket_is_closed(closed))?
  test.contains(closed, "Reason: too difficult")?
  test.contains(closed, "runs/run-1/workers/engineer/task-tags-002/report.json")?
  test.ok(runtime.disable_eval(factory, "task-tags", eval_report.parent())?)?
  let disabled = fs.read_text(fp"${factory}/evals/task-tags/EVAL.md")?
  test.ok(control.eval_is_disabled(disabled))?
  test.contains(disabled, "Reason: eval-worker budget exceeded")?
  test.contains(disabled, "runs/run-2/workers/eval-worker/task-tags-1/report.json")?
}

proc test_engineer_assignment_is_controller_bound() [error] {
  let assignment = "- Ticket ID: `task-tags-001`\n- Dedicated XSH worktree: `/tmp/work`\n<!-- CONTROLLER_TICKET_SNAPSHOT_BEGIN -->\nticket\n<!-- CONTROLLER_TICKET_SNAPSHOT_END -->\nDo not search for open tickets\n"
  test.ok(control.engineer_assignment_ok("/factory/runs/run-1", "task-tags-001",
    "/factory/runs/run-1/messages/task-tags-001.md", "/tmp/work", assignment))?
  test.ok(! control.engineer_assignment_ok("/factory/runs/run-1", "task-tags-002",
    "/factory/runs/run-1/messages/task-tags-002.md", "/tmp/work", assignment))?
}

proc test_eval_image_inputs_are_local() [fs, error] {
  let dockerfile = fs.read_text(fp"${fs.cwd()?}/evals/Dockerfile.base")?
  let controller = fs.read_text(fp"${fs.cwd()?}/run-eval.xsh")?
  let executor = fs.read_text(fp"${fs.cwd()?}/eval-executor.xsh")?
  test.contains(dockerfile, ".dist/xsh")?
  test.contains(dockerfile, ".dist/xsht")?
  test.contains(controller, "dist-Linux-docker")?
  test.contains(controller, "stage_xsht")?
  test.contains(executor, "--pids-limit")?
  test.contains(executor, "--memory")?
  test.contains(executor, "size=64m")?
}
