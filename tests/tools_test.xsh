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
  test.contains(rendered, "Budget status: pass")?
  test.contains(thinking, "inspect the fixture")?
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
        "--role", entry.role, "--worker-id", entry.worker, "--budget-usd", "2"],
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

proc test_cleanup_run_uses_a_mock_container_command(ctx: TestContext) [fs, process, error] {
  let run_dir = test.temp_dir(ctx, name: "cleanup-run")?
  let registry = fp"${run_dir}/processes"
  let fake_docker = fp"${run_dir}/fake-docker"
  let docker_log = fp"${run_dir}/docker.log"
  fs.mkdir(registry)?
  fs.write(fp"${registry}/worker.pids", "2147483647\nnot-a-pid\n")?
  fs.write(fp"${run_dir}/worker.cid", "fake-container\n")?
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
  test.eq(fs.read_text(docker_log)?, "calledcalled")?
}
