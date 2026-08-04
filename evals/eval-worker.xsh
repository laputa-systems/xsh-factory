##! Shared Pi eval-worker entry point used by every eval image.

proc main(...argv: List[Str]) [fs, process, env, time, error, io] {
  let session = Path(argv[0])
  let task_path = Path(argv[1])
  let agent_dir = env.path("PI_CODING_AGENT_DIR", p"/run/pi-agent")?
  fs.mkdir(agent_dir)?
  fs.copy(p"/run/pi-auth.json", fp"${agent_dir}/auth.json", overwrite: true)?
  fs.chmod(fp"${agent_dir}/auth.json", 0o600)?

  let pi_command = env.get_or("PI_COMMAND", "pi")?
  let pi_provider = env.get_or("PI_PROVIDER", "openrouter")?
  let pi_model = env.get_or("PI_MODEL", "deepseek/deepseek-v4-flash-0731")?
  let pi_thinking = env.get_or("PI_THINKING", "high")?
  let pi_tools = env.get_or("PI_TOOLS", "read,write,edit,bash")?
  let pi = process.which(pi_command)?
  let _ = pi

  fs.write(session, "")?
  let prompt = f"Before coding, read /work/agents.md and /work/handbook.md with the read tool. Complete ${task_path.name()} in /work. Run the required checks and leave the requested artifact and review.md there."
  let pi_argv = [
    pi_command,
    "--provider", pi_provider,
    "--model", pi_model,
    "--thinking", pi_thinking,
    "--approve",
    "--system-prompt", "/work/agents.md",
    "--no-extensions",
    "--no-skills",
    "--no-prompt-templates",
    "--no-themes",
    "--no-context-files",
    "--tools", pi_tools,
    "--session", session.display(),
    "--print",
    f"@${task_path.display()}",
    prompt,
  ]
  let handle = spawn process.command_argv(pi_command, pi_argv)?
  let tail = spawn run tail -f ${session.display()} ?
  let status = wait handle?
  time.sleep(200ms)?
  tail.cancel(signal: "TERM", kill_after: 100ms)?

  abort(if status.ok { 0 } else { status.exit_code() ?? 1 })
}
