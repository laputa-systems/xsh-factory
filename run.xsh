##! Runs one complete Markdown-directed factory cycle.

# A run owns every child process group started by its XSH process. A zero
# pre-cancel budget makes Ctrl-C forward immediately, while the runtime
# cancels and reaps the active group before this hook commits the exit status.
on SIGINT --pre-cancel=0ms [error] {
  abort(130)
}

on SIGTERM --pre-cancel=0ms [error] {
  abort(143)
}

proc main(...argv: List[Str]) [fs, process, env, time, error, io] {
  if argv.len() < 1 {
    eprint "usage: xsh run.xsh CYCLE_REQUEST.md"
    abort(2)
  }
  let factory_dir = env.path("FACTORY_DIR", fs.cwd()?)?
  let request = Path(argv[0])
  let xsh_repo = env.path("FACTORY_XSH_REPO", fp"${factory_dir}/../xsh")?
  let docker = env.get_or("DOCKER", "docker")?
  let platform = env.get_or("FACTORY_PLATFORM", "linux/arm64")?
  let target = env.get_or("XSH_TARGET", "aarch64-unknown-linux-musl")?
  let image = env.get_or("FACTORY_HELLO_IMAGE", "xsh-factory-hello:latest")?
  let home = env.get("HOME")?
  let auth_file = env.path("PI_AUTH_FILE", fp"${home}/.pi/agent/auth.json")?
  let stamp = time.now()
  let run_dir = fp"${factory_dir}/runs/run-${stamp}"
  let worker_root = fp"${run_dir}/workers"
  fs.mkdir(fp"${factory_dir}/runs")?
  fs.mkdir(worker_root)?
  fs.copy(request, fp"${run_dir}/CYCLE-REQUEST.md", overwrite: true)?

  let dist_dir = fp"${xsh_repo}/target/docker-${target}-release/${target}/dist"
  let dist_xsh = fp"${dist_dir}/xsh"
  let dist_xsht = fp"${dist_dir}/xsht"
  if ! fs.exists(dist_xsh)? or ! fs.exists(dist_xsht)? {
    let build = process.run(process.command_argv(
      "make",
      ["make", "-C", xsh_repo.display(), "dist-Linux-docker", f"TARGET=${target}"],
    ))?
    if ! build.ok {
      eprint "unable to build the local XSH distribution"
      abort(build.exit_code() ?? 1)
    }
  }
  let staged_dir = fp"${factory_dir}/evals/hello/.dist"
  fs.mkdir(staged_dir)?
  let stage_xsh = process.run(process.command_argv(
    "cp", ["cp", "-fL", dist_xsh.display(), fp"${staged_dir}/xsh".display()],
  ))?
  let stage_xsht = process.run(process.command_argv(
    "cp", ["cp", "-fL", dist_xsht.display(), fp"${staged_dir}/xsht".display()],
  ))?
  if ! stage_xsh.ok or ! stage_xsht.ok {
    eprint "unable to stage local XSH binaries for the hello image"
    abort(1)
  }
  let image_status = process.run(process.command_argv(
    docker,
    [docker, "build", "--platform", platform, "-t", image,
      "-f", fp"${factory_dir}/evals/hello/Dockerfile".display(),
      fp"${factory_dir}/evals/hello".display()],
  ))?
  if ! image_status.ok {
    eprint "unable to build the hello eval image"
    abort(image_status.exit_code() ?? 1)
  }

  let xsh_path = process.which("xsh")?
  let run_agent = fp"${factory_dir}/run-agent.xsh"
  let director_message = fp"${run_dir}/DIRECTOR-REQUEST.md"
  fs.write(director_message, f"# Director assignment\n\nRead the cycle request at `${run_dir}/CYCLE-REQUEST.md` and run the bounded cycle.\n\nThe active bootstrap eval is hello. Create the message directory, then launch its eval-manager with:\n\n```sh\nFACTORY_ROLE=eval-manager FACTORY_WORKER_ID=hello FACTORY_PARENT_ID=director FACTORY_EVAL_ID=hello xsh \"${run_agent}\" -- eval-manager hello \"${factory_dir}/roles/eval-manager.md\" \"${run_dir}/messages/hello-manager.md\"\n```\n\nThe manager must run the hello executor and write its manager report in `$FACTORY_WORKER_DIR`. If the request asks for a designer, launch it through the same runner after the manager. Do not launch xsh-swe unless an open ticket existed at cycle start. Finish by writing `$FACTORY_RUN_DIR/DIRECTOR-REPORT.md` with the child results and required-output status.\n")?
  fs.mkdir(fp"${run_dir}/messages")?
  fs.write(fp"${run_dir}/messages/hello-manager.md", f"# Hello manager assignment\n\nRun one trial of `${factory_dir}/evals/hello/EVAL.md`. Use the executor as a black box:\n\n```sh\nFACTORY_EVAL_ID=hello FACTORY_TRIAL_ID=1 FACTORY_EVAL_WORKER_DIR=\"$FACTORY_RUN_DIR/workers/eval-worker/hello-1\" FACTORY_HELLO_IMAGE=\"$FACTORY_HELLO_IMAGE\" xsh \"${factory_dir}/evals/hello/executor.xsh\"\n```\n\nThe executor resolves the structured `FACTORY_EVAL_WORKER_*` model settings inherited from the shared runner. Inspect `EXECUTOR-REPORT.md`, `WORKER-REPORT.md`, `thinking.md`, and the task artifact. Write `$FACTORY_WORKER_DIR/MANAGER-REPORT.md` with the result, effort, evidence, and handbook/ticket decision. Do not invent a ticket for a successful trivial run.\n")?

  let director_env = {
    PATH: env.get("PATH")?,
    HOME: env.get("HOME")?,
    FACTORY_DIR: factory_dir.display(),
    FACTORY_RUN_DIR: run_dir.display(),
    FACTORY_RUN_AGENT: run_agent.display(),
    FACTORY_XSH_REPO: xsh_repo.display(),
    FACTORY_HELLO_IMAGE: image,
    FACTORY_PLATFORM: platform,
    PI_AUTH_FILE: auth_file.display(),
    PI_COMMAND: env.get_or("PI_COMMAND", "pi")?,
    FACTORY_DIRECTOR_PROVIDER: env.get_or("FACTORY_DIRECTOR_PROVIDER", "openrouter")?,
    FACTORY_DIRECTOR_MODEL: env.get_or("FACTORY_DIRECTOR_MODEL", "deepseek/deepseek-v4-flash-0731")?,
    FACTORY_DIRECTOR_THINKING: env.get_or("FACTORY_DIRECTOR_THINKING", "high")?,
    FACTORY_DIRECTOR_BUDGET_USD: env.get_or("FACTORY_DIRECTOR_BUDGET_USD", "2")?,
    FACTORY_DIRECTOR_TOOLS: env.get_or("FACTORY_DIRECTOR_TOOLS", "read,write,edit,bash,grep,find,ls")?,
    FACTORY_EVAL_DESIGNER_PROVIDER: env.get_or("FACTORY_EVAL_DESIGNER_PROVIDER", "openrouter")?,
    FACTORY_EVAL_DESIGNER_MODEL: env.get_or("FACTORY_EVAL_DESIGNER_MODEL", "deepseek/deepseek-v4-flash-0731")?,
    FACTORY_EVAL_DESIGNER_THINKING: env.get_or("FACTORY_EVAL_DESIGNER_THINKING", "high")?,
    FACTORY_EVAL_DESIGNER_BUDGET_USD: env.get_or("FACTORY_EVAL_DESIGNER_BUDGET_USD", "2")?,
    FACTORY_EVAL_DESIGNER_TOOLS: env.get_or("FACTORY_EVAL_DESIGNER_TOOLS", "read,write,edit,bash,grep,find,ls")?,
    FACTORY_EVAL_MANAGER_PROVIDER: env.get_or("FACTORY_EVAL_MANAGER_PROVIDER", "openrouter")?,
    FACTORY_EVAL_MANAGER_MODEL: env.get_or("FACTORY_EVAL_MANAGER_MODEL", "deepseek/deepseek-v4-flash-0731")?,
    FACTORY_EVAL_MANAGER_THINKING: env.get_or("FACTORY_EVAL_MANAGER_THINKING", "high")?,
    FACTORY_EVAL_MANAGER_BUDGET_USD: env.get_or("FACTORY_EVAL_MANAGER_BUDGET_USD", "2")?,
    FACTORY_EVAL_MANAGER_TOOLS: env.get_or("FACTORY_EVAL_MANAGER_TOOLS", "read,write,edit,bash,grep,find,ls")?,
    FACTORY_EVAL_WORKER_PROVIDER: env.get_or("FACTORY_EVAL_WORKER_PROVIDER", "openrouter")?,
    FACTORY_EVAL_WORKER_MODEL: env.get_or("FACTORY_EVAL_WORKER_MODEL", "deepseek/deepseek-v4-flash-0731")?,
    FACTORY_EVAL_WORKER_THINKING: env.get_or("FACTORY_EVAL_WORKER_THINKING", "high")?,
    FACTORY_EVAL_WORKER_BUDGET_USD: env.get_or("FACTORY_EVAL_WORKER_BUDGET_USD", "2")?,
    FACTORY_EVAL_WORKER_TOOLS: env.get_or("FACTORY_EVAL_WORKER_TOOLS", "read,write,edit,bash")?,
    FACTORY_XSH_SWE_PROVIDER: env.get_or("FACTORY_XSH_SWE_PROVIDER", "openrouter")?,
    FACTORY_XSH_SWE_MODEL: env.get_or("FACTORY_XSH_SWE_MODEL", "deepseek/deepseek-v4-flash-0731")?,
    FACTORY_XSH_SWE_THINKING: env.get_or("FACTORY_XSH_SWE_THINKING", "high")?,
    FACTORY_XSH_SWE_BUDGET_USD: env.get_or("FACTORY_XSH_SWE_BUDGET_USD", "2")?,
    FACTORY_XSH_SWE_TOOLS: env.get_or("FACTORY_XSH_SWE_TOOLS", "read,write,edit,bash,grep,find,ls")?,
  }
  let director_status = process.run(process.command_argv(
    xsh_path,
    [xsh_path.display(), run_agent, "--", "director", "director",
      fp"${factory_dir}/roles/director.md".display(), director_message.display()],
    env: director_env,
  ))?

  let cost_status = process.run(process.command_argv(
    xsh_path,
    [xsh_path.display(), fp"${factory_dir}/tools/session-report.xsh", "--", "run", "--run-dir", run_dir.display(),
      "--output", fp"${run_dir}/COST.md".display()],
  ))?
  let director_session = fp"${run_dir}/workers/director/director/session.jsonl"
  let manager_session = fp"${run_dir}/workers/eval-manager/hello/session.jsonl"
  let worker_report = fp"${run_dir}/workers/eval-worker/hello-1/EXECUTOR-REPORT.md"
  let required = fs.exists(director_session)? and fs.exists(manager_session)? and fs.exists(worker_report)? and cost_status.ok
  let result = if director_status.ok and required { "pass" } else { "fail" }
  let director_state = if fs.exists(director_session)? { "present" } else { "missing" }
  let manager_state = if fs.exists(manager_session)? { "present" } else { "missing" }
  let worker_state = if fs.exists(worker_report)? { "present" } else { "missing" }
  let cost_state = if cost_status.ok { "present" } else { "failed" }
  let run_report = f"# Factory run ${stamp}\n\n## Result\n\n${result}\n\n## Cycle\n\n- Request: `CYCLE-REQUEST.md`\n- XSH repository: `${xsh_repo.display()}`\n- Platform: `${platform}`\n- Hello image: `${image}`\n\n## Required outputs\n\n- Director session: `${director_state}`\n- Hello manager session: `${manager_state}`\n- Hello executor report: `${worker_state}`\n- Cost report: `${cost_state}`\n\n## Evidence\n\nAll Pi sessions, extracted thinking transcripts, worker reports, container logs,\nand evaluator artifacts are under `workers/`. See `COST.md` for per-worker,\nper-role, and total accounting.\n"
  fs.write(fp"${run_dir}/RUN.md", run_report)?
  print f"factory run: ${run_dir} (${result})"
  abort(if result == "pass" { 0 } else { 1 })
}
