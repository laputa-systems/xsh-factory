##! Executes one isolated task-tags eval-worker trial and writes a Markdown
##! report. The evaluator runs in a separate container boundary.

proc main() [fs, process, env, time, error, io] {
  let factory_dir = env.path("FACTORY_DIR")?
  let worker_dir = env.path("FACTORY_EVAL_WORKER_DIR")?
  let work_dir = fp"${worker_dir}/work"
  let docker = env.get_or("DOCKER", "docker")?
  let platform = env.get_or("FACTORY_PLATFORM", "linux/arm64")?
  let image = env.get_or("FACTORY_EVAL_IMAGE", env.get_or("FACTORY_TASK_TAGS_IMAGE", "xsh-factory-task-tags:latest")?)?
  let auth_file = env.path("PI_AUTH_FILE")?
  let provider = env.get_or("FACTORY_EVAL_WORKER_PROVIDER", "openrouter")?
  let model = env.get_or("FACTORY_EVAL_WORKER_MODEL", "deepseek/deepseek-v4-flash-0731")?
  let thinking = env.get_or("FACTORY_EVAL_WORKER_THINKING", "high")?
  let budget = env.get_or("FACTORY_EVAL_WORKER_BUDGET_USD", "2")?
  let eval_id = env.get_or("FACTORY_EVAL_ID", "task-tags")?
  let trial_id = env.get_or("FACTORY_TRIAL_ID", "1")?
  let handbook_file = env.path("FACTORY_HANDBOOK_FILE", fp"${factory_dir}/evals/task-tags/runtime/handbook.md")?
  let session = fp"${worker_dir}/session.jsonl"
  let agent_cidfile = fp"${worker_dir}/agent.cid"
  let evaluator_cidfile = fp"${worker_dir}/evaluator.cid"
  fs.mkdir(worker_dir)?
  fs.mkdir(work_dir)?
  for name in ["agents.md", "handbook.md", "review.md", "task-tags.md"] {
    fs.copy(fp"${factory_dir}/evals/task-tags/runtime/${name}", fp"${work_dir}/${name}", overwrite: true)?
  }
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
    "--mount", f"type=bind,src=${factory_dir.display()}/evals/task-tags/eval-worker.xsh,dst=/run/eval-worker.xsh,readonly",
    "--mount", f"type=bind,src=${work_dir.display()}/agents.md,dst=/work/agents.md,readonly",
    "--mount", f"type=bind,src=${work_dir.display()}/handbook.md,dst=/work/handbook.md,readonly",
    "--mount", f"type=bind,src=${work_dir.display()}/task-tags.md,dst=/work/task-tags.md,readonly",
  ]
  let agent_envs = [
    "--env", f"PI_PROVIDER=${provider}",
    "--env", f"PI_MODEL=${model}",
    "--env", f"PI_THINKING=${thinking}",
    "--env", "PI_COMMAND=pi",
    "--env", "PI_CODING_AGENT_DIR=/run/pi-agent",
  ]
  let agent_argv = agent_flags.extend(agent_mounts).extend(agent_envs).extend([
    image, "xsh", "/run/eval-worker.xsh", "--", "/session/session.jsonl", "/work/task-tags.md",
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
    "--mount", f"type=bind,src=${factory_dir.display()}/evals/task-tags/evaluate.xsh,dst=/run/evaluate.xsh,readonly",
  ]
  let eval_envs = [
    "--env", f"FACTORY_EVAL_ID=${eval_id}",
    "--env", f"FACTORY_TRIAL_ID=${trial_id}",
    "--env", f"FACTORY_XSH_COMMIT=${env.get_or("FACTORY_XSH_COMMIT", "unknown")?}",
    "--env", f"FACTORY_XSH_BIN_SHA256=${env.get_or("FACTORY_XSH_BIN_SHA256", "unknown")?}",
    "--env", f"FACTORY_XSHT_BIN_SHA256=${env.get_or("FACTORY_XSHT_BIN_SHA256", "unknown")?}",
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
  let artifact = if fs.exists(fp"${work_dir}/tag.xsh")? { "present" } else { "missing" }
  let review = if fs.exists(fp"${work_dir}/review.md")? { "present" } else { "missing" }
  let reporting_state = if report_status.ok { "pass" } else { "fail" }
  fs.write(fp"${worker_dir}/EXECUTOR-REPORT.md", f"# Executor report\n\n## Result\n\n${result}\n\n## Failure classification\n\n- Primary: `${classification}`\n- Worker container: `${agent_state}`\n- Evaluator container: `${eval_state}`\n- Session reporting: `${reporting_state}`\n- Evaluator manifest: `${manifest_state}`\n\n## Trial\n\n- Eval: ${eval_id}\n- Trial: ${trial_id}\n- Worker session: `session.jsonl`\n- Agent wall time: ${agent_wall}\n\n## Artifact\n\n- tag.xsh: ${artifact}\n- review.md: ${review}\n\n## Evidence\n\nThe evaluator manifest contains separate protocol, correctness, restriction,\nand timing evidence. The worker session, extracted thinking transcript,\ncontainer logs, and copied artifacts are in this directory.\n")?
  print f"task-tags executor: ${result}"
  abort(if result == "pass" { 0 } else { 1 })
}
