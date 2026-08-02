##! Shared Pi worker runner. Every factory Pi session goes through this file.

pure role_prefix(role: Str) -> Str {
  if role == "director" { return "DIRECTOR" }
  if role == "eval-designer" { return "EVAL_DESIGNER" }
  if role == "eval-manager" { return "EVAL_MANAGER" }
  if role == "eval-worker" { return "EVAL_WORKER" }
  if role == "xsh-swe" { return "XSH_SWE" }
  return ""
}

pure default_provider(role: Str) -> Str {
  if role == "director" { return "openrouter" }
  if role == "eval-designer" { return "openrouter" }
  if role == "eval-manager" { return "openrouter" }
  if role == "eval-worker" { return "openrouter" }
  if role == "xsh-swe" { return "openrouter" }
  return ""
}

pure default_model(role: Str) -> Str {
  if role == "director" { return "deepseek/deepseek-v4-flash-0731" }
  if role == "eval-designer" { return "deepseek/deepseek-v4-flash-0731" }
  if role == "eval-manager" { return "deepseek/deepseek-v4-flash-0731" }
  if role == "eval-worker" { return "deepseek/deepseek-v4-flash-0731" }
  if role == "xsh-swe" { return "deepseek/deepseek-v4-flash-0731" }
  return ""
}

pure default_thinking(role: Str) -> Str {
  if role == "director" { return "high" }
  if role == "eval-designer" { return "high" }
  if role == "eval-manager" { return "high" }
  if role == "eval-worker" { return "high" }
  if role == "xsh-swe" { return "high" }
  return ""
}

pure default_budget(role: Str) -> Str {
  if role == "director" { return "2" }
  if role == "eval-designer" { return "2" }
  if role == "eval-manager" { return "2" }
  if role == "eval-worker" { return "2" }
  if role == "xsh-swe" { return "2" }
  return ""
}

pure default_tools(role: Str) -> Str {
  if role == "eval-worker" { return "read,write,edit,bash" }
  if role == "director" { return "read,write,edit,bash,grep,find,ls" }
  if role == "eval-designer" { return "read,write,edit,bash,grep,find,ls" }
  if role == "eval-manager" { return "read,write,edit,bash,grep,find,ls" }
  if role == "xsh-swe" { return "read,write,edit,bash,grep,find,ls" }
  return ""
}

proc role_setting(role: Str, key: Str, fallback: Str) [env, error] -> Result[Str] {
  let name = f"FACTORY_${role_prefix(role)}_${key}"
  return env.get_or(name, fallback)
}

proc main(...argv: List[Str]) [fs, process, env, time, error, io] {
  if argv.len() < 4 {
    eprint "usage: run-agent.xsh -- ROLE WORKER_ID SYSTEM_PROMPT MESSAGE_FILE"
    abort(2)
  }
  let role = argv[0]
  let prefix = role_prefix(role)
  if prefix == "" {
    eprint f"unknown Pi role: ${role}"
    abort(2)
  }
  let worker_id = argv[1]
  let system_prompt = Path(argv[2])
  let message_file = Path(argv[3])
  let factory_dir = env.path("FACTORY_DIR")?
  let run_dir = env.path("FACTORY_RUN_DIR")?
  let worker_dir = fp"${run_dir}/workers/${role}/${worker_id}"
  let session = fp"${worker_dir}/session.jsonl"
  let report = fp"${worker_dir}/WORKER-REPORT.md"
  let budget = role_setting(role, "BUDGET_USD", default_budget(role))?
  let provider = role_setting(role, "PROVIDER", default_provider(role))?
  let model = role_setting(role, "MODEL", default_model(role))?
  let thinking = role_setting(role, "THINKING", default_thinking(role))?
  let pi_command = env.get_or("PI_COMMAND", "pi")?
  let xsh_path = process.which("xsh")?
  let pi_path = process.which(pi_command)?
  let _ = pi_path
  let parent = env.get_or("FACTORY_PARENT_ID", "unknown")?
  let eval_id = env.get_or("FACTORY_EVAL_ID", "")?
  let ticket_id = env.get_or("FACTORY_TICKET_ID", "")?
  let tools = role_setting(role, "TOOLS", default_tools(role))?
  fs.mkdir(worker_dir)?
  fs.write(fp"${worker_dir}/WORKER.md", f"# Worker\n\n- Role: `${role}`\n- Worker: `${worker_id}`\n- Parent: `${parent}`\n- Eval: `${eval_id}`\n- Ticket: `${ticket_id}`\n- Provider: `${provider}`\n- Model: `${model}`\n- Thinking: `${thinking}`\n- Budget: `${budget}`\n")?

  let pi_argv = [
    pi_command,
    "--provider", provider,
    "--model", model,
    "--thinking", thinking,
    "--approve",
    "--system-prompt", system_prompt.display(),
    "--no-extensions",
    "--no-skills",
    "--no-prompt-templates",
    "--no-themes",
    "--no-context-files",
    "--tools", tools,
    "--session", session.display(),
    "--print",
    f"@${message_file.display()}",
  ]
  let child_env = {
    PATH: env.get("PATH")?,
    HOME: env.get("HOME")?,
    FACTORY_DIR: factory_dir.display(),
    FACTORY_RUN_DIR: run_dir.display(),
    FACTORY_RUN_AGENT: env.get("FACTORY_RUN_AGENT")?,
    FACTORY_WORKER_DIR: worker_dir.display(),
    FACTORY_ROLE: role,
    FACTORY_WORKER_ID: worker_id,
    FACTORY_PARENT_ID: parent,
    FACTORY_EVAL_ID: eval_id,
    FACTORY_TICKET_ID: ticket_id,
    FACTORY_XSH_REPO: env.get("FACTORY_XSH_REPO")?,
    FACTORY_HELLO_IMAGE: env.get_or("FACTORY_HELLO_IMAGE", "xsh-factory-hello:latest")?,
    FACTORY_PLATFORM: env.get_or("FACTORY_PLATFORM", "linux/arm64")?,
    FACTORY_DIRECTOR_PROVIDER: role_setting("director", "PROVIDER", default_provider("director"))?,
    FACTORY_DIRECTOR_MODEL: role_setting("director", "MODEL", default_model("director"))?,
    FACTORY_DIRECTOR_THINKING: role_setting("director", "THINKING", default_thinking("director"))?,
    FACTORY_DIRECTOR_BUDGET_USD: role_setting("director", "BUDGET_USD", default_budget("director"))?,
    FACTORY_DIRECTOR_TOOLS: role_setting("director", "TOOLS", default_tools("director"))?,
    FACTORY_EVAL_DESIGNER_PROVIDER: role_setting("eval-designer", "PROVIDER", default_provider("eval-designer"))?,
    FACTORY_EVAL_DESIGNER_MODEL: role_setting("eval-designer", "MODEL", default_model("eval-designer"))?,
    FACTORY_EVAL_DESIGNER_THINKING: role_setting("eval-designer", "THINKING", default_thinking("eval-designer"))?,
    FACTORY_EVAL_DESIGNER_BUDGET_USD: role_setting("eval-designer", "BUDGET_USD", default_budget("eval-designer"))?,
    FACTORY_EVAL_DESIGNER_TOOLS: role_setting("eval-designer", "TOOLS", default_tools("eval-designer"))?,
    FACTORY_EVAL_MANAGER_PROVIDER: role_setting("eval-manager", "PROVIDER", default_provider("eval-manager"))?,
    FACTORY_EVAL_MANAGER_MODEL: role_setting("eval-manager", "MODEL", default_model("eval-manager"))?,
    FACTORY_EVAL_MANAGER_THINKING: role_setting("eval-manager", "THINKING", default_thinking("eval-manager"))?,
    FACTORY_EVAL_MANAGER_BUDGET_USD: role_setting("eval-manager", "BUDGET_USD", default_budget("eval-manager"))?,
    FACTORY_EVAL_MANAGER_TOOLS: role_setting("eval-manager", "TOOLS", default_tools("eval-manager"))?,
    FACTORY_EVAL_WORKER_PROVIDER: role_setting("eval-worker", "PROVIDER", default_provider("eval-worker"))?,
    FACTORY_EVAL_WORKER_MODEL: role_setting("eval-worker", "MODEL", default_model("eval-worker"))?,
    FACTORY_EVAL_WORKER_THINKING: role_setting("eval-worker", "THINKING", default_thinking("eval-worker"))?,
    FACTORY_EVAL_WORKER_BUDGET_USD: role_setting("eval-worker", "BUDGET_USD", default_budget("eval-worker"))?,
    FACTORY_EVAL_WORKER_TOOLS: role_setting("eval-worker", "TOOLS", default_tools("eval-worker"))?,
    FACTORY_XSH_SWE_PROVIDER: role_setting("xsh-swe", "PROVIDER", default_provider("xsh-swe"))?,
    FACTORY_XSH_SWE_MODEL: role_setting("xsh-swe", "MODEL", default_model("xsh-swe"))?,
    FACTORY_XSH_SWE_THINKING: role_setting("xsh-swe", "THINKING", default_thinking("xsh-swe"))?,
    FACTORY_XSH_SWE_BUDGET_USD: role_setting("xsh-swe", "BUDGET_USD", default_budget("xsh-swe"))?,
    FACTORY_XSH_SWE_TOOLS: role_setting("xsh-swe", "TOOLS", default_tools("xsh-swe"))?,
    PI_AUTH_FILE: env.get("PI_AUTH_FILE")?,
    PI_COMMAND: pi_command,
  }
  let handle = spawn process.command_argv(
    pi_command,
    pi_argv,
    env: child_env,
    stdout: fp"${worker_dir}/stdout.log",
    stderr: fp"${worker_dir}/stderr.log",
  )?
  let watcher = spawn process.command_argv(
    xsh_path,
    [xsh_path.display(), fp"${factory_dir}/tools/budget-watch.xsh", "--",
      "--session", session.display(), "--pid", f"${handle.pid}",
      "--budget-usd", budget, "--marker", fp"${worker_dir}/BUDGET-BREACH".display()],
  )?
  let status = wait handle?
  let watcher_status = wait watcher?
  if fs.exists(session)? {
    let _ = process.run(process.command_argv(
      pi_command,
      [pi_command, "--export", session.display(), session.with_ext("html").display()],
    ))?
  }
  let report_status = process.run(process.command_argv(
    xsh_path,
    [xsh_path.display(), fp"${factory_dir}/tools/session-report.xsh", "--", "worker",
      "--session", session.display(), "--output", report.display(), "--role", role,
      "--worker-id", worker_id, "--budget-usd", budget],
  ))?
  let code = if ! status.ok or ! watcher_status.ok or ! report_status.ok { 1 } else { 0 }
  abort(code)
}
