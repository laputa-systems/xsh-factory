##! Dispatches one complete factory cycle from a checked-in request.

use factory_control as control
use factory_runtime as runtime

on SIGINT --pre-cancel=0ms [fs, process, env, error] {
  runtime.cleanup_active_run()?
  abort(130)
}

on SIGTERM --pre-cancel=0ms [fs, process, env, error] {
  runtime.cleanup_active_run()?
  abort(143)
}

proc preflight(
  factory_dir: Path,
  xsh_repo: Path,
  request: Path,
  request_text: Str,
  mode: Str,
) [fs, process, env, error, io] -> Result[Bool] {
  if ! fs.exists(request)? {
    eprint f"cycle request does not exist: ${request.display()}"
    return false
  }
  if ! fs.exists(xsh_repo)? {
    eprint f"XSH repository does not exist: ${xsh_repo.display()}"
    return false
  }
  for required in [
    "NORTH-STAR.md",
    "runtime/handbook.md",
    "run-agent.xsh",
    "run-ticket-reuse.xsh",
    "factory_control.xsh",
    "factory_runtime.xsh",
    "factory_report.xsh",
    "report_schema.xsh",
    "audit-run.xsh",
    "tools/cleanup-run.xsh",
    "tools/cycle-budget-watch.xsh",
    "tools/session-watch.xsh",
    "tools/cto-report.xsh",
    "templates/POSTMORTEM.md",
    "templates/CTO-REPORT.md",
    "templates/CTO-EVAL-REVIEW.md",
    "templates/CTO-EMPLOYEE.md",
    "templates/CTO-PHASE.md",
    "templates/CTO-WORKER.md",
    "templates/CTO-TOOL-ERROR.md",
    "templates/CTO-TOTAL.md",
    "templates/CTO-IMPROVEMENT.md",
  ] {
    if ! fs.exists(fp"${factory_dir}/${required}")? {
      eprint f"factory prerequisite is missing: ${factory_dir}/${required}"
      return false
    }
  }
  let xsh_status = run.text "git" "-C" $xsh_repo.display() "status" "--porcelain" ?
  if xsh_status.trim() != "" {
    eprint f"XSH repository must be clean before ${mode} admission: ${xsh_repo.display()}"
    return false
  }
  let runs_dir = fp"${factory_dir}/runs"
  let active_run = fp"${runs_dir}/ACTIVE"
  let organization_run = fp"${runs_dir}/ORGANIZATION-ACTIVE"
  if fs.exists(active_run)? or fs.exists(organization_run)? {
    eprint "another factory run is already active"
    return false
  }

  let requested_tickets = control.request_tickets(request_text)
  let candidate_tickets = if requested_tickets.len() > 0 {
    requested_tickets
  } else if mode == "organization" and control.request_ticket_policy(request_text) != "none" {
    runtime.first_approved_tickets(factory_dir, control.max_concurrent_engineers())?
  } else {
    []
  }
  if candidate_tickets.len() > control.max_concurrent_engineers() {
    eprint f"cycle admits at most ${control.max_concurrent_engineers()} tickets"
    return false
  }
  for candidate_ticket in candidate_tickets {
    if ! control.valid_ticket_id(candidate_ticket) {
      eprint f"unsafe ticket id: ${candidate_ticket}"
      return false
    }
    let ticket_path = fp"${factory_dir}/tickets/${candidate_ticket}.md"
    if fs.exists(ticket_path)? and runtime.accepted_ticket(ticket_path)? {
      let open_branch = runtime.open_ticket_branch(xsh_repo, candidate_ticket)?
      if open_branch != "" and mode != "organization" {
        eprint f"ticket ${candidate_ticket} already has an unmerged implementation branch: ${open_branch}"
        eprint "replay or review that branch before dispatching another engineer"
        return false
      }
    }
  }

  let home = env.get("HOME")?
  if env.get_or("FACTORY_SKIP_CYCLE_BUDGET", "false")? == "true" {
    eprint "top-level dispatcher cannot disable the aggregate cycle budget"
    return false
  }
  let requested_cycle_budget = env.get_or("FACTORY_CYCLE_BUDGET_USD", control.default_cycle_budget())?
  let _cycle_budget = control.clamp_cycle_budget(requested_cycle_budget)?
  let auth_file = env.path("PI_AUTH_FILE", fp"${home}/.pi/agent/auth.json")?
  if ! fs.exists(auth_file)? {
    eprint f"Pi auth file does not exist: ${auth_file.display()}"
    return false
  }
  let pi_command = env.get_or("PI_COMMAND", "pi")?
  let _pi_path = process.which(pi_command)?
  let _xsh_path = process.which("xsh")?
  let requires_eval_runtime = mode == "eval" or mode == "organization"
  if requires_eval_runtime {
    let _make_path = process.which("make")?
    let docker_command = env.get_or("DOCKER", "docker")?
    let _docker_path = process.which(docker_command)?
    let docker_status = process.run(process.command_argv(
      docker_command,
      [docker_command, "info", "--format", "{{.ServerVersion}}"],
    ))?
    if ! docker_status.ok {
      eprint "Docker daemon preflight failed"
      return false
    }
  }

  if mode == "eval" or mode == "organization" or mode == "eval-design" {
    let eval_id = control.request_eval(request_text)
    let eval_path = fp"${factory_dir}/evals/${eval_id}/EVAL.md"
    let eval_exists = fs.exists(eval_path)?
    let eval_disabled = eval_exists and control.eval_is_disabled(eval_path.read_text()?)
    if ! control.valid_eval_id(eval_id) or ! eval_exists or eval_disabled {
      eprint f"cycle request selected unsupported or missing eval: ${eval_id}"
      return false
    }
  }
  if mode == "eval" or mode == "organization" {
    let trial_count = control.request_trial_count(request_text)?
    if trial_count < 1 or trial_count > 2 {
      eprint f"unsupported trial count: ${trial_count} (expected 1 or 2)"
      return false
    }
  }
  if mode == "eval-design" {
    let new_eval_count = control.request_new_eval_count(request_text)?
    if new_eval_count != 1 {
      eprint f"${mode} requires exactly one eval-design proposal"
      return false
    }
  } else if mode == "organization" {
    let new_eval_count = control.request_new_eval_count(request_text)?
    if new_eval_count < 0 or new_eval_count > 1 {
      eprint "organization cycles allow zero or one eval-design proposal"
      return false
    }
  }
  return true
}

proc main(...argv: List[Str]) [fs, process, env, time, error, io] {
  if argv.len() < 1 {
    eprint "usage: xsh run.xsh CYCLE_REQUEST.md [EVAL_ID]"
    abort(2)
  }
  let factory_dir = env.path("FACTORY_DIR", fs.cwd()?)?
  let request = Path(argv[0])
  if ! fs.exists(request)? {
    eprint f"cycle request does not exist: ${request.display()}"
    abort(2)
  }
  let request_text = request.read_text()?
  let mode = control.request_mode(request_text)
  if mode != "ticket-implementation" and mode != "eval" and
    mode != "organization" and mode != "eval-design" {
    eprint f"unsupported cycle mode: ${mode}"
    abort(2)
  }
  let xsh_repo = env.path("FACTORY_XSH_REPO", fp"${factory_dir}/../xsh")?
  if ! preflight(factory_dir, xsh_repo, request, request_text, mode)? {
    abort(1)
  }
  let child = if mode == "ticket-implementation" {
    fp"${factory_dir}/run-ticket.xsh"
  } else if mode == "eval" {
    fp"${factory_dir}/run-eval.xsh"
  } else if mode == "organization" {
    fp"${factory_dir}/run-organization.xsh"
  } else {
    fp"${factory_dir}/run-design.xsh"
  }
  let xsh_path = process.which("xsh")?
  let status = process.run(process.command_argv(
    xsh_path,
    [xsh_path.display(), child.display(), "--"].extend(argv),
    cwd: factory_dir,
  ))?
  abort(if status.ok { 0 } else { status.exit_code() ?? 1 })
}
