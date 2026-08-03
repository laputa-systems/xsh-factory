##! Native tests for structured reports, shutdown, and patch boundaries.

use factory_control as control
use factory_runtime as runtime
use report_schema as schema

proc command_ok(command: Path, args: List[Str]) [process, error] -> Result[Bool] {
  return process.run(process.command_argv(command, args))?.ok
}

proc run_session_report(root: Path, session: Path, output: Path) [fs, process, error] -> Result[Bool] {
  let xsh = process.which("xsh")?
  let status = process.run(process.command_argv(
    xsh,
    [xsh.display(), fp"${fs.cwd()?}/tools/session-report.xsh", "--", "worker",
      "--session", session.display(), "--output", output.display(),
      "--role", "eval-worker", "--worker-id", "fixture", "--budget-usd", "0.50"],
    env: {FACTORY_DIR: fs.cwd()?.display(), XSH_MODULE_PATH: fs.cwd()?.display()},
  ))?
  return status.ok
}

proc test_session_report_is_structured_and_counts_thinking(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "structured-session")?
  let session = fp"${root}/session.jsonl"
  let output = fp"${root}/report.json"
  fs.write(session, r"""
{"timestamp":"2026-08-01T12:00:00.000Z","type":"message","message":{"role":"user","content":"task"}}
{"timestamp":"2026-08-01T12:00:01.000Z","type":"message","message":{"role":"assistant","provider":"openrouter","model":"deepseek/deepseek-v4-flash-0731","stopReason":"toolUse","content":[{"type":"thinking","thinking":"inspect"},{"type":"toolCall","name":"read"}],"usage":{"input":10,"output":20,"reasoning":7,"totalTokens":30,"cost":{"total":0.003}}}}
{"timestamp":"2026-08-01T12:00:02.000Z","type":"message","message":{"role":"toolResult","toolName":"read","isError":false,"usage":{"input":2,"output":3,"totalTokens":5,"cost":{"total":0.0005}}}}
""")?
  let status = run_session_report(root, session, output)?
  test.ok(status, "known-cost session should normalize successfully")?
  let report = json.read(output)?
  test.ok(schema.valid(report, "worker"))?
  test.eq(json.get(report, ["usage", "assistant_turns"], 0), 1)?
  test.eq(json.get(report, ["usage", "thinking_blocks"], 0), 1)?
  test.eq(schema.value_text(json.get(report, ["usage", "reasoning_tokens"], null)), "7")?
  test.eq(json.get(report, ["usage", "tool_errors"], 0), 0)?
  test.eq(json.get(report, ["result"], "unknown"), "pass")?
  test.ok(! fs.exists(fp"${root}/WORKER-REPORT.md")?)?
  test.ok(! fs.exists(fp"${root}/thinking.md")?)?
}

proc test_session_report_retains_every_tool_error_in_json(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "structured-tool-errors")?
  let session = fp"${root}/session.jsonl"
  let output = fp"${root}/report.json"
  fs.write(session, r"""
{"timestamp":"2026-08-01T12:00:01.000Z","type":"message","message":{"role":"assistant","provider":"openrouter","model":"fixture","content":[{"type":"toolCall","name":"bash"}],"usage":{"input":1,"output":1,"cost":{"total":0.001}}}}
{"timestamp":"2026-08-01T12:00:02.000Z","type":"message","message":{"role":"toolResult","toolName":"bash","isError":true,"content":[{"type":"text","text":"invalid xsht api query 1"}]}}
{"timestamp":"2026-08-01T12:00:03.000Z","type":"message","message":{"role":"assistant","provider":"openrouter","model":"fixture","content":[{"type":"toolCall","name":"bash"}]}}
{"timestamp":"2026-08-01T12:00:04.000Z","type":"message","message":{"role":"toolResult","toolName":"bash","isError":true,"content":[{"type":"text","text":"invalid xsht api query 2"}]}}
""")?
  let status = run_session_report(root, session, output)?
  test.ok(status, "tool failures do not prevent structured normalization")?
  let report = json.read(output)?
  test.eq(json.get(report, ["usage", "tool_errors"], 0), 2)?
  let errors = json.get(report, ["tool_errors"], [])
  match errors {
    values is List[Any] => {
      test.eq(values.len(), 2)?
      test.contains(schema.value_text(json.get(values[0], ["summary"], "")), "invalid xsht api query 1")?
      test.contains(schema.value_text(json.get(values[1], ["summary"], "")), "invalid xsht api query 2")?
    }
    _ => test.ok(false, "tool_errors must be a JSON list")?
  }
  test.ok(! fs.exists(fp"${root}/TOOL-ERRORS.md")?)?
}

proc test_session_report_fails_closed_on_unknown_cost(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "unknown-cost")?
  let session = fp"${root}/session.jsonl"
  let output = fp"${root}/report.json"
  fs.write(session, "{\"type\":\"message\",\"message\":{\"role\":\"assistant\",\"content\":[]}}\n")?
  let status = run_session_report(root, session, output)?
  test.ok(! status, "unknown provider cost must fail the worker gate")?
  test.eq(json.get(json.read(output)?, ["result"], ""), "unknown")?
}

proc write_eval_phase_fixture(root: Path, factory: Path) [fs, error] -> Result[Unit] {
  fs.mkdir(fp"${root}/workers/eval-worker/task-tags-1")?
  fs.mkdir(fp"${root}/workers/eval-manager/task-tags")?
  fs.mkdir(fp"${root}/workers/director/director")?
  fs.mkdir(fp"${root}/lineage")?
  fs.copy(fp"${factory}/runtime/handbook.md", fp"${root}/lineage/handbook-approved.md", overwrite: true)?
  fs.write(fp"${root}/lineage/handbook-candidate.md", "candidate handbook\n")?
  fs.mkdir(fp"${root}/phases/02-eval-design")?
  fs.write(fp"${root}/phases/02-eval-design/CTO-EVAL-REVIEW.md", "# Eval review\n\nphase review\n")?
  fs.write(fp"${root}/CYCLE-REQUEST.md", "# Cycle\n\n## Mode\n\n- `eval`\n\n## Active evals\n\n- `task-tags`\n\n## Trial plan\n\n- Count: `1`\n\n## New eval proposals\n\n- Count: `0`\n")?
  fs.write(fp"${root}/lineage/handbook-approved.md", "approved\n")?
  fs.write(fp"${root}/lineage/handbook-candidate.md", "candidate\n")?
  json.write(fp"${root}/workers/eval-worker/task-tags-1/report.json", {
    schema_version: 1, kind: "worker", identity: {role: "eval-worker", worker_id: "task-tags-1"},
    state: "completed", result: "pass", session: "workers/eval-worker/task-tags-1/session.jsonl",
    execution: {result: "fail", classification: "worker_failed"},
    usage: {assistant_turns: 2, total_bucket_tokens: 30, cost_usd: 0.01, budget_usd: 0.50, tool_errors: 0},
    tool_errors: [], findings: [], artifacts: []
  }, pretty: true)?
  fs.write(fp"${root}/workers/eval-worker/task-tags-1/session.jsonl", "{}\n")?
  fs.write(fp"${root}/workers/eval-worker/task-tags-1/run.json", "{\"eval_id\":\"task-tags\",\"trial_id\":\"1\",\"result\":\"pass\",\"protocol\":{\"artifact_present\":true,\"review_ok\":true},\"correctness\":{\"passed\":true},\"restrictions\":{\"passed\":true},\"timings\":{\"passed\":true}}\n")?
  json.write(fp"${root}/workers/eval-manager/task-tags/report.json", {
    schema_version: 1, kind: "worker", identity: {role: "eval-manager", worker_id: "task-tags"},
    state: "completed", result: "pass", usage: {assistant_turns: 1, total_bucket_tokens: 10, cost_usd: 0.01, budget_usd: 0.15, tool_errors: 0}, tool_errors: [], findings: [], artifacts: []
  }, pretty: true)?
  json.write(fp"${root}/workers/director/director/report.json", {
    schema_version: 1, kind: "worker", identity: {role: "director", worker_id: "director"},
    state: "completed", result: "pass", usage: {assistant_turns: 1, total_bucket_tokens: 10, cost_usd: 0.01, budget_usd: 0.06, tool_errors: 0}, tool_errors: [], findings: [], artifacts: []
  }, pretty: true)?
  fs.write(fp"${root}/workers/eval-manager/task-tags/REPORT.md", "# Manager\n\n## Result\n\npass\n\n## Effort metrics\n\nfixture\n\n## Usage and cost\n\nfixture\n\n## Thinking evidence\n\nfixture\n\n## Tool-error findings\n\nNone.\n\n## Timing evidence\n\nfixture\n\n## Observation classification\n\nfixture\n\n## Handbook decision\n\nunchanged\n\n## Tickets created\n\nNone.\n\n## Post-merge decisions\n\nNone.\n\n## Next replay\n\nNone.\n\n## North-star impact\n\nfixture\n")?
  fs.write(fp"${root}/workers/director/director/REPORT.md", "# Director\n\n## Result\n\npass\n\n## Cycle\n\nfixture\n\n## Children\n\nfixture\n\n## Required-output status\n\npass\n\n## North-star impact\n\nfixture\n")?
  fs.write(fp"${factory}/NORTH-STAR.md", fs.read_text(fp"${factory}/NORTH-STAR.md")?)?
  return Ok()
}

proc test_audit_compiles_one_phase_report(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "audit-phase")?
  let factory = fs.cwd()?
  write_eval_phase_fixture(root, factory)?
  let xsh = process.which("xsh")?
  let status = process.run(process.command_argv(
    xsh, [xsh.display(), fp"${factory}/audit-run.xsh", "--", root.display(), "eval"],
    cwd: factory, env: {FACTORY_DIR: factory.display(), XSH_MODULE_PATH: factory.display(), FACTORY_XSH_COMMIT: "fixture"},
  ))?
  test.ok(status.ok, "audit compiler should produce a phase report")?
  let report = json.read(fp"${root}/report.json")?
  test.ok(schema.valid(report, "phase"))?
  test.eq(json.get(report, ["result"], ""), "pass")?
  test.eq(json.get(report, ["data", "cost", "tool_errors"], -1), 0)?
  test.eq(json.get(report, ["data", "tool_errors"], []).len(), 0)?
  test.ok(! fs.exists(fp"${root}/AUDIT.md")?)?
  test.ok(! fs.exists(fp"${root}/COST.md")?)?
}

proc test_organization_audit_only_admits_direct_phase_children(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "audit-organization")?
  let factory = fs.cwd()?
  fs.mkdir(fp"${root}/phases/01-eval/workers/eval-worker")?
  json.write(fp"${root}/phases/01-eval/report.json", {
    schema_version: 1, kind: "phase", identity: {run_id: "01-eval", mode: "eval"},
    state: "completed", result: "pass", data: {cost: {workers: 0, assistant_turns: 0, total_bucket_tokens: 0, cost_usd: 0.0, tool_errors: 0}}, findings: [], artifacts: []
  }, pretty: true)?
  let xsh = process.which("xsh")?
  let status = process.run(process.command_argv(
    xsh, [xsh.display(), fp"${factory}/audit-run.xsh", "--", root.display(), "organization"],
    cwd: factory, env: {FACTORY_DIR: factory.display(), XSH_MODULE_PATH: factory.display(), FACTORY_XSH_COMMIT: "fixture"},
  ))?
  test.ok(status.ok, "organization audit should accept the direct phase")?
  let report = json.read(fp"${root}/report.json")?
  test.ok(schema.valid(report, "run"))?
  test.eq(json.get(report, ["result"], ""), "pass")?
  let phases = json.get(report, ["data", "phases"], [])
  match phases {
    values is List[Any] => test.eq(values.len(), 1)?
    _ => test.ok(false, "organization phases must be a list")?
  }
}

proc test_cto_briefing_reads_json_not_projection(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "cto-briefing")?
  let factory = fs.cwd()?
  write_eval_phase_fixture(root, factory)?
  json.write(fp"${root}/report.json", {
    schema_version: 1, kind: "phase", identity: {run_id: "fixture", mode: "eval"},
    state: "completed", result: "pass", data: {cost: {workers: 1, assistant_turns: 2, total_bucket_tokens: 30, cost_usd: 0.01, tool_errors: 0}}, findings: [], artifacts: []
  }, pretty: true)?
  let output = fp"${root}/CTO-REPORT.md"
  let xsh = process.which("xsh")?
  let status = process.run(process.command_argv(
    xsh, [xsh.display(), fp"${factory}/tools/cto-report.xsh", "--", "--run-dir", root.display(), "--output", output.display(), "--result", "pass"],
    cwd: factory, env: {FACTORY_DIR: factory.display(), XSH_MODULE_PATH: factory.display()},
  ))?
  test.ok(status.ok, "CTO compiler should consume structured reports")?
  let text = fs.read_text(output)?
  test.contains(text, "Structured run or phase report")?
  test.contains(text, "workers/eval-worker/task-tags-1/report.json")?
  test.contains(text, "Execution: `fail`; classification: `worker_failed`")?
  test.contains(text, "- Result: `pass`")?
  test.contains(text, "phases/02-eval-design/CTO-EVAL-REVIEW.md")?
  test.contains(text, "phase review")?
  test.contains(text, "CTO-IMPROVEMENT.md")?
  test.contains(text, "## Handbook lineage")?
  test.contains(text, "lineage/handbook-candidate.md")?
  test.contains(text, "promotion or rejection decision required")?
  test.contains(text, "Historical candidates:")?
  test.contains(text, "ledger-dispositioned:")?
  test.ok(! text.contains("COST.md"))?
  test.ok(! text.contains("TOOL-ERRORS.md"))?
}

proc test_aggregate_budget_breach_writes_postmortem_and_stops(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "aggregate-budget")?
  let session = fp"${root}/session.jsonl"
  let marker = fp"${root}/AGGREGATE-BUDGET-BREACH"
  let stop = fp"${root}/AGGREGATE-BUDGET-STOP"
  let postmortem = fp"${root}/POSTMORTEM.md"
  fs.write(session, "{\"type\":\"message\",\"message\":{\"role\":\"assistant\",\"usage\":{\"cost\":{\"total\":0.60}}}}\n")?
  let child = spawn process.command_argv("sh", ["sh", "-c", "sleep 5"])?
  let xsh = process.which("xsh")?
  let status = process.run(process.command_argv(
    xsh, [xsh.display(), fp"${fs.cwd()?}/tools/cycle-budget-watch.xsh", "--",
      "--run-dir", root.display(), "--pid", f"${child.pid}", "--budget-usd", "0.50",
      "--marker", marker.display(), "--stop", stop.display(), "--postmortem", postmortem.display()],
    env: {FACTORY_DIR: fs.cwd()?.display(), XSH_MODULE_PATH: fs.cwd()?.display()},
  ))?
  let child_status = wait child?
  test.ok(! status.ok, "aggregate breach watcher must return failure")?
  test.ok(! child_status.ok, "aggregate breach must terminate its controller-owned child")?
  test.ok(fs.exists(marker)?)?
  test.ok(fs.exists(postmortem)?)?
  test.contains(fs.read_text(postmortem)?, "Factory cycle postmortem")?
}

proc test_engineer_patch_survives_worktree_cleanup(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "patch-cleanup")?
  let product = fp"${root}/product"
  let worktree = fp"${root}/worktree"
  let patches = fp"${root}/patches"
  fs.mkdir(product)?
  fs.mkdir(patches)?
  let git = process.which("git")?
  test.ok(command_ok(git, ["git", "-C", product.display(), "init", "-q", "-b", "main"])?)?
  test.ok(command_ok(git, ["git", "-C", product.display(), "config", "user.email", "factory@test"])?)?
  test.ok(command_ok(git, ["git", "-C", product.display(), "config", "user.name", "Factory Test"])?)?
  fs.write(fp"${product}/README", "base\n")?
  test.ok(command_ok(git, ["git", "-C", product.display(), "add", "README"])?)?
  test.ok(command_ok(git, ["git", "-C", product.display(), "commit", "-qm", "base"])?)?
  let base = run.text "git" "-C" $product.display() "rev-parse" "HEAD" ?
  test.ok(command_ok(git, ["git", "-C", product.display(), "worktree", "add", "-q", "-b", "factory/test", worktree.display(), base.trim()])?)?
  fs.write(fp"${worktree}/README", "base\nchanged\n")?
  test.ok(command_ok(git, ["git", "-C", worktree.display(), "add", "README"])?)?
  test.ok(command_ok(git, ["git", "-C", worktree.display(), "commit", "-qm", "change"])?)?
  let head = run.text "git" "-C" $worktree.display() "rev-parse" "HEAD" ?
  let diff_path = fp"${patches}/task.diff"
  test.ok(runtime.write_engineer_patch(worktree, base.trim(), head.trim(), diff_path, fp"${patches}/task.stderr")?)
  test.contains(fs.read_text(diff_path)?, "+changed")?
  test.ok(runtime.remove_clean_worktree(product, worktree)?)?
  test.ok(! fs.exists(worktree)?)?
  test.contains(run.text "git" "-C" $product.display() "branch" "--list" "factory/test" ?, "factory/test")?
}

proc test_organization_reuses_existing_branch_without_duplicate_dispatch() [fs, error] {
  let organization = fs.read_text(fp"${fs.cwd()?}/run-organization.xsh")?
  let reuse = fs.read_text(fp"${fs.cwd()?}/run-ticket-reuse.xsh")?
  let launcher = fs.read_text(fp"${fs.cwd()?}/run.xsh")?
  test.contains(organization, "run_reuse_phase")?
  test.contains(reuse, "mode: \"ticket-reuse\"")?
  test.contains(reuse, "worktree", "existing branch must use a detached worktree")?
  test.contains(launcher, "open_branch != \"\" and mode != \"organization\"")?
}

proc test_ticket_cycle_bounds_concurrent_engineers() [fs, error] {
  let ticket = fs.read_text(fp"${fs.cwd()?}/run-ticket.xsh")?
  let director = fs.read_text(fp"${fs.cwd()?}/roles/director.md")?
  let organization = fs.read_text(fp"${fs.cwd()?}/run-organization.xsh")?
  test.contains(ticket, "max_concurrent_engineers()")?
  test.contains(ticket, r"""at most ${control.max_concurrent_engineers()} engineer tickets""")?
  test.contains(ticket, "if ! director_status.ok")?
  test.contains(ticket, "runtime.cleanup_active_run()")?
  test.contains(ticket, "spawn_engineer")?
  test.contains(ticket, "engineer_handles")?
  test.contains(ticket, "controller-dispatching engineer worker")?
  test.contains(director, "launch all children")?
  test.contains(organization, "ticket_worker_pass(primary_phase, ticket_id)")?
  test.contains(organization, "let reeval_ok = ticket_primary_pass and run_child")?
}

proc test_eval_mode_has_no_paid_director_review() [fs, error] {
  let evaluator = fs.read_text(fp"${fs.cwd()?}/run-eval.xsh")?
  let auditor = fs.read_text(fp"${fs.cwd()?}/audit-run.xsh")?
  test.ok(! evaluator.contains("20-director-started"))?
  test.ok(! evaluator.contains("director_handle"))?
  test.contains(auditor, "result: \"not-requested\"")?
  test.contains(auditor, "if mode == \"ticket-implementation\"")?
}

proc test_eval_gate_diagnostics_are_persisted() [fs, error] {
  let evaluator = fs.read_text(fp"${fs.cwd()?}/run-eval.xsh")?
  test.contains(evaluator, "required-outputs.json")?
  test.contains(evaluator, "write_preflight_failure_report")?
  test.contains(evaluator, "preflight-failure")?
  test.contains(evaluator, "manager_evidence_read")?
  test.contains(evaluator, "designer_handbook_read")?
}

proc test_eval_dispatch_is_package_owned() [fs, error] {
  let common = fs.read_text(fp"${fs.cwd()?}/evaluate_common.xsh")?
  let executor = fs.read_text(fp"${fs.cwd()?}/eval-executor.xsh")?
  test.ok(! common.contains("task-tags"))?
  test.ok(! common.contains("task-ecount"))?
  test.ok(! common.contains("task-envcfg"))?
  test.contains(common, "FACTORY_EVAL_EVALUATOR")?
  test.contains(executor, "evaluator.xsh")?
  for eval_id in ["task-tags", "task-ecount", "task-envcfg"] {
    test.ok(fs.exists(fp"${fs.cwd()?}/evals/${eval_id}/evaluator.xsh")?)?
  }
}

proc test_eval_design_stages_and_promotes_complete_package() [fs, error] {
  let controller = fs.read_text(fp"${fs.cwd()?}/run-design.xsh")?
  let assignment = fs.read_text(fp"${fs.cwd()?}/templates/EVAL-DESIGNER-ASSIGNMENT.md")?
  let role = fs.read_text(fp"${fs.cwd()?}/roles/eval-designer.md")?
  let review = fs.read_text(fp"${fs.cwd()?}/templates/CTO-EVAL-REVIEW.md")?
  test.contains(controller, "\"evaluator.xsh\"")?
  test.contains(controller, "promote_eval_proposal")?
  test.contains(controller, "84-cto-reviewed")?
  test.contains(controller, "evaluator_check_ok")?
  test.contains(assignment, "including `evaluator.xsh`")?
  test.contains(assignment, "new valid `task-*` ID")?
  test.contains(assignment, "not already present under")?
  test.contains(assignment, "before any further exploration")?
  test.contains(role, "new valid `task-*` ID")?
  test.contains(role, "promotion to fail closed")?
  test.contains(review, "may set `Approved.`")?
  test.contains(review, "MISSING_PACKAGE_FILES")?
  test.contains(review, "Checked-in status")?
}

proc test_process_output_is_written_to_event_ledger(ctx: TestContext) [fs, error] {
  let root = test.temp_dir(ctx, name: "process-events")?
  let output = fp"${root}/child.stdout"
  fs.write(output, "hello\n")?
  runtime.emit_process_output(root, "child-1", "stdout", output, 0)?
  let events = fs.read_text(fp"${root}/events.jsonl")?
  test.contains(events, "process-output")?
  test.contains(events, "child-1:stdout")?
  test.contains(events, "hello\\n")?
}

proc test_cto_handoff_is_staged_for_every_run(ctx: TestContext) [fs, error] {
  let root = test.temp_dir(ctx, name: "cto-handoff")?
  let factory = fs.cwd()?
  runtime.stage_cto_improvement(factory, root)?
  let handoff = fp"${root}/CTO-IMPROVEMENT.md"
  test.ok(fs.exists(handoff)?)?
  test.contains(fs.read_text(handoff)?, "pending-validation")?
  test.contains(fs.read_text(handoff)?, "## Revert condition")?
}

proc test_eval_executor_is_documented_as_controller_not_role() [fs, error] {
  let contract = fs.read_text(fp"${fs.cwd()?}/FACTORY.md")?
  let guide = fs.read_text(fp"${fs.cwd()?}/AGENTS.md")?
  test.contains(contract, "controller program, not a Pi role")?
  test.contains(contract, "it is not an")?
  test.contains(guide, "controller-owned infrastructure, not a role or employee")?
}

proc test_controllers_have_no_legacy_projection_outputs() [fs, error] {
  for file in ["run.xsh", "run-eval.xsh", "run-ticket.xsh", "run-design.xsh", "run-organization.xsh", "audit-run.xsh", "tools/session-report.xsh"] {
    let source = fs.read_text(fp"${fs.cwd()?}/${file}")?
    test.ok(! source.contains("COST.md"), f"${file} must use report.json")?
    test.ok(! source.contains("AUDIT.md"), f"${file} must use report.json")?
    test.ok(! source.contains("TOOL-ERRORS.md"), f"${file} must use structured tool_errors")?
    test.ok(! source.contains("CURRENT-EVIDENCE.md"), f"${file} must not emit evidence projection")?
  }
}

proc test_eval_worker_prompt_matches_task_image() [fs, error] {
  let prompt = fs.read_text(fp"${fs.cwd()?}/roles/eval-worker.md")?
  test.contains(prompt, "BusyBox `sh`, not `bash`")?
  test.contains(prompt, "avoid bash-only syntax")?
  test.contains(prompt, "`and` and `or`, not shell `&&` and `||`")?
}
