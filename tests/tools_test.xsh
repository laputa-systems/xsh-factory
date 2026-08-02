##! Native tests for factory tools. These fixtures use synthetic sessions and
##! harmless subprocesses; they never launch Pi.

use factory_control as control

proc test_session_report_uses_synthetic_pi_session(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "session-report")?
  let session = fp"${root}/session.jsonl"
  let report = fp"${root}/WORKER-REPORT.md"
  let tool = fp"${fs.cwd()?}/tools/session-report.xsh"
  fs.write(session, r"""
{"timestamp":"2026-08-01T12:00:00.000Z","type":"message","message":{"role":"user","content":"task"}}
{"timestamp":"2026-08-01T12:00:01.000Z","type":"message","message":{"role":"assistant","provider":"openrouter","model":"deepseek/deepseek-v4-flash-0731","stopReason":"toolUse","content":[{"type":"thinking","thinking":"inspect the fixture"},{"type":"toolCall","name":"read"}],"usage":{"input":10,"output":20,"reasoning":7,"totalTokens":30,"cost":{"input":0.001,"output":0.002,"total":0.003}}}}
{"timestamp":"2026-08-01T12:00:02.000Z","type":"message","message":{"role":"toolResult","isError":false,"usage":{"input":2,"output":3,"totalTokens":5,"cost":{"total":0.0005}}}}
""")?
  let xsh = process.which("xsh")?
  let status = process.run(process.command_argv(
    xsh,
    [xsh.display(), tool.display(), "--", "worker", "--session", session.display(),
      "--output", report.display(), "--role", "eval-worker", "--worker-id", "fixture",
      "--budget-usd", "2"],
  ))?
  test.ok(status.ok, "session-report should accept a well-formed synthetic session")?
  let rendered = fs.read_text(report)?
  let thinking = fs.read_text(fp"${root}/thinking.md")?
  test.contains(rendered, "Assistant turns: 1")?
  test.contains(rendered, "Reasoning/thinking tokens (provider subset of output): 7")?
  test.contains(rendered, "Budget: $0.50")?
  test.contains(rendered, "Budget status: pass")?
  test.contains(thinking, "inspect the fixture")?
}

proc test_run_dispatcher_fails_preflight_before_agent_launch(ctx: TestContext) [fs, process, env, error] {
  let root = test.temp_dir(ctx, name: "dispatcher-preflight")?
  let request = fp"${root}/cycle.md"
  fs.write(request, "# Cycle\n\n## Mode\n\n- `organization`\n\n## Active evals\n\n- `task-ecount`\n\n## Trial plan\n\n- Count: `1`\n\n## New eval proposals\n\n- Count: `1`\n")?
  let xsh = process.which("xsh")?
  let factory_dir = fs.cwd()?
  let status = process.run(process.command_argv(
    xsh,
    [xsh.display(), fp"${factory_dir}/run.xsh".display(), "--", request.display()],
    cwd: factory_dir,
    env: {
      PATH: env.get("PATH")?,
      HOME: env.get("HOME")?,
      FACTORY_DIR: root.display(),
      XSH_MODULE_PATH: factory_dir.display(),
    },
  ))?
  test.ok(! status.ok, "dispatcher should stop before workers when XSH repo admission fails")?
  test.ok(! fs.exists(fp"${root}/runs/ORGANIZATION-ACTIVE")?)?
}

proc test_disabled_eval_is_rejected_before_executor_launch(ctx: TestContext) [fs, process, env, error] {
  let root = test.temp_dir(ctx, name: "disabled-eval")?
  let factory = fs.cwd()?
  fs.mkdir(fp"${root}/evals/task-tags")?
  fs.write(fp"${root}/evals/task-tags/EVAL.md", "# Eval task-tags\n\n## Status\n\nDisabled.\n")?
  let request = fp"${root}/cycle.md"
  fs.write(request, "# Cycle\n\n## Mode\n\n- `eval`\n\n## Active evals\n\n- `task-tags`\n")?
  let xsh = process.which("xsh")?
  let status = process.run(process.command_argv(
    xsh,
    [xsh.display(), fp"${factory}/run-eval.xsh".display(), "--", request.display()],
    cwd: root,
    env: {
      PATH: env.get("PATH")?,
      FACTORY_DIR: root.display(),
      XSH_MODULE_PATH: factory.display(),
    },
  ))?
  test.ok(! status.ok, "disabled eval must be rejected before launching a worker")?
  test.ok(! fs.exists(fp"${root}/runs/ACTIVE")?)?
}

proc test_organization_overlaps_design_with_primary_using_fake_children(ctx: TestContext) [fs, process, env, error] {
  let root = test.temp_dir(ctx, name: "organization-schedule")?
  let factory = fs.cwd()?
  fs.mkdir(fp"${root}/evals")?
  fs.mkdir(fp"${root}/runtime")?
  fs.mkdir(fp"${root}/tools")?
  let copied_templates = fs.copy_tree(fp"${factory}/templates", fp"${root}/templates")?
  let copied_eval = fs.copy_tree(fp"${factory}/evals/task-tags", fp"${root}/evals/task-tags")?
  fs.copy(fp"${factory}/NORTH-STAR.md", fp"${root}/NORTH-STAR.md", overwrite: true)?
  fs.copy(fp"${factory}/runtime/handbook.md", fp"${root}/runtime/handbook.md", overwrite: true)?
  fs.copy(fp"${factory}/tools/session-report.xsh", fp"${root}/tools/session-report.xsh", overwrite: true)?

  let fake_child = fp"${root}/fake-child.sh"
  fs.write(fake_child, r"""#!/bin/sh
set -eu
printf 'start:%s\n' "$FACTORY_PHASE_DIR" >> "$FACTORY_TEST_LOG"
sleep 1
printf 'end:%s\n' "$FACTORY_PHASE_DIR" >> "$FACTORY_TEST_LOG"
cp "$FACTORY_TEST_REPORT" "$FACTORY_PHASE_DIR/RUN.md"
cp "$FACTORY_TEST_REPORT" "$FACTORY_PHASE_DIR/RUN-DESIGN.md"
""")?
  let chmod = process.run(process.command_argv("chmod", ["chmod", "+x", fake_child.display()]))?
  test.ok(chmod.ok, "fake organization child should be executable")?
  let request = fp"${root}/cycle.md"
  fs.copy(fp"${factory}/tests/fixtures/organization-no-ticket.md", request, overwrite: true)?
  let log = fp"${root}/schedule.log"
  let report = fp"${factory}/tests/fixtures/organization-pass.md"
  let xsh = process.which("xsh")?
  let product = fp"${factory}/../xsh"
  let status = process.run(process.command_argv(
    xsh,
    [xsh.display(), fp"${factory}/run-organization.xsh".display(), "--", request.display()],
    cwd: root,
    env: {
      PATH: env.get("PATH")?,
      HOME: env.get("HOME")?,
      FACTORY_DIR: root.display(),
      XSH_MODULE_PATH: factory.display(),
      FACTORY_XSH_REPO: product.display(),
      FACTORY_CHILD_RUNNER: "/bin/sh",
      FACTORY_PRIMARY_CONTROLLER: fake_child.display(),
      FACTORY_DESIGN_CONTROLLER: fake_child.display(),
      FACTORY_TEST_LOG: log.display(),
      FACTORY_TEST_REPORT: report.display(),
    },
  ))?
  test.ok(status.ok, "fake organization cycle should complete")?
  let schedule = fs.read_text(log)?
  let first_start = schedule.find("start:")
  let second_start = schedule.find("start:", first_start + 1)
  let first_end = schedule.find("end:")
  test.ok(first_start >= 0 and second_start > first_start, "both phases should start")?
  test.ok(first_end > second_start, "design and primary must overlap")?
}

proc test_audit_run_preserves_separate_evaluator_outcomes(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "audit-run")?
  let run_dir = fp"${root}/run-1"
  let director_dir = fp"${run_dir}/workers/director/director"
  let manager_dir = fp"${run_dir}/workers/eval-manager/task-tags"
  let worker_dir = fp"${run_dir}/workers/eval-worker/task-tags-1"
  fs.mkdir(director_dir)?
  fs.mkdir(manager_dir)?
  fs.mkdir(worker_dir)?
  fs.write(fp"${run_dir}/CYCLE-REQUEST.md", "# Cycle\n\n## Active evals\n\n- `task-tags`\n\n## Trial plan\n\n- Count: `1`\n\n## New eval proposals\n\n- Count: `0`\n")?

  let provenance_template = fs.read_text(fp"${fs.cwd()?}/templates/PROVENANCE.md")?
  fs.write(fp"${run_dir}/PROVENANCE.md", control.fill_template(provenance_template, [
    {key: "RUN_ID", value: run_dir.display()},
    {key: "MODE", value: "eval"},
    {key: "REQUEST", value: "CYCLE-REQUEST.md"},
    {key: "BUILD_ID", value: "fixture-build"},
    {key: "XSH_COMMIT", value: "fixture-xsh"},
    {key: "CANDIDATE_TICKET", value: "not-reevaluation"},
    {key: "CANDIDATE_WORKTREE", value: "not-reevaluation"},
    {key: "IMAGE", value: "fixture-image"},
    {key: "IMAGE_ID", value: "fixture-image-id"},
    {key: "PLATFORM", value: "fixture-platform"},
    {key: "APPROVED_HANDBOOK_SHA", value: "approved"},
    {key: "CANDIDATE_HANDBOOK_SHA", value: "candidate"},
    {key: "TICKET_SNAPSHOT_SHA", value: "not-ticket-cycle"},
  ]))?
  let lineage_template = fs.read_text(fp"${fs.cwd()?}/templates/LINEAGE.md")?
  fs.write(fp"${run_dir}/LINEAGE.md", control.fill_template(lineage_template, [
    {key: "BASELINE_SHA", value: "approved"},
    {key: "CANDIDATE_SHA", value: "candidate"},
    {key: "TRIAL1_SHA", value: "approved"},
    {key: "TRIAL2_SHA", value: "not-requested"},
    {key: "APPROVED_SNAPSHOT_UNCHANGED", value: "true"},
    {key: "CHECKED_IN_HANDBOOK_UNCHANGED", value: "true"},
    {key: "LINEAGE_STATE", value: "pass"},
  ]))?
  fs.write(fp"${run_dir}/COST.md", "# Run cost report\n\n## Workers\n\n## Role totals\n\n## Run total\n\n- Budget failures or unknown costs: 0\n")?
  fs.write(fp"${run_dir}/DIRECTOR-REPORT.md", "# Director report\n\n## Result\n\npass\n\n## Cycle\n\nfixture\n\n## Children\n\nfixture\n\n## Required-output status\n\npass\n\n## North-star impact\n\nfixture\n")?
  fs.write(fp"${run_dir}/workers/eval-manager/task-tags/MANAGER-REPORT.md", "# Manager report\n\n## Result\n\npass\n\n## Effort metrics\n\nfixture\n\n## Usage and cost\n\nfixture\n\n## Thinking evidence\n\nfixture\n\n## Timing evidence\n\nfixture\n\n## Observation classification\n\nfixture\n\n## Handbook decision\n\nfixture\n\n## Tickets created\n\nfixture\n\n## Post-merge decisions\n\nfixture\n\n## Next replay\n\nfixture\n\n## North-star impact\n\nfixture\n")?

  let session_text = r"""
{"timestamp":"2026-08-01T12:00:00.000Z","type":"message","message":{"role":"user","content":"fixture"}}
{"timestamp":"2026-08-01T12:00:01.000Z","type":"message","message":{"role":"assistant","provider":"openrouter","model":"deepseek/deepseek-v4-flash-0731","stopReason":"stop","content":[{"type":"thinking","thinking":"fixture"}],"usage":{"input":1,"output":2,"reasoning":1,"totalTokens":3,"cost":{"total":0.001}}}}
"""
  for target in [director_dir, manager_dir, worker_dir] {
    fs.write(fp"${target}/session.jsonl", session_text)?
  }
  let xsh = process.which("xsh")?
  for entry in [
    {path: director_dir, role: "director", worker: "director"},
    {path: manager_dir, role: "eval-manager", worker: "task-tags"},
    {path: worker_dir, role: "eval-worker", worker: "task-tags-1"},
  ] {
    let report_status = process.run(process.command_argv(
      xsh,
      [xsh.display(), fp"${fs.cwd()?}/tools/session-report.xsh", "--", "worker",
        "--session", fp"${entry.path}/session.jsonl".display(),
        "--output", fp"${entry.path}/WORKER-REPORT.md".display(),
        "--role", entry.role, "--worker-id", entry.worker,
        "--budget-usd", if entry.role == "director" { "0.06" } else if entry.role == "eval-manager" { "0.15" } else { "0.50" }],
    ))?
    test.ok(report_status.ok, "synthetic worker report should render")?
  }
  fs.write(fp"${worker_dir}/EXECUTOR-REPORT.md", "# Executor report\n\n## Result\n\npass\n\n## Failure classification\n\npass\n\n## Trial\n\n1\n\n## Artifact\n\npresent\n\n## Evidence\n\nfixture\n")?
  fs.write(fp"${worker_dir}/run.json", r"""
{
  "eval_id": "task-tags",
  "trial_id": "1",
  "result": "pass",
  "classification": "pass",
  "inputs": {"handbook_sha256": "approved"},
  "outputs": {"candidate_sha256": "candidate-output", "oracle_sha256": "oracle-output"},
  "protocol": {"artifact_present": true, "review_ok": true},
  "correctness": {"all_exact": true},
  "restrictions": {"passed": true},
  "timings": {"candidate_wall_ns": 100, "oracle_wall_ns": 100, "ratio": 1.0}
}
""")?

  let audit_tool = fp"${fs.cwd()?}/audit-run.xsh"
  let first = process.run(process.command_argv(
    xsh, [xsh.display(), audit_tool.display(), "--", run_dir.display(), "eval"],
  ))?
  test.ok(first.ok, "audit generation should succeed for valid evidence")?
  let audit = fs.read_text(fp"${run_dir}/AUDIT.md")?
  test.ok(control.audit_report_contract_ok(audit))?
  test.eq(control.audit_result(audit), "pass")?
  test.contains(audit, "protocol=pass; correctness=true; restrictions=true")?
  test.contains(audit, "timing=ratio=1.000; gate=unknown")?

  fs.write(fp"${worker_dir}/run.json", r"""
{
  "eval_id": "task-tags",
  "trial_id": "1",
  "result": "fail",
  "classification": "protocol_failed",
  "inputs": {"handbook_sha256": "approved"},
  "outputs": {"candidate_sha256": "candidate-output", "oracle_sha256": "oracle-output"},
  "protocol": {"artifact_present": true, "review_ok": false},
  "correctness": {"all_exact": true},
  "restrictions": {"passed": true},
  "timings": {"candidate_wall_ns": 100, "oracle_wall_ns": 100}
}
""")?
  let second = process.run(process.command_argv(
    xsh, [xsh.display(), audit_tool.display(), "--", run_dir.display(), "eval"],
  ))?
  test.ok(second.ok, "audit generation should preserve failed evidence")?
  let failed_audit = fs.read_text(fp"${run_dir}/AUDIT.md")?
  test.eq(control.audit_result(failed_audit), "fail")?
  test.contains(failed_audit, "protocol=fail; correctness=true; restrictions=true")?
  test.contains(failed_audit, "classification=protocol_failed")?
}

proc test_budget_watch_terminates_a_harmless_fake_worker(ctx: TestContext) [fs, process, error] {
  # The sleep process is the test double for Pi: it has a real PID for the
  # process-list boundary, but no agent, network, or model is involved.
  let root = test.temp_dir(ctx, name: "budget-watch")?
  let session = fp"${root}/session.jsonl"
  let marker = fp"${root}/budget.marker"
  let tool = fp"${fs.cwd()?}/tools/budget-watch.xsh"
  fs.write(session, "{\"message\":{\"usage\":{\"cost\":{\"total\":1.25}}}}\n")?
  let child = process.spawn(process.command_argv("sh", ["sh", "-c", "sleep 5"]))?
  let xsh = process.which("xsh")?
  let status = process.run(process.command_argv(
    xsh,
    [xsh.display(), tool.display(), "--", "--session", session.display(),
      "--pid", f"${child.pid}", "--budget-usd", "1.00", "--marker", marker.display()],
  ))?
  test.ok(status.exited_with(3), "budget breach should use the documented exit code")?
  test.ok(fs.exists(marker)?, "budget breach should leave a durable marker")?
  test.contains(fs.read_text(marker)?, "budget exceeded: 1.250000 > 1.00")?
}

proc test_eval_executor_disables_eval_when_mock_worker_breaches_budget(ctx: TestContext) [fs, process, env, error] {
  let root = test.temp_dir(ctx, name: "eval-budget-breach")?
  let factory = fs.cwd()?
  let worker = fp"${root}/worker"
  let fake_docker = fp"${root}/fake-docker"
  fs.mkdir(worker)?
  fs.mkdir(fp"${root}/evals/task-tags/runtime")?
  fs.mkdir(fp"${root}/runtime")?
  fs.mkdir(fp"${root}/templates")?
  fs.mkdir(fp"${root}/tools")?
  fs.write(fp"${root}/evals/task-tags/EVAL.md", "# Eval task-tags\n\n## Status\n\nApproved.\n")?
  fs.write(fp"${root}/evals/task-tags/runtime/artifact.md", "artifact.txt\n")?
  fs.write(fp"${root}/evals/task-tags/runtime/task.md", "fake task\n")?
  fs.write(fp"${root}/runtime/agents.md", "agents\n")?
  fs.write(fp"${root}/runtime/review.md", "review\n")?
  fs.write(fp"${root}/runtime/handbook.md", "handbook\n")?
  for name in ["BUDGET-BREACH.md", "EXECUTOR-REPORT.md"] {
    fs.copy(fp"${factory}/templates/${name}", fp"${root}/templates/${name}", overwrite: true)?
  }
  for name in ["budget-watch.xsh", "session-report.xsh"] {
    fs.copy(fp"${factory}/tools/${name}", fp"${root}/tools/${name}", overwrite: true)?
  }
  fs.copy(fp"${factory}/tests/fixtures/fake-docker-budget-breach.sh", fake_docker, overwrite: true)?
  let chmod = process.run(process.command_argv("chmod", ["chmod", "+x", fake_docker.display()]))?
  test.ok(chmod.ok)?
  let xsh = process.which("xsh")?
  let status = process.run(process.command_argv(
    xsh,
    [xsh.display(), fp"${factory}/eval-executor.xsh".display(), "--", "task-tags"],
    cwd: root,
    env: {
      PATH: f"${root.display()}:${env.get("PATH")?}",
      FACTORY_DIR: root.display(),
      FACTORY_EVAL_WORKER_DIR: worker.display(),
      FACTORY_EVAL_IMAGE: "fake-image",
      FACTORY_EVAL_WORKER_BUDGET_USD: "2",
      FACTORY_PLATFORM: "linux/arm64",
      FACTORY_XSH_MODULE_PATH: factory.display(),
      XSH_MODULE_PATH: factory.display(),
      PI_AUTH_FILE: "/dev/null",
      DOCKER: fake_docker.display(),
    },
  ))?
  test.ok(! status.ok, "a budget-breached executor must fail the trial")?
  let eval_text = fs.read_text(fp"${root}/evals/task-tags/EVAL.md")?
  test.ok(control.eval_is_disabled(eval_text))?
  test.contains(eval_text, "Reason: eval-worker budget exceeded")?
  test.contains(eval_text, "worker/WORKER-REPORT.md")?
  let executor = fs.read_text(fp"${worker}/EXECUTOR-REPORT.md")?
  test.contains(executor, "Primary: `budget_breach`")?
  test.contains(executor, "Budget watcher: `breached`")?
}

proc test_run_agent_closes_assigned_ticket_when_mock_swe_breaches_budget(ctx: TestContext) [fs, process, env, error] {
  let root = test.temp_dir(ctx, name: "swe-budget-breach")?
  let factory = fs.cwd()?
  let run_dir = fp"${root}/runs/run-1"
  let workdir = fp"${run_dir}/worktrees/task-tags-002"
  let message = fp"${run_dir}/messages/task-tags-002.md"
  let fake_pi = fp"${root}/bin/fake-pi"
  fs.mkdir(fp"${run_dir}/messages")?
  fs.mkdir(workdir)?
  fs.mkdir(fp"${root}/tickets")?
  fs.mkdir(fp"${root}/runtime")?
  fs.mkdir(fp"${root}/templates")?
  fs.mkdir(fp"${root}/tools")?
  fs.write(fp"${root}/tickets/task-tags-002.md", "# Ticket task-tags-002\n\n## Status\n\nApproved.\n")?
  fs.write(fp"${root}/NORTH-STAR.md", "north star\n")?
  fs.write(fp"${root}/runtime/handbook.md", "handbook\n")?
  for name in ["WORKER.md", "BUDGET-BREACH.md", "XSH-SWE-ASSIGNMENT.md"] {
    fs.copy(fp"${factory}/templates/${name}", fp"${root}/templates/${name}", overwrite: true)?
  }
  for name in ["budget-watch.xsh", "session-report.xsh"] {
    fs.copy(fp"${factory}/tools/${name}", fp"${root}/tools/${name}", overwrite: true)?
  }
  fs.mkdir(fp"${root}/bin")?
  fs.copy(fp"${factory}/tests/fixtures/fake-pi-budget-breach.sh", fake_pi, overwrite: true)?
  let chmod = process.run(process.command_argv("chmod", ["chmod", "+x", fake_pi.display()]))?
  test.ok(chmod.ok)?
  let ticket_path = fp"${root}/tickets/task-tags-002.md"
  let assignment_template = fs.read_text(fp"${factory}/templates/XSH-SWE-ASSIGNMENT.md")?
  let assignment = control.fill_template(assignment_template, [
    {key: "TICKET_ID", value: "task-tags-002"},
    {key: "TICKET_PATH", value: ticket_path.display()},
    {key: "TICKET_SHA", value: hash.sha256(ticket_path)?.hex()},
    {key: "WORKTREE", value: workdir.display()},
    {key: "BRANCH", value: "factory/task-tags-002/run-1"},
    {key: "XSH_COMMIT", value: "xsh-sha"},
    {key: "SWE_REPORT", value: fp"${run_dir}/workers/xsh-swe/task-tags-002/SWE-REPORT.md".display()},
    {key: "FACTORY_DIR", value: root.display()},
    {key: "FACTORY_RUN_DIR", value: run_dir.display()},
    {key: "NORTH_STAR_FILE", value: fp"${root}/NORTH-STAR.md".display()},
    {key: "HANDBOOK_FILE", value: fp"${root}/runtime/handbook.md".display()},
    {key: "XSH_AGENTS_FILE", value: "xsh/AGENTS.md"},
    {key: "XSH_RATIONALE_FILE", value: "xsh/docs/CHAPTER-01-why-xsh.md"},
    {key: "TICKET_TEXT", value: "## Observation\n\nfixture"},
  ])
  fs.write(message, assignment)?
  let assignment_sha = hash.sha256(message)?.hex()
  let xsh = process.which("xsh")?
  let status = process.run(process.command_argv(
    xsh,
    [xsh.display(), fp"${factory}/run-agent.xsh".display(), "--", "xsh-swe", "task-tags-002",
      fp"${factory}/roles/xsh-swe.md".display(), message.display()],
    cwd: root,
    env: {
      PATH: f"${root}/bin:${env.get("PATH")?}",
      XSH_MODULE_PATH: factory.display(),
      FACTORY_DIR: root.display(),
      FACTORY_RUN_DIR: run_dir.display(),
      FACTORY_RUN_AGENT: fp"${factory}/run-agent.xsh".display(),
      FACTORY_PARENT_ID: "director",
      FACTORY_MODE: "ticket-implementation",
      FACTORY_TICKET_ID: "task-tags-002",
      FACTORY_ASSIGNMENT_SHA: assignment_sha,
      FACTORY_WORKDIR: workdir.display(),
      FACTORY_XSH_REPO: fp"${factory}/../xsh".display(),
      FACTORY_XSH_SWE_BUDGET_USD: "2",
      PI_AUTH_FILE: "/dev/null",
      PI_COMMAND: "fake-pi",
    },
  ))?
  test.ok(! status.ok, "an over-budget SWE runner must fail the worker")?
  let ticket = fs.read_text(ticket_path)?
  test.ok(control.ticket_is_closed(ticket))?
  test.contains(ticket, "Reason: too difficult")?
  test.contains(ticket, "runs/run-1/workers/xsh-swe/task-tags-002/WORKER-REPORT.md")?
  test.ok(fs.exists(fp"${run_dir}/workers/xsh-swe/task-tags-002/BUDGET-BREACH")?)?
}

proc test_audit_run_accepts_standalone_eval_design_evidence(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "audit-design")?
  let run_dir = fp"${root}/run-1"
  let worker_dir = fp"${run_dir}/workers/eval-designer/proposal-1"
  let proposal_dir = fp"${run_dir}/proposals/proposal-1"
  fs.mkdir(worker_dir)?
  fs.mkdir(proposal_dir)?
  fs.write(fp"${run_dir}/CYCLE-REQUEST.md", "# Design\n\n## Mode\n\n- `eval-design`\n")?
  let provenance_template = fs.read_text(fp"${fs.cwd()?}/templates/PROVENANCE.md")?
  fs.write(fp"${run_dir}/PROVENANCE.md", control.fill_template(provenance_template, [
    {key: "RUN_ID", value: run_dir.display()},
    {key: "MODE", value: "eval-design"},
    {key: "REQUEST", value: "CYCLE-REQUEST.md"},
    {key: "BUILD_ID", value: "fixture-design"},
    {key: "XSH_COMMIT", value: "fixture-xsh"},
    {key: "CANDIDATE_TICKET", value: "not-reevaluation"},
    {key: "CANDIDATE_WORKTREE", value: "not-reevaluation"},
    {key: "IMAGE", value: "not-used"},
    {key: "IMAGE_ID", value: "not-used"},
    {key: "PLATFORM", value: "fixture-platform"},
    {key: "APPROVED_HANDBOOK_SHA", value: "approved"},
    {key: "CANDIDATE_HANDBOOK_SHA", value: "not-used"},
    {key: "TICKET_SNAPSHOT_SHA", value: "not-used"},
  ]))?
  fs.write(fp"${run_dir}/COST.md", "# Cost\n\n## Workers\n\n## Role totals\n\n## Run total\n\n- Budget failures or unknown costs: 0\n")?
  fs.write(fp"${run_dir}/proposals/proposal-1/EVAL.md", "proposal\n")?
  fs.write(fp"${worker_dir}/DESIGNER-REPORT.md", "# Designer\n\n## Result\n\nready-for-review\n\n## Proposal\n\nproposal\n\n## Dry run\n\nevidence\n\n## North-star impact\n\nimpact\n\n## Known risks\n\nnone\n\n## Review path\n\npath\n")?
  fs.write(fp"${worker_dir}/session.jsonl", r"""
{"timestamp":"2026-08-01T12:00:00.000Z","type":"message","message":{"role":"user","content":"fixture"}}
{"timestamp":"2026-08-01T12:00:01.000Z","type":"message","message":{"role":"assistant","provider":"openrouter","model":"deepseek/deepseek-v4-flash-0731","stopReason":"stop","content":[{"type":"thinking","thinking":"fixture"}],"usage":{"input":1,"output":2,"reasoning":1,"totalTokens":3,"cost":{"total":0.001}}}}
""")?
  let xsh = process.which("xsh")?
  let report_status = process.run(process.command_argv(
    xsh,
    [xsh.display(), fp"${fs.cwd()?}/tools/session-report.xsh", "--", "worker",
      "--session", fp"${worker_dir}/session.jsonl".display(),
      "--output", fp"${worker_dir}/WORKER-REPORT.md".display(),
      "--role", "eval-designer", "--worker-id", "proposal-1", "--budget-usd", "0.30"],
  ))?
  test.ok(report_status.ok, "synthetic design worker report should render")?
  let audit_status = process.run(process.command_argv(
    xsh,
    [xsh.display(), fp"${fs.cwd()?}/audit-run.xsh", "--", run_dir.display(), "eval-design"],
  ))?
  test.ok(audit_status.ok, "standalone design audit should run")?
  let audit = fs.read_text(fp"${run_dir}/AUDIT.md")?
  test.ok(control.audit_report_contract_ok(audit))?
  test.eq(control.audit_result(audit), "pass")?
  test.contains(audit, "Mode: `eval-design`")?
}

proc test_audit_run_accepts_ready_for_review_ticket_evidence(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "audit-ticket")?
  let run_dir = fp"${root}/run-1"
  let director_dir = fp"${run_dir}/workers/director/director"
  let swe_dir = fp"${run_dir}/workers/xsh-swe/task-tags-002"
  let factory = fs.cwd()?
  fs.mkdir(director_dir)?
  fs.mkdir(swe_dir)?
  fs.copy(fp"${factory}/tests/fixtures/audit-ticket-request.md", fp"${run_dir}/CYCLE-REQUEST.md", overwrite: true)?
  fs.copy(fp"${factory}/tests/fixtures/audit-ticket-director-report.md", fp"${run_dir}/DIRECTOR-REPORT.md", overwrite: true)?
  fs.copy(fp"${factory}/tests/fixtures/audit-ticket-cost.md", fp"${run_dir}/COST.md", overwrite: true)?
  fs.copy(fp"${factory}/tests/fixtures/audit-ticket-swe-report.md", fp"${swe_dir}/SWE-REPORT.md", overwrite: true)?
  for target in [director_dir, swe_dir] {
    fs.copy(fp"${factory}/tests/fixtures/audit-ticket-session.jsonl", fp"${target}/session.jsonl", overwrite: true)?
  }

  let provenance_template = fs.read_text(fp"${factory}/templates/PROVENANCE.md")?
  fs.write(fp"${run_dir}/PROVENANCE.md", control.fill_template(provenance_template, [
    {key: "RUN_ID", value: run_dir.display()},
    {key: "MODE", value: "ticket-implementation"},
    {key: "REQUEST", value: "CYCLE-REQUEST.md"},
    {key: "BUILD_ID", value: "fixture-ticket"},
    {key: "XSH_COMMIT", value: "fixture-xsh"},
    {key: "CANDIDATE_TICKET", value: "task-tags-002"},
    {key: "CANDIDATE_WORKTREE", value: "fixture-worktree"},
    {key: "IMAGE", value: "not-used"},
    {key: "IMAGE_ID", value: "not-used"},
    {key: "PLATFORM", value: "fixture-platform"},
    {key: "APPROVED_HANDBOOK_SHA", value: "not-requested"},
    {key: "CANDIDATE_HANDBOOK_SHA", value: "not-requested"},
    {key: "TICKET_SNAPSHOT_SHA", value: "fixture-ticket"},
  ]))?

  let xsh = process.which("xsh")?
  for entry in [
    {path: director_dir, role: "director", worker: "director"},
    {path: swe_dir, role: "xsh-swe", worker: "task-tags-002"},
  ] {
    let report_status = process.run(process.command_argv(
      xsh,
      [xsh.display(), fp"${factory}/tools/session-report.xsh".display(), "--", "worker",
        "--session", fp"${entry.path}/session.jsonl".display(),
        "--output", fp"${entry.path}/WORKER-REPORT.md".display(),
        "--role", entry.role, "--worker-id", entry.worker, "--budget-usd", "0.05"],
    ))?
    test.ok(report_status.ok, "synthetic ticket worker report should render")?
  }

  let audit_status = process.run(process.command_argv(
    xsh, [xsh.display(), fp"${factory}/audit-run.xsh".display(), "--", run_dir.display(), "ticket-implementation"],
  ))?
  test.ok(audit_status.ok, "ticket audit should accept a ready-for-review SWE report")?
  let audit = fs.read_text(fp"${run_dir}/AUDIT.md")?
  test.ok(control.audit_report_contract_ok(audit))?
  test.eq(control.audit_result(audit), "pass")?
  test.ok(audit.contains("Ticket evidence") and ! audit.contains("Ticket evidence: fail"))?
  test.contains(audit, "| ticket | task-tags-002 | ready-for-review | xsh-swe | pass |")?
}

proc test_cleanup_run_uses_a_mock_container_command(ctx: TestContext) [fs, process, error] {
  let run_dir = test.temp_dir(ctx, name: "cleanup-run")?
  let registry = fp"${run_dir}/processes"
  let fake_docker = fp"${run_dir}/fake-docker"
  let docker_log = fp"${run_dir}/docker.log"
  fs.mkdir(registry)?
  fs.mkdir(fp"${run_dir}/phases/01/processes")?
  fs.write(fp"${registry}/worker.pids", "2147483647\nnot-a-pid\n")?
  fs.write(fp"${run_dir}/phases/01/processes/worker.pids", "2147483646\n")?
  fs.write(fp"${run_dir}/worker.cid", "fake-container\n")?
  fs.write(fp"${run_dir}/phases/01/worker.cid", "fake-phase-container\n")?
  fs.write(fp"${run_dir.parent()}/ACTIVE", run_dir.display() + "\n")?
  fs.write(fake_docker, f"#!/bin/sh\nprintf called >> '${docker_log.display()}'\n")?
  let chmod = process.run(process.command_argv("chmod", ["chmod", "+x", fake_docker.display()]))?
  test.ok(chmod.ok)?
  let tool = fp"${fs.cwd()?}/tools/cleanup-run.xsh"
  let xsh = process.which("xsh")?
  let status = process.run(process.command_argv(
    xsh,
    [xsh.display(), tool.display(), "--", run_dir.display()],
    env: {PATH: f"${run_dir.display()}:/usr/bin:/bin", DOCKER: fake_docker.display()},
  ))?
  test.ok(status.ok, "cleanup should tolerate stale and malformed registry entries")?
  test.ok(! (fs.exists(fp"${run_dir.parent()}/ACTIVE")?))?
  test.eq(fs.read_text(docker_log)?, "calledcalledcalledcalled")?
}
