##! Native tests for factory tools. These fixtures use synthetic sessions and
##! harmless subprocesses; they never launch Pi.

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
