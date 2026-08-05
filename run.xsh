##! Dispatches one complete factory cycle from a checked-in request.

use factory.control as control
use factory.runtime as runtime
use factory.request as typed_request
use factory.types as typed_types

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
  let parsed_mode = typed_request.mode_value(request_text)
  match parsed_mode {
    Err(_) => {
      eprint "cycle request failed canonical typed parsing"
      return false
    }
    Ok(parsed) => {
      if parsed != mode {
        eprint f"cycle request mode does not match dispatcher mode: ${mode}"
        return false
      }
    }
  }
  if ! fs.exists(xsh_repo)? {
    eprint f"XSH repository does not exist: ${xsh_repo.display()}"
    return false
  }
  for required in [
    "NORTH-STAR.md",
    "runtime/handbook.md",
    "factory/entrypoints/run-agent.xsh",
    "factory/controllers/reuse.xsh",
    "factory/tools/cto.xsh",
    "factory/control.xsh",
    "factory/runtime.xsh",
    "factory/tools/report.xsh",
    "factory/schema.xsh",
    "factory/tools/audit.xsh",
    "factory/tools/cleanup-run.xsh",
    "factory/tools/cycle-budget-watch.xsh",
    "factory/tools/session-watch.xsh",
    "factory/tools/cto-report.xsh",
    "templates/POSTMORTEM.md",
    "templates/CTO-REPORT.md",
    "templates/CTO-EVAL-REVIEW.md",
    "templates/CTO-EMPLOYEE.md",
    "templates/CTO-PHASE.md",
    "templates/CTO-WORKER.md",
    "templates/CTO-TOOL-ERROR.md",
    "templates/CTO-TOTAL.md",
    "templates/CTO-IMPROVEMENT.md",
    "runtime/handbook-ledger.md",
    "factory/types.xsh",
    "factory/paths.xsh",
    "factory/request.xsh",
    "factory/policy.xsh",
    "factory/graph.xsh",
    "factory/dispatch.xsh",
    "factory/lifecycle.xsh",
    "factory/evidence.xsh",
    "factory/reports.xsh",
    "factory/cleanup.xsh",
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

  if mode == "organization" {
    let ticket_inventory = runtime.cto_ticket_inventory(factory_dir, xsh_repo)?
    let unreviewed_tickets = runtime.cto_unreviewed_open_tickets(ticket_inventory)
    if unreviewed_tickets.len() > 0 {
      eprint f"CTO review required for Open tickets before organization admission: ${unreviewed_tickets.join(", ")}"
      return false
    }
  }

  let requested_tickets = typed_request.ticket_values(request_text)?
  let eval_contracts = fs.files(fp"${factory_dir}/evals", gitignore: false, hidden: true)?
    |> where .name == "EVAL.md"
    |> collect()
  if eval_contracts.len() > control.max_eval_contracts() {
    eprint f"eval contract cap exceeded: ${eval_contracts.len()} > ${control.max_eval_contracts()}"
    return false
  }
  let candidate_tickets = if requested_tickets.len() > 0 {
    requested_tickets
  } else if mode == "organization" and typed_request.ticket_policy_value(request_text)? != "none" {
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
    if fs.exists(ticket_path)? and control.ticket_change_target(ticket_path.read_text()?) != "product" {
      eprint f"ticket ${candidate_ticket} is not a product ticket; CTO owns factory changes and no engineer was dispatched"
      return false
    }
    if fs.exists(ticket_path)? and runtime.accepted_ticket(ticket_path)? {
      let open_branch = runtime.open_ticket_branch(xsh_repo, candidate_ticket)?
      if open_branch != "" and mode != "organization" {
        eprint f"ticket ${candidate_ticket} already has an unmerged implementation branch: ${open_branch}"
        eprint "replay or review that branch before dispatching another engineer"
        return false
      }
    }
  }
  let unresolved_handbook = runtime.unresolved_handbook_candidates(factory_dir)?
  if unresolved_handbook > 0 {
    eprint f"${unresolved_handbook} handbook candidates require CTO disposition before paid work"
    return false
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
    let eval_values = typed_request.eval_values(request_text)?
    let eval_id = if eval_values.len() > 0 { eval_values[0] } else { "" }
    if mode == "organization" and eval_id == "" {
      eprint "organization request must select an eval"
      return false
    }
    let eval_path = fp"${factory_dir}/evals/${eval_id}/EVAL.md"
    let eval_exists = fs.exists(eval_path)?
    let eval_disabled = eval_exists and control.eval_is_disabled(eval_path.read_text()?)
    if mode == "organization" and ! typed_request.measured_reuse_value(request_text)? {
      let next_untried = runtime.next_untried_approved_eval(factory_dir)?
      if next_untried != "" and eval_id != next_untried {
        eprint f"organization request must select next untried approved eval ${next_untried}; selected ${eval_id}"
        return false
      }
    }
    if ! control.valid_eval_id(eval_id) or ! eval_exists or eval_disabled {
      eprint f"cycle request selected unsupported or missing eval: ${eval_id}"
      return false
    }
    let evaluator_file = fp"${factory_dir}/evals/${eval_id}/evaluator.xsh"
    if ! fs.exists(evaluator_file)? {
      eprint f"eval ${eval_id} is missing its package-owned evaluator.xsh"
      return false
    }
    let evaluator_source = evaluator_file.read_text()?
    if ! control.eval_evaluator_package_owned(evaluator_source) {
      eprint f"eval ${eval_id} package evaluator delegates to a legacy/shared dispatcher"
      return false
    }
    let evaluator_check = process.run(process.command_argv(
      process.which("xsht")?,
      ["xsht", "check", evaluator_file.display()],
      cwd: factory_dir,
    ))?
    if ! evaluator_check.ok {
      eprint f"eval ${eval_id} package evaluator failed xsht check"
      return false
    }
  }
  if mode == "eval" or mode == "organization" {
    let trial_count = typed_request.trial_value(request_text)?
    if trial_count < 1 or trial_count > 2 {
      eprint f"unsupported trial count: ${trial_count} (expected 1 or 2)"
      return false
    }
  }
  if mode == "eval-design" {
    let new_eval_count = typed_request.design_value(request_text)?
    if new_eval_count != 1 {
      eprint f"${mode} requires exactly one eval-design proposal"
      return false
    }
  } else if mode == "organization" {
    let new_eval_count = typed_request.design_value(request_text)?
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
  let mode = typed_request.mode_value(request_text)?
  let xsh_repo = env.path("FACTORY_XSH_REPO", fp"${factory_dir}/../xsh")?
  if ! preflight(factory_dir, xsh_repo, request, request_text, mode)? {
    abort(1)
  }
  let child = if mode == "ticket-implementation" {
    fp"${factory_dir}/factory/controllers/ticket.xsh"
  } else if mode == "eval" {
    fp"${factory_dir}/factory/controllers/eval.xsh"
  } else if mode == "organization" {
    fp"${factory_dir}/factory/controllers/organization.xsh"
  } else {
    fp"${factory_dir}/factory/controllers/design.xsh"
  }
  let xsh_path = process.which("xsh")?
  let status = process.run(process.command_argv(
    xsh_path,
    [xsh_path.display(), child.display(), "--"].extend(argv),
    cwd: factory_dir,
  ))?
  abort(if status.ok { 0 } else { status.exit_code() ?? 1 })
}
