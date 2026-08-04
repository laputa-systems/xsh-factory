##! Shared Pi worker runner. Every factory Pi session goes through this file.

use factory_control as control
use factory_runtime as runtime

proc main(...argv: List[Str]) [fs, process, env, time, error, io] {
  if argv.len() < 4 {
    eprint "usage: run-agent.xsh -- ROLE WORKER_ID SYSTEM_PROMPT MESSAGE_FILE"
    abort(2)
  }
  let role = argv[0]
  let prefix = control.role_prefix(role)
  if prefix == "" {
    eprint f"unknown Pi role: ${role}"
    abort(2)
  }
  let worker_id = argv[1]
  let system_prompt = Path(argv[2])
  let message_file = Path(argv[3])
  let factory_dir = env.path("FACTORY_DIR")?
  let run_dir = env.path("FACTORY_RUN_DIR")?
  let handbook_file = env.path("FACTORY_HANDBOOK_FILE", fp"${factory_dir}/runtime/handbook.md")?
  let north_star_file = env.path("FACTORY_NORTH_STAR_FILE", fp"${factory_dir}/NORTH-STAR.md")?
  let worker_dir = fp"${run_dir}/workers/${role}/${worker_id}"
  let process_registry = fp"${run_dir}/processes"
  let process_registry_file = fp"${process_registry}/${role}-${worker_id}.pids"
  let session = fp"${worker_dir}/session.jsonl"
  let report = fp"${worker_dir}/report.json"
  let default_required_report = fp"${worker_dir}/REPORT.md".display()
  let required_report = env.get_or("FACTORY_REQUIRED_REPORT", default_required_report)?
  let configured_workdir = env.get_or("FACTORY_WORKDIR", "")?
  let workdir = if configured_workdir == "" { fs.cwd()? } else { Path(configured_workdir) }
  let budget = control.configured_role_setting(role, "BUDGET_USD")?
  let max_turns = control.configured_role_setting(role, "MAX_TURNS")?
  let max_wall_seconds = control.configured_role_setting(role, "MAX_WALL_SECONDS")?
  let provider = control.configured_role_setting(role, "PROVIDER")?
  let model = control.configured_role_setting(role, "MODEL")?
  let thinking = control.configured_role_setting(role, "THINKING")?
  let pi_command = env.get_or("PI_COMMAND", "pi")?
  let xsh_path = process.which("xsh")?
  let pi_path = process.which(pi_command)?
  let _ = pi_path
  let self_pid = process.current_pid()?
  let parent = env.get_or("FACTORY_PARENT_ID", "unknown")?
  let mode = env.get_or("FACTORY_MODE", "")?
  let eval_id = env.get_or("FACTORY_EVAL_ID", "")?
  let ticket_id = env.get_or("FACTORY_TICKET_ID", "")?
  let assignment_sha = env.get_or("FACTORY_ASSIGNMENT_SHA", "")?
  let tools = control.configured_role_setting(role, "TOOLS")?
  if role == "engineer" {
    if worker_id != ticket_id or assignment_sha == "" or ! fs.exists(message_file)? {
      eprint "engineer dispatch is missing its controller assignment identity"
      abort(2)
    }
    let assignment = fs.read_text(message_file)?
    let actual_assignment_sha = hash.sha256(message_file)?.hex()
    if actual_assignment_sha != assignment_sha or ! control.engineer_assignment_ok(
      run_dir.display(), ticket_id, message_file.display(), workdir.display(), assignment
    ) {
      eprint "engineer dispatch does not match the controller assignment"
      abort(2)
    }
  }
  fs.mkdir(fp"${run_dir}/locks")?
  let claim_lock = fs.lock(fp"${run_dir}/locks/${role}-${worker_id}.lock", nonblocking: true)?
  let claim_file = fp"${run_dir}/locks/${role}-${worker_id}.claimed"
  if fs.exists(claim_file)? {
    eprint f"worker slot already claimed: ${role}/${worker_id}"
    abort(2)
  }
  fs.write_atomic(claim_file, f"${self_pid}\n${assignment_sha}\n")?
  fs.mkdir(process_registry)?
  fs.write(process_registry_file, f"${self_pid}\n")?
  fs.mkdir(worker_dir)?
  if required_report != "" and ! fs.exists(Path(required_report))? {
    if role == "eval-manager" {
      fs.copy(fp"${factory_dir}/templates/EVAL-MANAGER-REPORT.md", Path(required_report), overwrite: false)?
    } else if role == "director" {
      fs.copy(fp"${factory_dir}/templates/DIRECTOR-REPORT.md", Path(required_report), overwrite: false)?
    } else if role == "engineer" {
      fs.copy(fp"${factory_dir}/templates/ENGINEER-REPORT.md", Path(required_report), overwrite: false)?
    }
  }
  let worker_template = fp"${factory_dir}/templates/WORKER.md"
  let worker_values: List[control.TemplateValue] = [
    {key: "ROLE", value: role},
    {key: "WORKER_ID", value: worker_id},
    {key: "PARENT_ID", value: parent},
    {key: "MODE", value: mode},
    {key: "EVAL_ID", value: eval_id},
    {key: "TICKET_ID", value: ticket_id},
    {key: "ASSIGNMENT_SHA", value: assignment_sha},
    {key: "WORKDIR", value: workdir.display()},
    {key: "NORTH_STAR_FILE", value: north_star_file.display()},
    {key: "HANDBOOK_FILE", value: handbook_file.display()},
    {key: "PROVIDER", value: provider},
    {key: "MODEL", value: model},
    {key: "THINKING", value: thinking},
    {key: "BUDGET", value: budget},
    {key: "MAX_TURNS", value: max_turns},
    {key: "MAX_WALL_SECONDS", value: max_wall_seconds},
    {key: "REQUIRED_REPORT", value: required_report},
  ]
  fs.write(fp"${worker_dir}/WORKER.md", control.fill_template(worker_template.read_text()?, worker_values))?

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
    XSH_MODULE_PATH: env.get_or("XSH_MODULE_PATH", factory_dir.display())?,
    FACTORY_DIR: factory_dir.display(),
    FACTORY_RUN_DIR: run_dir.display(),
    FACTORY_RUN_AGENT: env.get("FACTORY_RUN_AGENT")?,
    FACTORY_WORKER_DIR: worker_dir.display(),
    FACTORY_ROLE: role,
    FACTORY_WORKER_ID: worker_id,
    FACTORY_PARENT_ID: parent,
    FACTORY_MODE: mode,
    FACTORY_EVAL_ID: eval_id,
    FACTORY_TICKET_ID: ticket_id,
    FACTORY_ASSIGNMENT_SHA: assignment_sha,
    FACTORY_WORKDIR: workdir.display(),
    FACTORY_HANDBOOK_FILE: handbook_file.display(),
    FACTORY_NORTH_STAR_FILE: north_star_file.display(),
    FACTORY_XSH_REPO: env.get("FACTORY_XSH_REPO")?,
    FACTORY_XSH_COMMIT: env.get_or("FACTORY_XSH_COMMIT", "unknown")?,
    FACTORY_IMAGE_ID: env.get_or("FACTORY_IMAGE_ID", "unknown")?,
    FACTORY_EVAL_DIR: env.get_or("FACTORY_EVAL_DIR", "")?,
    FACTORY_EVAL_IMAGE: env.get_or("FACTORY_EVAL_IMAGE", "")?,
    FACTORY_EVAL_TASK_FILE: env.get_or("FACTORY_EVAL_TASK_FILE", "")?,
    FACTORY_EVAL_ARTIFACT: env.get_or("FACTORY_EVAL_ARTIFACT", "")?,
    FACTORY_LINEAGE_DIR: env.get_or("FACTORY_LINEAGE_DIR", "")?,
    FACTORY_PLATFORM: env.get_or("FACTORY_PLATFORM", "linux/arm64")?,
    FACTORY_DIRECTOR_PROVIDER: control.configured_role_setting("director", "PROVIDER")?,
    FACTORY_DIRECTOR_MODEL: control.configured_role_setting("director", "MODEL")?,
    FACTORY_DIRECTOR_THINKING: control.configured_role_setting("director", "THINKING")?,
    FACTORY_DIRECTOR_BUDGET_USD: control.configured_role_setting("director", "BUDGET_USD")?,
    FACTORY_DIRECTOR_TOOLS: control.configured_role_setting("director", "TOOLS")?,
    FACTORY_EVAL_DESIGNER_PROVIDER: control.configured_role_setting("eval-designer", "PROVIDER")?,
    FACTORY_EVAL_DESIGNER_MODEL: control.configured_role_setting("eval-designer", "MODEL")?,
    FACTORY_EVAL_DESIGNER_THINKING: control.configured_role_setting("eval-designer", "THINKING")?,
    FACTORY_EVAL_DESIGNER_BUDGET_USD: control.configured_role_setting("eval-designer", "BUDGET_USD")?,
    FACTORY_EVAL_DESIGNER_TOOLS: control.configured_role_setting("eval-designer", "TOOLS")?,
    FACTORY_EVAL_MANAGER_PROVIDER: control.configured_role_setting("eval-manager", "PROVIDER")?,
    FACTORY_EVAL_MANAGER_MODEL: control.configured_role_setting("eval-manager", "MODEL")?,
    FACTORY_EVAL_MANAGER_THINKING: control.configured_role_setting("eval-manager", "THINKING")?,
    FACTORY_EVAL_MANAGER_BUDGET_USD: control.configured_role_setting("eval-manager", "BUDGET_USD")?,
    FACTORY_EVAL_MANAGER_TOOLS: control.configured_role_setting("eval-manager", "TOOLS")?,
    FACTORY_EVAL_WORKER_PROVIDER: control.configured_role_setting("eval-worker", "PROVIDER")?,
    FACTORY_EVAL_WORKER_MODEL: control.configured_role_setting("eval-worker", "MODEL")?,
    FACTORY_EVAL_WORKER_THINKING: control.configured_role_setting("eval-worker", "THINKING")?,
    FACTORY_EVAL_WORKER_BUDGET_USD: control.configured_role_setting("eval-worker", "BUDGET_USD")?,
    FACTORY_EVAL_WORKER_TOOLS: control.configured_role_setting("eval-worker", "TOOLS")?,
    FACTORY_ENGINEER_PROVIDER: control.configured_role_setting("engineer", "PROVIDER")?,
    FACTORY_ENGINEER_MODEL: control.configured_role_setting("engineer", "MODEL")?,
    FACTORY_ENGINEER_THINKING: control.configured_role_setting("engineer", "THINKING")?,
    FACTORY_ENGINEER_BUDGET_USD: control.configured_role_setting("engineer", "BUDGET_USD")?,
    FACTORY_ENGINEER_TOOLS: control.configured_role_setting("engineer", "TOOLS")?,
    FACTORY_DIRECTOR_MAX_TURNS: control.configured_role_setting("director", "MAX_TURNS")?,
    FACTORY_DIRECTOR_MAX_WALL_SECONDS: control.configured_role_setting("director", "MAX_WALL_SECONDS")?,
    FACTORY_EVAL_DESIGNER_MAX_TURNS: control.configured_role_setting("eval-designer", "MAX_TURNS")?,
    FACTORY_EVAL_DESIGNER_MAX_WALL_SECONDS: control.configured_role_setting("eval-designer", "MAX_WALL_SECONDS")?,
    FACTORY_EVAL_MANAGER_MAX_TURNS: control.configured_role_setting("eval-manager", "MAX_TURNS")?,
    FACTORY_EVAL_MANAGER_MAX_WALL_SECONDS: control.configured_role_setting("eval-manager", "MAX_WALL_SECONDS")?,
    FACTORY_EVAL_WORKER_MAX_TURNS: control.configured_role_setting("eval-worker", "MAX_TURNS")?,
    FACTORY_EVAL_WORKER_MAX_WALL_SECONDS: control.configured_role_setting("eval-worker", "MAX_WALL_SECONDS")?,
    FACTORY_ENGINEER_MAX_TURNS: control.configured_role_setting("engineer", "MAX_TURNS")?,
    FACTORY_ENGINEER_MAX_WALL_SECONDS: control.configured_role_setting("engineer", "MAX_WALL_SECONDS")?,
    PI_AUTH_FILE: env.get("PI_AUTH_FILE")?,
    PI_COMMAND: pi_command,
  }
  let handle = spawn process.command_argv(
    pi_command,
    pi_argv,
    cwd: workdir,
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
  let limit_watcher = spawn process.command_argv(
    xsh_path,
    [xsh_path.display(), fp"${factory_dir}/tools/session-watch.xsh", "--",
      "--session", session.display(), "--pid", f"${handle.pid}",
      "--max-turns", max_turns, "--max-seconds", max_wall_seconds,
      "--marker", fp"${worker_dir}/SESSION-LIMIT".display(), "--role", role],
  )?
  fs.write(process_registry_file, f"${self_pid}\n${handle.pid}\n${watcher.pid}\n${limit_watcher.pid}\n")?
  let status = wait handle?
  let watcher_status = wait watcher?
  let limit_status = wait limit_watcher?
  let report_status = process.run(process.command_argv(
    xsh_path,
    [xsh_path.display(), fp"${factory_dir}/tools/session-report.xsh", "--", "worker",
      "--session", session.display(), "--output", report.display(), "--role", role,
      "--worker-id", worker_id, "--budget-usd", budget],
  ))?
  if required_report != "" and ! fs.exists(Path(required_report))? {
    fs.write(fp"${worker_dir}/REPORT-MISSING", f"required report missing: ${required_report}\n")?
  }
  let required_report_ok = required_report == "" or fs.exists(Path(required_report))?
  if fs.exists(report)? {
    let worker_report = json.read(report)?
    let enriched = json.set(worker_report, ["execution"], {
      agent_process: if status.ok { "pass" } else { "nonzero-exit" },
      watcher: if watcher_status.ok { "pass" } else { "failed" },
      session_limit_watcher: if limit_status.ok { "pass" } else { "failed" },
      reporting: if report_status.ok { "pass" } else { "failed" },
      required_report: if required_report_ok { "present" } else { "missing" },
    })?
    json.write(report, enriched, pretty: true)?
  }
  let budget_breach = fs.exists(fp"${worker_dir}/BUDGET-BREACH")?
  if budget_breach and role == "engineer" {
    let closed = runtime.close_ticket_too_difficult(factory_dir, ticket_id, worker_dir)?
    if ! closed {
      eprint f"unable to close over-budget ticket: ${ticket_id}"
    }
  }
  let code = if control.agent_completion_ok(
    watcher_status.ok, limit_status.ok, report_status.ok, required_report_ok
  ) { 0 } else { 1 }
  abort(code)
}
