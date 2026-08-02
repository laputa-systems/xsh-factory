##! Executes one isolated hello eval-worker trial and writes a Markdown report.

proc main() [fs, process, env, time, error, io] {
  let factory_dir = env.path("FACTORY_DIR")?
  let run_dir = env.path("FACTORY_RUN_DIR")?
  let worker_dir = env.path("FACTORY_EVAL_WORKER_DIR")?
  let work_dir = fp"${worker_dir}/work"
  let docker = env.get_or("DOCKER", "docker")?
  let platform = env.get_or("FACTORY_PLATFORM", "linux/arm64")?
  let image = env.get("FACTORY_HELLO_IMAGE")?
  let auth_file = env.path("PI_AUTH_FILE")?
  let provider = env.get_or("FACTORY_EVAL_WORKER_PROVIDER", "openrouter")?
  let model = env.get_or("FACTORY_EVAL_WORKER_MODEL", "deepseek/deepseek-v4-flash-0731")?
  let thinking = env.get_or("FACTORY_EVAL_WORKER_THINKING", "high")?
  let eval_id = env.get_or("FACTORY_EVAL_ID", "hello")?
  let trial_id = env.get_or("FACTORY_TRIAL_ID", "1")?
  let session = fp"${worker_dir}/session.jsonl"
  fs.mkdir(worker_dir)?
  fs.mkdir(work_dir)?
  for name in ["agents.md", "handbook.md", "review.md", "task.md"] {
    fs.copy(fp"${factory_dir}/evals/hello/runtime/${name}", fp"${work_dir}/${name}", overwrite: true)?
  }

  let flags = [
    "run", "--rm", "--platform", platform,
    "--read-only",
    "--tmpfs", "/tmp:rw,noexec,nosuid,nodev",
    "--tmpfs", "/run/pi-agent:rw,noexec,nosuid,nodev",
    "--cap-drop=ALL",
    "--security-opt=no-new-privileges",
    "--workdir", "/work",
  ]
  let mounts = [
    "--mount", f"type=bind,src=${auth_file.display()},dst=/run/pi-auth.json,readonly",
    "--mount", f"type=bind,src=${work_dir.display()},dst=/work",
    "--mount", f"type=bind,src=${worker_dir.display()},dst=/session",
    "--mount", f"type=bind,src=${factory_dir.display()}/evals/hello/eval-worker.xsh,dst=/run/eval-worker.xsh,readonly",
    "--mount", f"type=bind,src=${work_dir.display()}/agents.md,dst=/work/agents.md,readonly",
    "--mount", f"type=bind,src=${work_dir.display()}/handbook.md,dst=/work/handbook.md,readonly",
    "--mount", f"type=bind,src=${work_dir.display()}/review.md,dst=/work/review.md,readonly",
    "--mount", f"type=bind,src=${work_dir.display()}/task.md,dst=/work/task.md,readonly",
  ]
  let envs = [
    "--env", f"PI_PROVIDER=${provider}",
    "--env", f"PI_MODEL=${model}",
    "--env", f"PI_THINKING=${thinking}",
    "--env", "PI_COMMAND=pi",
    "--env", "PI_CODING_AGENT_DIR=/run/pi-agent",
  ]
  let argv = flags.extend(mounts).extend(envs).extend([
    image, "xsh", "/run/eval-worker.xsh", "--", "/session/session.jsonl", "/work/task.md",
  ])
  let started = time.now()
  let status = process.run(process.command_argv(
    docker,
    [docker].extend(argv),
    stdout: fp"${worker_dir}/container.stdout",
    stderr: fp"${worker_dir}/container.stderr",
  ))?
  let wall = time.now() - started

  var result = if status.ok { "pass" } else { "fail" }
  var answer = "missing"
  if fs.exists(fp"${work_dir}/answer.txt")? {
    answer = fs.read_text(fp"${work_dir}/answer.txt")?
    if answer.trim() != "hello" {
      result = "fail"
    }
  } else {
    result = "fail"
  }
  let review_ok = check_review(work_dir)?
  if ! review_ok {
    result = "fail"
  }
  let xsh_path = process.which("xsh")?
  let report_status = process.run(process.command_argv(
    xsh_path,
    [xsh_path.display(), fp"${factory_dir}/tools/session-report.xsh", "--", "worker", "--session", session.display(),
      "--output", fp"${worker_dir}/WORKER-REPORT.md".display(), "--role", "eval-worker",
      "--worker-id", f"${eval_id}-${trial_id}", "--budget-usd", "2"],
  ))?
  if ! report_status.ok {
    result = "fail"
  }
  let review_state = if review_ok { "complete" } else { "missing or incomplete" }
  fs.write(fp"${worker_dir}/EXECUTOR-REPORT.md", f"# Executor report\n\n## Result\n\n${result}\n\n## Trial\n\n- Eval: ${eval_id}\n- Trial: ${trial_id}\n- Worker session: `session.jsonl`\n- Wall time: ${wall}\n\n## Artifact\n\n- answer.txt: ${answer.trim()}\n- review.md: ${review_state}\n\n## Evidence\n\nThe eval-worker session, extracted thinking transcript, container logs, and\nworker report are in this directory.\n")?
  print f"hello executor: ${result}"
  abort(if result == "pass" { 0 } else { 1 })
}

proc check_review(work_dir: Path) [fs, error] -> Result[Bool] {
  let review_path = fp"${work_dir}/review.md"
  if ! fs.exists(review_path)? {
    return false
  }
  let text = fs.read_text(review_path)?
  return text.contains("## XSH language proposals") and text.contains("## xsht friction")
}
