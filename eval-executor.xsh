##! Shared host-side eval executor. Eval wrappers only select the eval id;
##! this file owns the isolated Docker worker/evaluator protocol and report.

use factory_control as control

proc main(...argv: List[Str]) [fs, process, env, time, error, io] {
  let factory_dir = env.path("FACTORY_DIR")?
  let eval_id = if argv.len() > 0 { argv[0] } else { env.get_or("FACTORY_EVAL_ID", "")? }
  if eval_id == "" {
    eprint "eval-executor requires an eval id"
    abort(2)
  }
  let eval_dir = fp"${factory_dir}/evals/${eval_id}"
  let worker_dir = env.path("FACTORY_EVAL_WORKER_DIR")?
  let work_dir = fp"${worker_dir}/work"
  let docker = env.get_or("DOCKER", "docker")?
  let platform = env.get_or("FACTORY_PLATFORM", "linux/arm64")?
  let base_image = env.get_or("FACTORY_BASE_IMAGE", "xsh-factory-base:latest")?
  let image = env.get_or("FACTORY_EVAL_IMAGE", base_image)?
  let auth_file = env.path("PI_AUTH_FILE")?
  let provider = env.get_or("FACTORY_EVAL_WORKER_PROVIDER", control.default_provider("eval-worker"))?
  let model = env.get_or("FACTORY_EVAL_WORKER_MODEL", control.default_model("eval-worker"))?
  let thinking = env.get_or("FACTORY_EVAL_WORKER_THINKING", control.default_thinking("eval-worker"))?
  let budget = env.get_or("FACTORY_EVAL_WORKER_BUDGET_USD", control.default_budget("eval-worker"))?
  let tools = env.get_or("FACTORY_EVAL_WORKER_TOOLS", control.default_tools("eval-worker"))?
  let trial_id = env.get_or("FACTORY_TRIAL_ID", "1")?
  let task_file = "task.md"
  let artifact_file = fs.read_text(fp"${eval_dir}/runtime/artifact.md")?.trim()
  if artifact_file == "" or artifact_file.contains("/") or artifact_file.contains("\\") {
    eprint f"eval ${eval_id} has invalid runtime/artifact.md"
    abort(2)
  }
  let handbook_file = env.path("FACTORY_HANDBOOK_FILE", fp"${factory_dir}/runtime/handbook.md")?
  let session = fp"${worker_dir}/session.jsonl"
  let agent_cidfile = fp"${worker_dir}/agent.cid"
  let evaluator_cidfile = fp"${worker_dir}/evaluator.cid"
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
    "--tmpfs", "/tmp:rw,noexec,nosuid,nodev",
    "--tmpfs", "/run/pi-agent:rw,noexec,nosuid,nodev",
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
  let agent_status = process.run(process.command_argv(
    docker,
    [docker].extend(agent_argv),
    stdout: fp"${worker_dir}/container.stdout",
    stderr: fp"${worker_dir}/container.stderr",
  ))?
  let agent_wall = time.now() - agent_started

  let eval_flags = [
    "run", "--rm", "--platform", platform,
    "--cidfile", evaluator_cidfile.display(),
    "--read-only",
    "--tmpfs", "/tmp:rw,noexec,nosuid,nodev",
    "--cap-drop=ALL",
    "--security-opt=no-new-privileges",
    "--workdir", "/work",
  ]
  let eval_mounts = [
    "--mount", f"type=bind,src=${work_dir.display()},dst=/work,readonly",
    "--mount", f"type=bind,src=${worker_dir.display()},dst=/session",
    "--mount", f"type=bind,src=${worker_dir.display()},dst=/export",
    "--mount", f"type=bind,src=${eval_dir.display()}/evaluate.xsh,dst=/run/evaluate.xsh,readonly",
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

  let xsh_path = process.which("xsh")?
  let report_status = process.run(process.command_argv(
    xsh_path,
    [xsh_path.display(), fp"${factory_dir}/tools/session-report.xsh", "--", "worker", "--session", session.display(),
      "--output", fp"${worker_dir}/WORKER-REPORT.md".display(), "--role", "eval-worker",
      "--worker-id", f"${eval_id}-${trial_id}", "--budget-usd", budget],
  ))?
  let result = if agent_status.ok and eval_status.ok and report_status.ok { "pass" } else { "fail" }
  let agent_state = if agent_status.ok { "pass" } else { "fail" }
  let eval_state = if eval_status.ok { "pass" } else { "fail" }
  let manifest = fp"${worker_dir}/run.json"
  let manifest_state = if fs.exists(manifest)? { "present" } else { "missing" }
  let classification = if ! agent_status.ok {
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
  let report_template = fp"${factory_dir}/templates/EXECUTOR-REPORT.md"
  let report_values: List[control.TemplateValue] = [
    {key: "RESULT", value: result},
    {key: "CLASSIFICATION", value: classification},
    {key: "AGENT_STATE", value: agent_state},
    {key: "EVAL_STATE", value: eval_state},
    {key: "REPORTING_STATE", value: reporting_state},
    {key: "MANIFEST_STATE", value: manifest_state},
    {key: "EVAL_ID", value: eval_id},
    {key: "TRIAL_ID", value: trial_id},
    {key: "AGENT_WALL", value: agent_wall.float().format(precision: 0)},
    {key: "ARTIFACT_FILE", value: artifact_file},
    {key: "ARTIFACT_STATE", value: artifact_state},
    {key: "REVIEW_STATE", value: review_state},
  ]
  fs.write(fp"${worker_dir}/EXECUTOR-REPORT.md", control.fill_template(
    report_template.read_text()?, report_values
  ))?
  print f"${eval_id} executor: ${result}"
  abort(if result == "pass" { 0 } else { 1 })
}
