##! Shared host-side eval executor. Eval wrappers only select the eval id;
##! this file owns the isolated Docker worker/evaluator protocol and report.

use factory_control as control
use factory_runtime as runtime

proc main(...argv: List[Str]) [fs, process, env, time, error, io] {
  let factory_dir = env.path("FACTORY_DIR")?
  let eval_id = if argv.len() > 0 { argv[0] } else { env.get_or("FACTORY_EVAL_ID", "")? }
  if eval_id == "" {
    eprint "eval-executor requires an eval id"
    abort(2)
  }
  let eval_dir = fp"${factory_dir}/evals/${eval_id}"
  let eval_manifest = fp"${eval_dir}/EVAL.md"
  if fs.exists(eval_manifest)? and control.eval_is_disabled(eval_manifest.read_text()?) {
    eprint f"eval ${eval_id} is disabled"
    abort(2)
  }
  let worker_dir = env.path("FACTORY_EVAL_WORKER_DIR")?
  let run_dir = env.path("FACTORY_RUN_DIR", fp"${factory_dir}/runs/unknown")?
  let work_dir = fp"${worker_dir}/work"
  let docker = env.get_or("DOCKER", "docker")?
  let platform = env.get_or("FACTORY_PLATFORM", "linux/arm64")?
  let base_image = env.get_or("FACTORY_BASE_IMAGE", "xsh-factory-base:latest")?
  let image = env.get_or("FACTORY_EVAL_IMAGE", base_image)?
  let auth_file = env.path("PI_AUTH_FILE")?
  let provider = env.get_or("FACTORY_EVAL_WORKER_PROVIDER", control.default_provider("eval-worker"))?
  let model = env.get_or("FACTORY_EVAL_WORKER_MODEL", control.default_model("eval-worker"))?
  let thinking = env.get_or("FACTORY_EVAL_WORKER_THINKING", control.default_thinking("eval-worker"))?
  let configured_budget = env.get_or("FACTORY_EVAL_WORKER_BUDGET_USD", control.default_budget("eval-worker"))?
  let budget = control.clamp_budget("eval-worker", configured_budget)?
  let max_turns = env.get_or("FACTORY_EVAL_WORKER_MAX_TURNS", control.default_max_turns("eval-worker"))?
  let max_wall_seconds = env.get_or("FACTORY_EVAL_WORKER_MAX_WALL_SECONDS", control.default_max_wall_seconds("eval-worker"))?
  let tools = env.get_or("FACTORY_EVAL_WORKER_TOOLS", control.default_tools("eval-worker"))?
  let trial_id = env.get_or("FACTORY_TRIAL_ID", "1")?
  let task_file = "task.md"
  let artifact_file = fs.read_text(fp"${eval_dir}/runtime/artifact.md")?.trim()
  let evaluator_file = fp"${eval_dir}/evaluator.xsh"
  if ! fs.exists(evaluator_file)? {
    eprint f"eval ${eval_id} is missing its package evaluator.xsh"
    abort(2)
  }
  if artifact_file == "" or artifact_file.contains("/") or artifact_file.contains("\\") {
    eprint f"eval ${eval_id} has invalid runtime/artifact.md"
    abort(2)
  }
  let handbook_file = env.path("FACTORY_HANDBOOK_FILE", fp"${factory_dir}/runtime/handbook.md")?
  let xsh_path = process.which("xsh")?
  let session = fp"${worker_dir}/session.jsonl"
  let agent_cidfile = fp"${worker_dir}/agent.cid"
  let evaluator_cidfile = fp"${worker_dir}/evaluator.cid"
  let agent_process_registry = fp"${worker_dir}/eval-worker.pids"
  fs.mkdir(worker_dir)?
  fs.mkdir(work_dir)?
  for name in ["agents.md", "review.md"] {
    fs.copy(fp"${factory_dir}/runtime/${name}", fp"${work_dir}/${name}", overwrite: true)?
  }
  fs.copy(fp"${eval_dir}/runtime/${task_file}", fp"${work_dir}/${task_file}", overwrite: true)?
  fs.copy(handbook_file, fp"${work_dir}/handbook.md", overwrite: true)?

  let agent_flags = [
    "run", "--rm", "--platform", platform,
    "--cidfile", agent_cidfile.display(),
    "--read-only",
    "--memory", "512m",
    "--cpus", "2",
    "--pids-limit", "128",
    "--tmpfs", "/tmp:rw,noexec,nosuid,nodev,size=64m",
    "--tmpfs", "/run/pi-agent:rw,noexec,nosuid,nodev,size=16m",
    "--cap-drop=ALL",
    "--security-opt=no-new-privileges",
    "--workdir", "/work",
  ]
  let agent_mounts = [
    "--mount", f"type=bind,src=${auth_file.display()},dst=/run/pi-auth.json,readonly",
    "--mount", f"type=bind,src=${work_dir.display()},dst=/work",
    "--mount", f"type=bind,src=${worker_dir.display()},dst=/session",
    "--mount", f"type=bind,src=${work_dir.display()}/agents.md,dst=/work/agents.md,readonly",
    "--mount", f"type=bind,src=${work_dir.display()}/handbook.md,dst=/work/handbook.md,readonly",
    "--mount", f"type=bind,src=${work_dir.display()}/${task_file},dst=/work/${task_file},readonly",
  ]
  let agent_envs = [
    "--env", f"PI_PROVIDER=${provider}",
    "--env", f"PI_MODEL=${model}",
    "--env", f"PI_THINKING=${thinking}",
    "--env", f"PI_TOOLS=${tools}",
    "--env", "PI_COMMAND=pi",
    "--env", "PI_CODING_AGENT_DIR=/run/pi-agent",
  ]
  let agent_argv = agent_flags.extend(agent_mounts).extend(agent_envs).extend([
    image, "xsh", "/usr/local/lib/xsh-factory/eval-worker.xsh", "--",
    "/session/session.jsonl", f"/work/${task_file}",
  ])
  let agent_started = time.now()
  let agent_handle = spawn process.command_argv(
    docker,
    [docker].extend(agent_argv),
    stdout: fp"${worker_dir}/container.stdout",
    stderr: fp"${worker_dir}/container.stderr",
  )?
  fs.write(agent_process_registry, f"${agent_handle.pid}\n")?
  let watcher = spawn process.command_argv(
    xsh_path,
    [xsh_path.display(), fp"${factory_dir}/tools/budget-watch.xsh", "--",
      "--session", session.display(), "--pid", f"${agent_handle.pid}",
      "--budget-usd", budget, "--marker", fp"${worker_dir}/BUDGET-BREACH".display()],
  )?
  let limit_watcher = spawn process.command_argv(
    xsh_path,
    [xsh_path.display(), fp"${factory_dir}/tools/session-watch.xsh", "--",
      "--session", session.display(), "--pid", f"${agent_handle.pid}",
      "--max-turns", max_turns, "--max-seconds", max_wall_seconds,
      "--marker", fp"${worker_dir}/SESSION-LIMIT".display(), "--role", "eval-worker"],
  )?
  fs.write(agent_process_registry, f"${agent_handle.pid}\n${watcher.pid}\n${limit_watcher.pid}\n")?
  let agent_status = wait agent_handle?
  let watcher_status = wait watcher?
  let limit_status = wait limit_watcher?
  let agent_wall = time.now() - agent_started
  fs.remove(agent_process_registry, missing_ok: true)?
  let budget_breach = fs.exists(fp"${worker_dir}/BUDGET-BREACH")?
  if budget_breach {
    let disabled = runtime.disable_eval(factory_dir, eval_id, worker_dir)?
    if ! disabled {
      eprint f"unable to disable over-budget eval: ${eval_id}"
    }
  }

  let eval_flags = [
    "run", "--rm", "--platform", platform,
    "--cidfile", evaluator_cidfile.display(),
    "--read-only",
    "--memory", "256m",
    "--cpus", "2",
    "--pids-limit", "64",
    "--tmpfs", "/tmp:rw,noexec,nosuid,nodev,size=64m",
    "--cap-drop=ALL",
    "--security-opt=no-new-privileges",
    "--workdir", "/work",
  ]
  let eval_mounts = [
    "--mount", f"type=bind,src=${work_dir.display()},dst=/work,readonly",
    "--mount", f"type=bind,src=${worker_dir.display()},dst=/session",
    "--mount", f"type=bind,src=${worker_dir.display()},dst=/export",
    "--mount", f"type=bind,src=${eval_dir.display()}/evaluate.xsh,dst=/run/evaluate.xsh,readonly",
    "--mount", f"type=bind,src=${evaluator_file.display()},dst=/run/evaluator.xsh,readonly",
  ]
  let eval_envs = [
    "--env", f"FACTORY_EVAL_ID=${eval_id}",
    "--env", f"FACTORY_TRIAL_ID=${trial_id}",
    "--env", f"FACTORY_XSH_COMMIT=${env.get_or("FACTORY_XSH_COMMIT", "unknown")?}",
    "--env", f"FACTORY_IMAGE_ID=${env.get_or("FACTORY_IMAGE_ID", "unknown")?}",
    "--env", f"FACTORY_PLATFORM=${platform}",
    "--env", f"FACTORY_EVAL_WORKER_PROVIDER=${provider}",
    "--env", f"FACTORY_EVAL_WORKER_MODEL=${model}",
    "--env", f"FACTORY_EVAL_WORKER_THINKING=${thinking}",
  ]
  let eval_status = process.run(process.command_argv(
    docker,
    [docker].extend(eval_flags).extend(eval_mounts).extend(eval_envs).extend([image, "xsh", "/run/evaluate.xsh"]),
    stdout: fp"${worker_dir}/evaluator.stdout",
    stderr: fp"${worker_dir}/evaluator.stderr",
  ))?

  let report_status = process.run(process.command_argv(
    xsh_path,
    [xsh_path.display(), fp"${factory_dir}/tools/session-report.xsh", "--", "worker", "--session", session.display(),
      "--output", fp"${worker_dir}/report.json".display(), "--role", "eval-worker",
      "--worker-id", f"${eval_id}-${trial_id}", "--budget-usd", budget],
  ))?
  # The provider stream is parser input only. Remove it after normalization;
  # retaining message_update deltas can be orders of magnitude larger than the
  # canonical session and report evidence.
  fs.remove(fp"${session.display()}.events.jsonl", missing_ok: true)?
  let result = if agent_status.ok and watcher_status.ok and limit_status.ok and eval_status.ok and report_status.ok { "pass" } else { "fail" }
  let agent_state = if agent_status.ok and watcher_status.ok and limit_status.ok { "pass" } else { "fail" }
  let eval_state = if eval_status.ok { "pass" } else { "fail" }
  let budget_state = if budget_breach { "breached" } else { "pass" }
  let manifest = fp"${worker_dir}/run.json"
  let manifest_state = if fs.exists(manifest)? { "present" } else { "missing" }
  let classification = if budget_breach {
    "budget_breach"
  } else if fs.exists(fp"${worker_dir}/SESSION-LIMIT")? {
    "session_limit"
  } else if ! agent_status.ok {
    "worker_failed"
  } else if ! eval_status.ok {
    "evaluator_failed"
  } else if ! report_status.ok {
    "reporting_failed"
  } else {
    "pass"
  }
  let artifact_state = if fs.exists(fp"${work_dir}/${artifact_file}")? { "present" } else { "missing" }
  let review_state = if fs.exists(fp"${work_dir}/review.md")? { "present" } else { "missing" }
  let reporting_state = if report_status.ok { "pass" } else { "fail" }
  let report_path = fp"${worker_dir}/report.json"
  if fs.exists(report_path)? {
    let session_report = json.read(report_path)?
    let with_identity = json.set(session_report, ["identity", "eval_id"], eval_id)?
    let with_run = json.set(with_identity, ["identity", "run_id"], run_dir.name())?
    let enriched = json.set(with_run, ["execution"], {
      result: result,
      classification: classification,
      agent_state: agent_state,
      evaluator_state: eval_state,
      budget_state: budget_state,
      reporting_state: reporting_state,
      evaluator_manifest: if fs.exists(manifest)? { manifest.display() } else { "" },
      agent_wall_ms: agent_wall,
      artifact: {name: artifact_file, state: artifact_state},
      review: {state: review_state},
    })?
    json.write(report_path, enriched, pretty: true)?
  }
  print f"${eval_id} executor: ${result}"
  abort(if result == "pass" { 0 } else { 1 })
}
