##! Native tests for structured reports, shutdown, and patch boundaries.

use factory.control as control
use factory.runtime as runtime
use factory.schema as schema

proc command_ok(command: Path, args: List[Str]) [process, error] -> Result[Bool] {
  return process.run(process.command_argv(command, args))?.ok
}

proc run_session_report(root: Path, session: Path, output: Path) [fs, process, error] -> Result[Bool] {
  let xsh = process.which("xsh")?
  let status = process.run(process.command_argv(
    xsh,
    [xsh.display(), fp"${fs.cwd()?}/factory/tools/session.xsh", "--", "worker",
      "--session", session.display(), "--output", output.display(),
      "--role", "eval-worker", "--worker-id", "fixture", "--budget-usd", "0.50"],
    env: {FACTORY_DIR: fs.cwd()?.display(), XSH_MODULE_PATH: fs.cwd()?.display()},
  ))?
  return status.ok
}

proc test_untried_approved_eval_selection(ctx: TestContext) [fs, error] {
  let root = test.temp_dir(ctx, name: "untried-eval-selection")?
  fs.mkdir(fp"${root}/evals/task-a")?
  fs.mkdir(fp"${root}/evals/task-b")?
  fs.mkdir(fp"${root}/evals/task-c")?
  fs.write(fp"${root}/evals/task-a/EVAL.md", "# Eval task-a\n\n## Status\n\nApproved.\n")?
  fs.write(fp"${root}/evals/task-b/EVAL.md", "# Eval task-b\n\n## Status\n\nApproved.\n")?
  fs.write(fp"${root}/evals/task-c/EVAL.md", "# Eval task-c\n\n## Status\n\nDraft.\n")?
  fs.mkdir(fp"${root}/runs/run-1/workers/eval-worker/task-b-1")?
  json.write(fp"${root}/runs/run-1/workers/eval-worker/task-b-1/report.json", {
    schema_version: 1,
    kind: "worker",
    identity: {role: "eval-worker", worker_id: "task-b-1", eval_id: "task-b", run_id: "run-1"},
    state: "completed", result: "pass", findings: [], artifacts: [],
  }, pretty: true)?
  test.eq(runtime.untried_approved_evals(root)?, ["task-a"]) ?
  test.eq(runtime.next_untried_approved_eval(root)?, "task-a")?
}

proc test_eval_trends_aggregates_historical_worker_reports(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "eval-trends")?
  let factory = fs.cwd()?
  let report_dir = fp"${root}/runs/run-1/workers/eval-worker/task-bigfiles-1"
  fs.mkdir(report_dir)?
  json.write(fp"${report_dir}/report.json", {
    schema_version: 1,
    kind: "worker",
    identity: {role: "eval-worker", worker_id: "task-bigfiles-1", eval_id: "task-bigfiles"},
    state: "completed",
    result: "pass",
    usage: {assistant_turns: 10, total_bucket_tokens: 100.0, tool_errors: 1, cost_usd: 0.01},
    timing: {session_span_ms: 1000},
    provider_telemetry: {retry_count: 0, provider_errors: []},
    execution: {classification: "pass"},
    findings: [],
    artifacts: [],
  }, pretty: true)?
  let xsh = process.which("xsh")?
  let output = fp"${root}/output.txt"
  let status = process.run(process.command_argv(
    xsh, [xsh.display(), fp"${factory}/factory/tools/eval-trends.xsh", "--", "--factory-dir", root.display()],
    cwd: factory, stdout: output, env: {XSH_MODULE_PATH: factory.display(), FACTORY_DIR: factory.display()},
  ))?
  test.ok(status.ok, "eval trend tool should summarize a fixture report")?
  let text = output.read_text()?
  test.contains(text, "task-bigfiles")?
  test.contains(text, "10")?
  test.contains(text, "100")?
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
  test.eq(json.get(report, ["provider_telemetry", "present"], true), false)?
  test.eq(json.get(report, ["result"], "unknown"), "pass")?
  test.ok(! fs.exists(fp"${root}/WORKER-REPORT.md")?)?
  test.ok(! fs.exists(fp"${root}/thinking.md")?)?
}

proc test_session_report_captures_provider_telemetry(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "provider-telemetry")?
  let session = fp"${root}/session.jsonl"
  let events = fp"${session.display()}.events.jsonl"
  let output = fp"${root}/report.json"
  fs.write(session, r"""
{"type":"message","timestamp":"2026-08-01T12:00:00.000Z","message":{"role":"assistant","provider":"fixture","model":"fixture","content":[],"usage":{"output":20,"cost":{"total":0.001}}}}
""")?
  fs.write(events, r"""
{"type":"turn_start","timestamp":1000}
{"type":"auto_retry_start","attempt":1,"delayMs":2000,"errorMessage":"503 overloaded"}
{"type":"auto_retry_end","success":true,"attempt":1}
{"type":"turn_end","message":{"role":"assistant","timestamp":3000,"usage":{"output":20}}}
""")?
  test.ok(run_session_report(root, session, output)?, "telemetry fixture should normalize")?
  let report = json.read(output)?
  test.eq(json.get(report, ["provider_telemetry", "present"], false), true)?
  test.eq(json.get(report, ["provider_telemetry", "retry_count"], 0), 1)?
  test.eq(json.get(report, ["provider_telemetry", "retry_delay_ms"], 0), 2000)?
  test.eq(json.get(report, ["provider_telemetry", "retry_successes"], 0), 1)?
  test.eq(json.get(report, ["provider_telemetry", "event_turns"], 0), 1)?
  test.eq(schema.value_text(json.get(report, ["provider_telemetry", "output_tokens_per_second"], null)), "10")?
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
  test.eq(json.get(report, ["provider_telemetry", "present"], true), false)?
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
    xsh, [xsh.display(), fp"${factory}/factory/tools/audit.xsh", "--", root.display(), "eval"],
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

proc test_audit_preserves_controller_required_output_failure(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "audit-required-output-gate")?
  let factory = fs.cwd()?
  write_eval_phase_fixture(root, factory)?
  json.write(fp"${root}/required-outputs.json", {required: false, manager_report: false}, pretty: true)?
  let xsh = process.which("xsh")?
  let status = process.run(process.command_argv(
    xsh, [xsh.display(), fp"${factory}/factory/tools/audit.xsh", "--", root.display(), "eval"],
    cwd: factory, env: {FACTORY_DIR: factory.display(), XSH_MODULE_PATH: factory.display(), FACTORY_XSH_COMMIT: "fixture"},
  ))?
  test.ok(status.ok, "audit compiler should write a report even when the gate fails")?
  let report = json.read(fp"${root}/report.json")?
  test.eq(json.get(report, ["result"], ""), "fail")?
  test.eq(json.get(report, ["data", "required_outputs", "required"], true), false)?
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
    xsh, [xsh.display(), fp"${factory}/factory/tools/audit.xsh", "--", root.display(), "organization"],
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

proc test_reconciliation_ignores_retired_branch_reference(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "retired-branch-reconciliation")?
  let factory = fs.cwd()?
  let product = fp"${root}/product"
  fs.mkdir(fp"${root}/tickets")?
  fs.mkdir(fp"${root}/tickets")?
  fs.mkdir(fp"${root}/templates")?
  fs.copy(fp"${factory}/templates/TICKET.md", fp"${root}/templates/TICKET.md", overwrite: true)?
  fs.mkdir(product)?
  let git = process.which("git")?
  test.ok(command_ok(git, ["git", "-C", product.display(), "init", "-q", "-b", "main"])?)?
  test.ok(command_ok(git, ["git", "-C", product.display(), "config", "user.email", "factory@test"])?)?
  test.ok(command_ok(git, ["git", "-C", product.display(), "config", "user.name", "Factory Test"])?)?
  fs.write(fp"${product}/README", "base\n")?
  test.ok(command_ok(git, ["git", "-C", product.display(), "add", "README"])?)?
  test.ok(command_ok(git, ["git", "-C", product.display(), "commit", "-qm", "base"])?)?
  fs.copy(fp"${factory}/templates/TICKET.md", fp"${root}/tickets/task-a.md", overwrite: true)?
  let ticket = fs.read_text(fp"${root}/tickets/task-a.md")?.replace("- Eval:", "- Eval: task-envcfg")
  fs.write(fp"${root}/tickets/task-a.md", ticket)?
  let helper = fp"${root}/helper.xsh"
  fs.write(helper, "use factory.runtime as runtime\nproc main() [fs, process, env, error, io] { let repo = env.path(\"FACTORY_XSH_REPO\")?; let _ = runtime.reconcile_tickets(fs.cwd()?, repo, run.text \"git\" \"-C\" $repo.display() \"rev-parse\" \"HEAD\" ?)? }\n")?
  let status = process.run(process.command_argv(process.which("xsh")?, ["xsh", helper.display()], cwd: root, env: {FACTORY_XSH_REPO: product.display(), XSH_MODULE_PATH: factory.display()}))?
  test.ok(status.ok, "reconciliation must ignore missing historical branches")?
}

proc test_stale_branch_inventory_is_documented() [fs, error] {
  let runtime = fs.read_text(fp"${fs.cwd()?}/factory/runtime.xsh")?
  let cto = fs.read_text(fp"${fs.cwd()?}/factory/tools/cto.xsh")?
  test.contains(runtime, "stale_ticket_branches")?
  test.contains(cto, "Stale branch candidates")?
  test.contains(cto, "retire_stale_ticket_branches")?
  test.contains(runtime, "retire_stale_ticket_branches")?
}

proc test_eval_cap_is_admission_policy() [fs, error] {
  let launcher = fs.read_text(fp"${fs.cwd()?}/run.xsh")?
  test.contains(launcher, "max_eval_contracts()")?
  test.contains(launcher, "eval contract cap exceeded")?
}

proc test_cto_report_pins_factory_root() [fs, error] {
  let runtime = fs.read_text(fp"${fs.cwd()?}/factory/runtime.xsh")?
  test.contains(runtime, "env: {FACTORY_DIR: factory_dir.display(), XSH_MODULE_PATH: factory_dir.display()}")?
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
    xsh, [xsh.display(), fp"${factory}/factory/tools/cto-report.xsh", "--", "--run-dir", root.display(), "--output", output.display(), "--result", "pass"],
    cwd: factory, env: {FACTORY_DIR: factory.display(), XSH_MODULE_PATH: factory.display()},
  ))?
  test.ok(status.ok, "CTO compiler should consume structured reports")?
  let text = fs.read_text(output)?
  test.contains(text, "Structured run or phase report")?
  test.contains(text, "## Outcome dimensions")?
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
    xsh, [xsh.display(), fp"${fs.cwd()?}/factory/tools/cycle-budget-watch.xsh", "--",
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

proc test_structured_provenance_event_exists() [fs, error] {
  let runtime = fs.read_text(fp"${fs.cwd()?}/factory/runtime.xsh")?
  let ticket = fs.read_text(fp"${fs.cwd()?}/factory/controllers/ticket.xsh")?
  test.contains(runtime, "emit_structured_event")?
  test.contains(ticket, "amended_commit")?
}

proc test_engineer_provenance_amend(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "engineer-provenance")?
  let factory = fp"${root}/factory"
  let product = fp"${root}/product"
  let run_dir = fp"${factory}/runs/run-1"
  let worker_dir = fp"${run_dir}/workers/engineer/task-a"
  let assignment_file = fp"${run_dir}/messages/task-a.md"
  let patches = fp"${run_dir}/patches"
  let worktree = fp"${root}/worktree"
  fs.mkdir(fp"${worker_dir}")?
  fs.mkdir(assignment_file.parent())?
  fs.mkdir(patches)?
  fs.mkdir(product)?
  fs.mkdir(worktree.parent())?
  let git = process.which("git")?
  test.ok(command_ok(git, ["git", "-C", product.display(), "init", "-q", "-b", "main"])?)?
  test.ok(command_ok(git, ["git", "-C", product.display(), "config", "user.email", "factory@test"])?)?
  test.ok(command_ok(git, ["git", "-C", product.display(), "config", "user.name", "Factory Test"])?)?
  fs.write(fp"${product}/README", "base\n")?
  test.ok(command_ok(git, ["git", "-C", product.display(), "add", "README"])?)?
  test.ok(command_ok(git, ["git", "-C", product.display(), "commit", "-qm", "base"])?)?
  let base = run.text "git" "-C" $product.display() "rev-parse" "HEAD" ?
  test.ok(command_ok(git, ["git", "-C", product.display(), "worktree", "add", "-q", "-b", "factory/task-a/run-1", worktree.display(), base.trim()])?)?
  fs.write(fp"${worktree}/README", "base\nchanged\n")?
  test.ok(command_ok(git, ["git", "-C", worktree.display(), "add", "README"])?)?
  test.ok(command_ok(git, ["git", "-C", worktree.display(), "commit", "-qm", "change"])?)?
  let head = run.text "git" "-C" $worktree.display() "rev-parse" "HEAD" ?
  fs.write(assignment_file, "controller assignment\n")?
  let assignment_sha = hash.sha256(assignment_file)?.hex()
  let report = fp"${worker_dir}/report.json"
  let session = fp"${worker_dir}/session.jsonl"
  let missing = runtime.amend_engineer_commit(worktree, head.trim(), factory, run_dir,
    report, session, "task-a", "factory/task-a/run-1", base.trim(), assignment_sha, "missing")?
  test.eq(missing, "")?
  let missing_session = fp"${worker_dir}/missing-session.jsonl"
  let missing_evidence = runtime.amend_engineer_commit(worktree, head.trim(), factory, run_dir,
    report, missing_session, "task-a", "factory/task-a/run-1", base.trim(), assignment_sha, "missing")?
  test.eq(missing_evidence, "")?
  fs.write(fp"${worker_dir}/session.jsonl", "session evidence\n")?
  fs.write(report, json.encode({
    models: ["openrouter/openai/gpt-5.6-luna"],
    usage: {assistant_turns: 81, tool_calls: 152, tool_errors: 11, thinking_blocks: 27,
      reasoning_tokens: 13963, total_bucket_tokens: 7348813, input_tokens: 243,
      output_tokens: 27898, cache_read_tokens: 7198079, cache_write_tokens: 122593,
      cost_usd: 0.104068015},
    timing: {session_span_ms: 695496}
  })? + "\n")?
  let patch_path = fp"${patches}/task-a.diff"
  test.ok(runtime.write_engineer_patch(worktree, base.trim(), head.trim(), patch_path, fp"${patches}/task-a.stderr")?)?
  let patch_sha = hash.sha256(patch_path)?.hex()
  let amended = runtime.amend_engineer_commit(worktree, head.trim(), factory, run_dir,
    report, session, "task-a", "factory/task-a/run-1", base.trim(), assignment_sha, patch_sha)?
  test.ok(amended != head.trim())?
  let message = run.text "git" "-C" $worktree.display() "log" "-1" "--format=%B" ?
  test.contains(message, "Factory-Provenance-Version: 1")?
  test.contains(message, "Factory-Model: openai/gpt-5.6-luna")?
  test.contains(message, "Factory-Report-SHA256:")?
  test.contains(message, f"Factory-Assignment-SHA256: ${assignment_sha}")?
  test.contains(message, "Factory-Session-SHA256:")?
  test.contains(message, f"Factory-Patch-SHA256: ${patch_sha}")?
  test.contains(message, f"Factory-Patch-SHA256: ${patch_sha}")?
  test.contains(message, "Factory-Provenance-Version: 1")?
  test.contains(message, "Factory-Cost-USD: 0.104068015")?
  test.ok(command_ok(git, ["git", "-C", worktree.display(), "status", "--porcelain"])?)?
  fs.write(fp"${worktree}/DIRTY", "must block amendment\n")?
  let dirty = runtime.amend_engineer_commit(worktree, amended, factory, run_dir,
    report, session, "task-a", "factory/task-a/run-1", base.trim(), assignment_sha, patch_sha)?
  test.eq(dirty, "")?
  fs.remove(fp"${worktree}/DIRTY")?
  let second = runtime.amend_engineer_commit(worktree, amended, factory, run_dir,
    report, session, "task-a", "factory/task-a/run-1", base.trim(), assignment_sha, patch_sha)?
  test.eq(second, amended)?
  test.ok(runtime.remove_clean_worktree(product, worktree)?)?
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
  test.ok(runtime.write_engineer_patch(worktree, base.trim(), head.trim(), diff_path, fp"${patches}/task.stderr")?)?
  test.contains(fs.read_text(diff_path)?, "+changed")?
  test.ok(runtime.remove_clean_worktree(product, worktree)?)?
  test.ok(! fs.exists(worktree)?)?
  test.contains(run.text "git" "-C" $product.display() "branch" "--list" "factory/test" ?, "factory/test")?
}

proc test_run_worktree_cleanup_removes_dirty_worktrees_preserves_branch(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "run-worktree-cleanup")?
  let product = fp"${root}/product"
  let run_dir = fp"${root}/runs/run-1"
  let worktree = fp"${run_dir}/phases/01-ticket/worktrees/task-a"
  fs.mkdir(worktree.parent())?
  fs.mkdir(product)?
  let git = process.which("git")?
  test.ok(command_ok(git, ["git", "-C", product.display(), "init", "-q", "-b", "main"])?)?
  test.ok(command_ok(git, ["git", "-C", product.display(), "config", "user.email", "factory@test"])?)?
  test.ok(command_ok(git, ["git", "-C", product.display(), "config", "user.name", "Factory Test"])?)?
  fs.write(fp"${product}/README", "base\n")?
  test.ok(command_ok(git, ["git", "-C", product.display(), "add", "README"])?)?
  test.ok(command_ok(git, ["git", "-C", product.display(), "commit", "-qm", "base"])?)?
  let base = run.text "git" "-C" $product.display() "rev-parse" "HEAD" ?
  test.ok(command_ok(git, ["git", "-C", product.display(), "worktree", "add", "-q", "-b", "factory/task-a/run-1", worktree.display(), base.trim()])?)?
  fs.write(fp"${worktree}/DIRTY", "preserve branch evidence\n")?
  test.ok(runtime.remove_run_worktrees(product, run_dir)?)?
  test.ok(! fs.exists(worktree)?)?
  test.contains(run.text "git" "-C" $product.display() "branch" "--list" "factory/task-a/run-1" ?, "factory/task-a/run-1")?
}

proc test_organization_reuses_existing_branch_without_duplicate_dispatch() [fs, error] {
  let organization = fs.read_text(fp"${fs.cwd()?}/factory/controllers/organization.xsh")?
  let reuse = fs.read_text(fp"${fs.cwd()?}/factory/controllers/reuse.xsh")?
  let launcher = fs.read_text(fp"${fs.cwd()?}/run.xsh")?
  test.contains(organization, "run_reuse_phase")?
  # Reuse mode must not gate the linked replay on a non-existent engineer
  # worker report; it uses the reuse phase report as the precondition.
  test.contains(organization, "if reuse_existing_branch {")?
  test.contains(organization, "phase_run_pass(primary_phase, \"report.json\")")?
  test.contains(reuse, "mode: \"ticket-reuse\"")?
  test.contains(reuse, "worktree", "existing branch must use a detached worktree")?
  test.contains(launcher, "open_branch != \"\" and mode != \"organization\"")?
}

proc test_ticket_cycle_bounds_concurrent_engineers() [fs, error] {
  let ticket = fs.read_text(fp"${fs.cwd()?}/factory/controllers/ticket.xsh")?
  let director = fs.read_text(fp"${fs.cwd()?}/roles/director.md")?
  let organization = fs.read_text(fp"${fs.cwd()?}/factory/controllers/organization.xsh")?
  test.contains(ticket, "max_concurrent_engineers()")?
  test.contains(ticket, r"""at most ${control.max_concurrent_engineers()} engineer tickets""")?
  test.contains(ticket, "remove_run_worktrees")?
  test.contains(ticket, "if ! director_status.ok")?
  test.contains(ticket, "runtime.cleanup_active_run()")?
  test.contains(ticket, "spawn_engineer")?
  test.contains(ticket, "engineer_handles")?
  test.contains(ticket, "controller-dispatching engineer worker")?
  test.contains(director, "launch each assigned row exactly once")?
  test.contains(organization, "ticket_worker_pass(primary_phase, ticket_id)")?
  test.contains(organization, "remove_run_worktrees")?
  test.contains(organization, "let reeval_ok = ticket_primary_pass and run_child")?
}

proc test_eval_mode_has_no_paid_director_review() [fs, error] {
  let evaluator = fs.read_text(fp"${fs.cwd()?}/factory/controllers/eval.xsh")?
  let auditor = fs.read_text(fp"${fs.cwd()?}/factory/tools/audit.xsh")?
  test.ok(! evaluator.contains("20-director-started"))?
  test.ok(! evaluator.contains("director_handle"))?
  test.contains(auditor, "result: \"not-requested\"")?
  test.contains(auditor, "if mode == \"ticket-implementation\"")?
}

proc test_eval_gate_diagnostics_are_persisted() [fs, error] {
  let evaluator = fs.read_text(fp"${fs.cwd()?}/factory/controllers/eval.xsh")?
  test.contains(evaluator, "required-outputs.json")?
  test.contains(evaluator, "write_preflight_failure_report")?
  test.contains(evaluator, "preflight-failure")?
  test.contains(evaluator, "manager_evidence_read")?
  test.contains(evaluator, "designer_handbook_read")?
  test.contains(evaluator, "_post_required_outputs_audit")?
}

proc test_task_bigfiles_evaluator_is_package_owned() [fs, error] {
  let evaluator = fs.read_text(fp"${fs.cwd()?}/evals/task-bigfiles/evaluator.xsh")?
  test.ok(control.eval_evaluator_package_owned(evaluator))?
  test.contains(evaluator, "run.json")?
  test.contains(evaluator, "task-bigfiles")?
  test.contains(evaluator, "sort -k1,1rn")?
}
proc test_eval_dispatch_is_package_owned() [fs, error] {
  let evaluate = fs.read_text(fp"${fs.cwd()?}/evals/task-bigfiles/evaluate.xsh")?
  let executor = fs.read_text(fp"${fs.cwd()?}/factory/entrypoints/eval-executor.xsh")?
  test.contains(evaluate, "/run/evaluator.xsh")?
  test.ok(! evaluate.contains("factory/tools"))?
  test.contains(executor, "evaluator.xsh")?
  test.contains(executor, "use factory.control as control")?
  let ticket_controller = fs.read_text(fp"${fs.cwd()?}/factory/controllers/ticket.xsh")?
  test.contains(ticket_controller, "CTO owns factory changes")?
  test.contains(ticket_controller, "ticket_change_target")?
  test.contains(executor, "identity", "eval_id")?
  test.contains(executor, "identity", "run_id")?
  for eval_id in ["task-ecount", "task-envcfg"] {
    test.ok(fs.exists(fp"${fs.cwd()?}/evals/${eval_id}/evaluator.xsh")?)?
  }
}

proc test_eval_design_rejects_legacy_evaluator_source() [fs, error] {
  let controller = fs.read_text(fp"${fs.cwd()?}/factory/controllers/design.xsh")?
  test.contains(controller, "eval_evaluator_package_owned")?
  test.contains(controller, "evaluator_source_ok")?
}

proc test_eval_design_stages_and_promotes_complete_package() [fs, error] {
  let controller = fs.read_text(fp"${fs.cwd()?}/factory/controllers/design.xsh")?
  let assignment = fs.read_text(fp"${fs.cwd()?}/templates/EVAL-DESIGNER-ASSIGNMENT.md")?
  let role = fs.read_text(fp"${fs.cwd()?}/roles/eval-designer.md")?
  let review = fs.read_text(fp"${fs.cwd()?}/templates/CTO-EVAL-REVIEW.md")?
  test.contains(controller, "\"evaluator.xsh\"")?
  test.contains(controller, "promote_eval_proposal")?
  test.contains(controller, "84-cto-reviewed")?
  test.contains(controller, "evaluator_check_ok")?
  test.contains(assignment, "new valid `task-*` ID")?
  test.contains(assignment, "approved eval's `EVAL.md`")?
  test.contains(assignment, "State machine")?
  test.contains(assignment, "Write the report")?
  test.contains(assignment, "Do not build a localized evaluator")?
  test.contains(role, "Replace the scaffold's source eval title and ID first")?
  test.contains(role, "Use an approved eval package")?
  test.contains(role, "State machine")?
  test.contains(role, "When the evaluator is valid, stop discovery")?
  test.contains(role, "Do not build a localized evaluator")?
  test.contains(review, "may set `Approved.`")?
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
  test.contains(fs.read_text(handoff)?, "## Revert condition")?
  runtime.stage_cto_productivity_report(factory, root)?
  let productivity = fp"${root}/CTO-PRODUCTIVITY-REPORT.md"
  test.ok(fs.exists(productivity)?)?
  test.contains(fs.read_text(productivity)?, "## Engineer-commit gate")?
}

proc test_eval_executor_is_documented_as_controller_not_role() [fs, error] {
  let contract = fs.read_text(fp"${fs.cwd()?}/FACTORY.md")?
  let guide = fs.read_text(fp"${fs.cwd()?}/AGENTS.md")?
  test.contains(contract, "controller program, not a Pi role")?
  test.contains(contract, "it is not an")?
  test.contains(guide, "controller-owned infrastructure, not a role or employee")?
}

proc test_controllers_have_no_legacy_projection_outputs() [fs, error] {
  for file in ["run.xsh", "factory/controllers/eval.xsh", "factory/controllers/ticket.xsh", "factory/controllers/design.xsh", "factory/controllers/organization.xsh", "factory/tools/audit.xsh", "factory/tools/session.xsh"] {
    let source = fs.read_text(fp"${fs.cwd()?}/${file}")?
    test.ok(! source.contains("COST.md"), f"${file} must use report.json")?
    test.ok(! source.contains("AUDIT.md"), f"${file} must use report.json")?
    test.ok(! source.contains("TOOL-ERRORS.md"), f"${file} must use structured tool_errors")?
    test.ok(! source.contains("CURRENT-EVIDENCE.md"), f"${file} must not emit evidence projection")?
  }
}

proc test_canonical_surface_has_no_compatibility_layer() [fs, error] {
  let root = fs.cwd()?
  let launcher = fs.read_text(fp"${root}/run.xsh")?
  test.ok(! launcher.contains("compat"), "the only top-level launcher must be canonical")?
  test.contains(launcher, "use factory.control as control")?
  for file in [
    "factory/controllers/organization.xsh", "factory/controllers/ticket.xsh",
    "factory/controllers/eval.xsh", "factory/controllers/design.xsh",
    "factory/controllers/reuse.xsh", "factory/entrypoints/run-agent.xsh",
    "factory/entrypoints/eval-executor.xsh", "factory/tools/audit.xsh",
    "factory/tools/report.xsh", "factory/tools/session.xsh",
  ] {
    let source = fs.read_text(fp"${root}/${file}")?
    test.ok(! source.contains("compat"), f"${file} must not use compatibility code")?
  }
}

proc test_clean_factory_supports_age_pruning() [fs, error] {
  let clean = fs.read_text(fp"${fs.cwd()?}/factory/tools/clean-factory.xsh")?
  test.contains(clean, "cutoff_ms")?
  test.contains(clean, r"removed ${removed} run(s) older than")?
  test.contains(clean, "age_days < 1")?
  test.contains(fs.read_text(fp"${fs.cwd()?}/Makefile")?, "clean-factory.xsh 3")?
}

proc test_compressed_session_support_round_trips(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "compressed-session")?
  let session = fp"${root}/session.jsonl"
  let events = fp"${session.display()}.events.jsonl"
  fs.write(session, "{\"type\":\"message\"}\n")?
  fs.write(events, "{\"type\":\"message_update\"}\n")?
  runtime.compress_run_sessions(root)?
  test.ok(! fs.exists(events)?, "streaming provider events must not be retained")?
  test.ok(! fs.exists(session)?, "raw session must be compressed")?
  test.contains(runtime.session_text(session)?, "message")?
}

proc test_compressed_session_support_is_documented() [fs, error] {
  let runtime = fs.read_text(fp"${fs.cwd()?}/factory/runtime.xsh")?
  let report = fs.read_text(fp"${fs.cwd()?}/factory/tools/session.xsh")?
  let budget = fs.read_text(fp"${fs.cwd()?}/factory/tools/budget-watch.xsh")?
  let cleanup = fs.read_text(fp"${fs.cwd()?}/factory/tools/cleanup-run.xsh")?
  test.contains(runtime, "session.jsonl.bz2")?
  test.contains(runtime, "compress_run_sessions")?
  test.contains(report, "runtime.session_text")?
  test.contains(budget, "runtime.session_text")?
  test.contains(cleanup, ".events.jsonl")?
  test.contains(fs.read_text(fp"${fs.cwd()?}/runs/.gitignore")?, "session.jsonl.events.jsonl.bz2")?
}

proc test_pi_session_persistence_is_jsonl_only() [fs, error] {
  let controller = fs.read_text(fp"${fs.cwd()?}/factory/entrypoints/run-agent.xsh")?
  let eval_worker = fs.read_text(fp"${fs.cwd()?}/evals/eval-worker.xsh")?
  test.contains(controller, "--session")?
  test.contains(controller, "--mode", "json")?
  test.contains(controller, ".events.jsonl")?
  test.contains(controller, "fs.remove(provider_events")?
  test.contains(eval_worker, "--session")?
  test.contains(eval_worker, "--mode", "json")?
  test.contains(eval_worker, ".events.jsonl")?
  let executor = fs.read_text(fp"${fs.cwd()?}/factory/entrypoints/eval-executor.xsh")?
  test.contains(executor, "fs.remove")?
  test.ok(! controller.contains("--export"), "run-agent must not create session.html")?
  test.ok(! eval_worker.contains("--export"), "eval worker must not create session.html")?
}

proc test_run_agent_clears_pi_harness_env() [fs, error] {
  # The factory may be launched from inside a standalone-embedded Pi session
  # whose PI_PACKAGE_DIR/PI_STANDALONE_BINARY leak (XSH merges spawn `env`)
  # into every host-side agent launch. The host runner must clear them so host
  # `pi` resolves its own installed package instead of a partial embedded one
  # lacking dist/modes/interactive/theme/dark.json, which crashed agent startup.
  let controller = fs.read_text(fp"${fs.cwd()?}/factory/entrypoints/run-agent.xsh")?
  test.contains(controller, "PI_PACKAGE_DIR: \"\"")?
  test.contains(controller, "PI_STANDALONE_BINARY: \"\"")?
  let worker = fs.read_text(fp"${fs.cwd()?}/evals/eval-worker.xsh")?
  test.ok(! worker.contains("PI_STANDALONE_BINARY"), "Docker worker stays harness-free")?
}

proc test_eval_worker_prompt_matches_task_image() [fs, error] {
  let prompt = fs.read_text(fp"${fs.cwd()?}/roles/eval-worker.md")?
  test.contains(prompt, "The task image is Alpine-based and provides BusyBox `sh`, not `bash`; use `sh`")?
  test.contains(prompt, "avoid bash-only syntax")?
  test.contains(prompt, "`and` and `or`, not shell `&&` and `||`")?
}

proc test_host_agent_dispatch_requires_controller_manifest(ctx: TestContext) [fs, error] {
  let root = test.temp_dir(ctx, name: "host-agent-dispatch")?
  let message = fp"${root}/message.md"
  fs.write(message, "controller assignment\n")?
  runtime.write_dispatch_record(
    root, "eval-manager", "task-a", message, root, "eval", "task-a", "", ""
  )?
  let dispatch = json.read(fp"${root}/dispatch/eval-manager-task-a.json")?
  test.eq(schema.value_text(json.get(dispatch, ["role"], "")), "eval-manager")?
  test.eq(schema.value_text(json.get(dispatch, ["worker_id"], "")), "task-a")?
  test.eq(schema.value_text(json.get(dispatch, ["message_file"], "")), message.display())?
  test.eq(schema.value_text(json.get(dispatch, ["mode"], "")), "eval")?
  test.eq(schema.value_text(json.get(dispatch, ["eval_id"], "")), "task-a")?
  let runner = fs.read_text(fp"${fs.cwd()?}/factory/entrypoints/run-agent.xsh")?
  test.contains(runner, "missing controller dispatch record")?
  test.contains(runner, "agent invocation does not match controller dispatch record")?
}
