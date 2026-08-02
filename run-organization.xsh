##! Organization-cycle controller with independent phase overlap.

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

proc spawn_child(
  child: Path,
  request: Path,
  phase_dir: Path,
  factory_dir: Path,
  xsh_repo: Path,
  parent_run: Path,
  base_commit: Str,
  run_agent: Path,
  auth_file: Path,
  pi_command: Str,
  docker: Str,
  target: Str,
  platform: Str,
  extra_env: List[Str],
  stdout: Path,
  stderr: Path,
) [fs, process, env, error] -> Result[ProcessHandle] {
  let xsh_path = process.which("xsh")?
  let child_runner = env.path("FACTORY_CHILD_RUNNER", xsh_path)?
  let env_path = process.which("env")?
  let base_image = env.get_or("FACTORY_BASE_IMAGE", "xsh-factory-base:latest")?
  var assignments: List[Str] = [
    "FACTORY_DIR=" + factory_dir.display(),
    "FACTORY_RUN_DIR=" + phase_dir.display(),
    "FACTORY_RUN_AGENT=" + run_agent.display(),
    "FACTORY_WORKFLOW_RUN=" + parent_run.display(),
    "FACTORY_PHASE_DIR=" + phase_dir.display(),
    "FACTORY_XSH_REPO=" + xsh_repo.display(),
    "FACTORY_XSH_COMMIT=" + base_commit,
    "FACTORY_HANDBOOK_FILE=" + fp"${factory_dir}/runtime/handbook.md".display(),
    "FACTORY_NORTH_STAR_FILE=" + fp"${factory_dir}/NORTH-STAR.md".display(),
    "FACTORY_PLATFORM=" + platform,
    "XSH_TARGET=" + target,
    "FACTORY_BASE_IMAGE=" + base_image,
    "FACTORY_SKIP_CYCLE_BUDGET=true",
    "PI_AUTH_FILE=" + auth_file.display(),
    "PI_COMMAND=" + pi_command,
    "DOCKER=" + docker,
    "XSH_MODULE_PATH=" + factory_dir.display(),
  ]
  assignments = assignments.push("FACTORY_ACTIVE_RUN=" + fp"${phase_dir}/ACTIVE".display())
  assignments = assignments.push("FACTORY_LOCK_PATH=" + fp"${phase_dir}/factory.lock".display())
  for role in ["director", "eval-designer", "eval-manager", "eval-worker", "xsh-swe"] {
    let prefix = control.role_prefix(role)
    assignments = assignments.push(f"FACTORY_${prefix}_PROVIDER=${control.configured_role_setting(role, "PROVIDER")?}")
    assignments = assignments.push(f"FACTORY_${prefix}_MODEL=${control.configured_role_setting(role, "MODEL")?}")
    assignments = assignments.push(f"FACTORY_${prefix}_THINKING=${control.configured_role_setting(role, "THINKING")?}")
    assignments = assignments.push(f"FACTORY_${prefix}_BUDGET_USD=${control.configured_role_setting(role, "BUDGET_USD")?}")
    assignments = assignments.push(f"FACTORY_${prefix}_TOOLS=${control.configured_role_setting(role, "TOOLS")?}")
  }
  let child_args = assignments.extend(extra_env).extend([
    child_runner.display(), child.display(), "--", request.display()
  ])
  return spawn process.command_argv(
    env_path,
    [env_path.display()].extend(child_args),
    cwd: factory_dir,
    stdout: stdout,
    stderr: stderr,
  )
}

proc wait_child(handle: ProcessHandle) [process, error] -> Result[Bool] {
  let status = wait handle?
  return status.ok
}

proc run_child(
  child: Path,
  request: Path,
  phase_dir: Path,
  factory_dir: Path,
  xsh_repo: Path,
  parent_run: Path,
  base_commit: Str,
  run_agent: Path,
  auth_file: Path,
  pi_command: Str,
  docker: Str,
  target: Str,
  platform: Str,
  extra_env: List[Str],
  stdout: Path,
  stderr: Path,
) [fs, process, env, error] -> Result[Bool] {
  let handle = spawn_child(
    child, request, phase_dir, factory_dir, xsh_repo, parent_run, base_commit,
    run_agent, auth_file, pi_command, docker, target, platform, extra_env,
    stdout, stderr,
  )?
  return wait_child(handle)
}

proc phase_run_pass(phase_dir: Path, report_name: Str) [fs, error] -> Result[Bool] {
  let report = fp"${phase_dir}/${report_name}"
  if ! fs.exists(report)? {
    return false
  }
  return control.report_field(report.read_text()?, "Result") == "pass"
}

proc phase_request(
  template: Path,
  output_path: Path,
  mode: Str,
  eval_id: Str,
  trial_count: Int,
  new_eval_count: Int,
  ticket_value: Str,
  objective: Str,
) [fs, error] -> Result[Unit] {
  let values: List[control.TemplateValue] = [
    {key: "MODE", value: mode},
    {key: "EVAL_ID", value: eval_id},
    {key: "TRIAL_COUNT", value: trial_count.float().format(precision: 0)},
    {key: "NEW_EVAL_COUNT", value: new_eval_count.float().format(precision: 0)},
    {key: "TICKET_ID", value: ticket_value},
    {key: "OBJECTIVE", value: objective},
  ]
  fs.write(output_path, control.fill_template(template.read_text()?, values))?
  return Ok()
}

proc main(...argv: List[Str]) [fs, process, env, time, error, io] {
  if argv.len() < 1 {
    eprint "usage: run-organization.xsh CYCLE_REQUEST.md"
    abort(2)
  }
  let factory_dir = env.path("FACTORY_DIR", fs.cwd()?)?
  let request = Path(argv[0])
  let request_text = request.read_text()?
  if control.request_mode(request_text) != "organization" {
    eprint "organization controller requires a request with mode organization"
    abort(2)
  }
  let trial_count = control.request_trial_count(request_text)?
  if trial_count < 1 or trial_count > 2 {
    eprint f"unsupported trial count: ${trial_count} (expected 1 or 2)"
    abort(2)
  }
  let new_eval_count = control.request_new_eval_count(request_text)?
  if new_eval_count < 0 or new_eval_count > 1 {
    eprint "organization cycles allow zero or one eval-design proposal"
    abort(2)
  }
  let design_requested = new_eval_count == 1
  let requested_tickets = control.request_tickets(request_text)
  if requested_tickets.len() > 1 {
    eprint "organization cycles admit at most one ticket"
    abort(2)
  }
  let xsh_repo = env.path("FACTORY_XSH_REPO", fp"${factory_dir}/../xsh")?
  let xsh_commit = run.text "git" "-C" $xsh_repo.display() "rev-parse" "HEAD" ?
  let xsh_git_status = run.text "git" "-C" $xsh_repo.display() "status" "--porcelain" ?
  if xsh_git_status.trim() != "" {
    eprint "organization cycle requires a clean XSH worktree at admission"
    abort(2)
  }
  let stamp = time.now()
  let run_dir = fp"${factory_dir}/runs/run-${stamp}"
  let active_run = fp"${factory_dir}/runs/ORGANIZATION-ACTIVE"
  fs.mkdir(fp"${factory_dir}/runs")?
  if fs.exists(active_run)? and fs.read_text(active_run)?.trim() != "" {
    eprint "another organization cycle is already active"
    abort(1)
  }
  let _organization_lock = fs.lock(fp"${factory_dir}/runs/organization.lock", nonblocking: true)?
  fs.mkdir(run_dir)?
  runtime.register_cycle_controller(run_dir)?
  let skip_cycle_budget = env.get_or("FACTORY_SKIP_CYCLE_BUDGET", "false")? == "true"
  if ! skip_cycle_budget {
    let _cycle_budget_watch = runtime.start_cycle_budget_watch(factory_dir, run_dir)?
  }
  fs.write(active_run, run_dir.display() + "\n")?
  defer fs.remove(active_run, missing_ok: true)?
  let _ = runtime.reconcile_tickets(factory_dir, xsh_repo, xsh_commit.trim())?
  let ticket_policy = control.request_ticket_policy(request_text)
  let selected_ticket = if requested_tickets.len() == 1 {
    requested_tickets[0]
  } else if ticket_policy == "none" {
    ""
  } else {
    runtime.first_approved_ticket(factory_dir)?
  }
  if selected_ticket != "" and ! control.valid_ticket_id(selected_ticket) {
    eprint f"unsafe ticket id: ${selected_ticket}"
    abort(2)
  }
  let selected_ticket_path = if selected_ticket == "" {
    fp"${factory_dir}/tickets/not-selected.md"
  } else {
    fp"${factory_dir}/tickets/${selected_ticket}.md"
  }
  if selected_ticket != "" and ! runtime.accepted_ticket(selected_ticket_path)? {
    eprint f"selected ticket is missing or not Approved: ${selected_ticket}"
    abort(2)
  }
  let requested_eval = control.request_eval(request_text)
  let ticket_eval = if selected_ticket != "" {
    control.ticket_eval(selected_ticket_path.read_text()?)
  } else {
    ""
  }
  let independent_eval_path = fp"${factory_dir}/evals/${requested_eval}/EVAL.md"
  let independent_eval_exists = fs.exists(independent_eval_path)?
  let independent_eval_disabled = independent_eval_exists and
    control.eval_is_disabled(independent_eval_path.read_text()?)
  if ! control.valid_eval_id(requested_eval) or ! independent_eval_exists or independent_eval_disabled {
    eprint f"organization cycle selected unsupported or missing independent eval: ${requested_eval}"
    abort(2)
  }
  let ticket_eval_exists = if selected_ticket == "" {
    true
  } else {
    fs.exists(fp"${factory_dir}/evals/${ticket_eval}/EVAL.md")?
  }
  let ticket_eval_path = fp"${factory_dir}/evals/${ticket_eval}/EVAL.md"
  let ticket_eval_disabled = if selected_ticket == "" or ! ticket_eval_exists {
    false
  } else {
    control.eval_is_disabled(ticket_eval_path.read_text()?)
  }
  if selected_ticket != "" and
    (! control.valid_eval_id(ticket_eval) or ! ticket_eval_exists or ticket_eval_disabled) {
    eprint f"ticket ${selected_ticket} links unsupported or missing eval: ${ticket_eval}"
    abort(2)
  }
  let selected_eval = if selected_ticket == "" { requested_eval } else { ticket_eval }

  let phases_dir = fp"${run_dir}/phases"
  let phase_requests_dir = fp"${run_dir}/phase-requests"
  let primary_mode = if selected_ticket == "" { "eval" } else { "ticket-implementation" }
  let primary_phase = if selected_ticket == "" {
    fp"${phases_dir}/01-eval"
  } else {
    fp"${phases_dir}/01-ticket"
  }
  let reeval_phase = fp"${phases_dir}/02-reeval"
  let independent_eval_phase = fp"${phases_dir}/03-eval"
  let design_phase = if selected_ticket == "" {
    fp"${phases_dir}/02-eval-design"
  } else {
    fp"${phases_dir}/04-eval-design"
  }
  let primary_request = fp"${phase_requests_dir}/01-primary.md"
  let reeval_request = fp"${phase_requests_dir}/02-reeval.md"
  let independent_eval_request = fp"${phase_requests_dir}/03-eval.md"
  let design_request = if selected_ticket == "" {
    fp"${phase_requests_dir}/02-eval-design.md"
  } else {
    fp"${phase_requests_dir}/04-eval-design.md"
  }
  let event_template = fp"${factory_dir}/templates/EVENT.md"
  let phase_template = fp"${factory_dir}/templates/ORGANIZATION-PHASE-REQUEST.md"
  let run_agent = fp"${factory_dir}/run-agent.xsh"
  let default_primary_controller = if selected_ticket == "" {
    fp"${factory_dir}/run-eval.xsh"
  } else {
    fp"${factory_dir}/run-ticket.xsh"
  }
  let primary_controller = env.path("FACTORY_PRIMARY_CONTROLLER", default_primary_controller)?
  let design_controller = env.path("FACTORY_DESIGN_CONTROLLER", fp"${factory_dir}/run-design.xsh")?
  let home = env.get("HOME")?
  let auth_file = env.path("PI_AUTH_FILE", fp"${home}/.pi/agent/auth.json")?
  let pi_command = env.get_or("PI_COMMAND", "pi")?
  let docker = env.get_or("DOCKER", "docker")?
  let platform = env.get_or("FACTORY_PLATFORM", "linux/arm64")?
  let target = env.get_or("XSH_TARGET", "aarch64-unknown-linux-musl")?
  fs.mkdir(phases_dir)?
  fs.mkdir(phase_requests_dir)?
  fs.mkdir(primary_phase)?
  if design_requested {
    fs.mkdir(design_phase)?
  }
  if selected_ticket != "" {
    fs.mkdir(reeval_phase)?
    fs.mkdir(independent_eval_phase)?
  }
  fs.write(active_run, run_dir.display() + "\n")?
  defer fs.remove(active_run, missing_ok: true)?
  fs.copy(request, fp"${run_dir}/CYCLE-REQUEST.md", overwrite: true)?
  runtime.emit_event(event_template, run_dir, "00-cycle-started", "organization", "started", 1, "controller", "bounded organization cycle with independent eval-design overlap")?

  let ticket_value = if selected_ticket == "" { "None." } else { f"`${selected_ticket}`" }
  let primary_objective = if selected_ticket == "" {
    f"Run one fresh ${selected_eval} eval because no approved ticket was admitted."
  } else {
    f"Implement exactly ${selected_ticket} in one isolated XSH worktree."
  }
  phase_request(phase_template, primary_request, primary_mode, selected_eval, trial_count, 0, ticket_value, primary_objective)?
  phase_request(phase_template, reeval_request, "eval", selected_eval, trial_count, 0, "None.",
    f"Validate the ${selected_ticket} implementation against the linked ${selected_eval} eval before merge.")?
  phase_request(phase_template, independent_eval_request, "eval", requested_eval, trial_count, 0, "None.",
    f"Run the independent ${requested_eval} eval against the XSH main commit.")?
  if design_requested {
    phase_request(phase_template, design_request, "eval-design", requested_eval, 1, 1, "None.",
      "Design and dry-run one small practical eval proposal for user review.")?
  }

  let candidate_worktree = if selected_ticket == "" {
    "not-reevaluation"
  } else {
    fp"${primary_phase}/worktrees/${selected_ticket}".display()
  }
  let ticket_snapshot_sha = if selected_ticket == "" {
    "not-ticket-cycle"
  } else {
    hash.sha256(selected_ticket_path)?.hex()
  }
  let approved_handbook_sha = hash.sha256(fp"${factory_dir}/runtime/handbook.md")?.hex()
  let provenance_template = fp"${factory_dir}/templates/PROVENANCE.md"
  let provenance_values: List[control.TemplateValue] = [
    {key: "RUN_ID", value: run_dir.display()},
    {key: "MODE", value: "organization"},
    {key: "REQUEST", value: "CYCLE-REQUEST.md"},
    {key: "BUILD_ID", value: "child-phase-builds"},
    {key: "XSH_COMMIT", value: xsh_commit.trim()},
    {key: "CANDIDATE_TICKET", value: if selected_ticket == "" { "not-reevaluation" } else { selected_ticket }},
    {key: "CANDIDATE_WORKTREE", value: candidate_worktree},
    {key: "IMAGE", value: "child-phase"},
    {key: "IMAGE_ID", value: "child-phase"},
    {key: "PLATFORM", value: platform},
    {key: "APPROVED_HANDBOOK_SHA", value: approved_handbook_sha},
    {key: "CANDIDATE_HANDBOOK_SHA", value: "child-phase"},
    {key: "TICKET_SNAPSHOT_SHA", value: ticket_snapshot_sha},
  ]
  fs.write(fp"${run_dir}/PROVENANCE.md", control.fill_template(provenance_template.read_text()?, provenance_values))?
  let plan_template = fp"${factory_dir}/templates/ORGANIZATION-PLAN.md"
  let plan_values: List[control.TemplateValue] = [
    {key: "XSH_COMMIT", value: xsh_commit.trim()},
    {key: "TICKET_ID", value: if selected_ticket == "" { "none" } else { selected_ticket }},
    {key: "TICKET_EVAL_ID", value: if selected_ticket == "" { "not-applicable" } else { selected_eval }},
    {key: "INDEPENDENT_EVAL_ID", value: requested_eval},
    {key: "TICKET_POLICY", value: ticket_policy},
    {key: "PRIMARY_MODE", value: primary_mode},
    {key: "PRIMARY_PHASE", value: primary_phase.display()},
    {key: "REEVAL_PHASE", value: if selected_ticket == "" { "not-applicable" } else { reeval_phase.display() }},
    {key: "INDEPENDENT_EVAL_PHASE", value: if selected_ticket == "" { "not-applicable" } else { independent_eval_phase.display() }},
    {key: "DESIGN_PHASE", value: if design_requested { design_phase.display() } else { "not-requested" }},
  ]
  fs.write(fp"${run_dir}/ORGANIZATION-PLAN.md", control.fill_template(plan_template.read_text()?, plan_values))?

  var design_handle: ProcessHandle? = null
  if design_requested {
    runtime.emit_event(event_template, run_dir, "10-design-started", "eval-design", "started", 1, "organization", "one independent eval-design phase was requested")?
    design_handle = spawn_child(
      design_controller, design_request, design_phase, factory_dir, xsh_repo,
      run_dir, xsh_commit.trim(), run_agent, auth_file, pi_command, docker, target, platform,
      ["FACTORY_MODE=eval-design", f"FACTORY_EVAL_ID=${requested_eval}"],
      fp"${run_dir}/design.stdout", fp"${run_dir}/design.stderr"
    )?
  }

  let primary_subject = if selected_ticket == "" { selected_eval } else { selected_ticket }
  runtime.emit_event(event_template, run_dir, "10-primary-started", primary_subject, "started", 1, "organization", primary_mode)?
  let primary_ok = run_child(
    primary_controller,
    primary_request, primary_phase, factory_dir, xsh_repo, run_dir, xsh_commit.trim(), run_agent,
    auth_file, pi_command, docker, target, platform,
    [f"FACTORY_MODE=${primary_mode}", f"FACTORY_EVAL_ID=${selected_eval}",
      "FACTORY_REEVAL_TICKET=not-reevaluation", "FACTORY_REEVAL_WORKTREE=not-reevaluation",
      "FACTORY_SKIP_TICKET_RECONCILE=false"],
    fp"${run_dir}/primary.stdout", fp"${run_dir}/primary.stderr"
  )?
  let primary_report_ok = phase_run_pass(primary_phase, if selected_ticket == "" { "RUN.md" } else { "RUN.md" })?
  let primary_pass = primary_ok and primary_report_ok
  let primary_state = if primary_pass { "pass" } else { "fail" }
  runtime.emit_event(event_template, run_dir, "80-primary-completed", primary_subject,
    if primary_pass { "completed" } else { "failed" }, 1, "controller", "primary phase returned")?
  if primary_pass {
    runtime.emit_event(event_template, run_dir, "85-primary-validated", primary_subject, "validated", 1, "controller", "primary phase RUN.md passed")?
  }

  var reeval_state = if selected_ticket == "" { "not-applicable" } else { "skipped" }
  var reeval_report_state = if selected_ticket == "" { "not-applicable" } else { "not-run" }
  if selected_ticket != "" and primary_pass {
    runtime.emit_event(event_template, run_dir, "10-reeval-started", f"${selected_ticket}-reevaluation", "started", 1, "organization", "validated SWE worktree is available")?
    let reeval_ok = run_child(
      fp"${factory_dir}/run-eval.xsh", reeval_request, reeval_phase, factory_dir,
      fp"${primary_phase}/worktrees/${selected_ticket}", run_dir, xsh_commit.trim(), run_agent,
      auth_file, pi_command, docker, target, platform,
      ["FACTORY_MODE=eval", f"FACTORY_EVAL_ID=${selected_eval}",
        f"FACTORY_REEVAL_TICKET=${selected_ticket}",
        f"FACTORY_REEVAL_WORKTREE=${candidate_worktree}",
        "FACTORY_SKIP_TICKET_RECONCILE=true"],
      fp"${run_dir}/reeval.stdout", fp"${run_dir}/reeval.stderr"
    )?
    let reeval_report_ok = phase_run_pass(reeval_phase, "RUN.md")?
    let reeval_pass = reeval_ok and reeval_report_ok
    reeval_state = if reeval_pass { "pass" } else { "fail" }
    reeval_report_state = if reeval_report_ok { "pass" } else { "missing-or-failed" }
    runtime.emit_event(event_template, run_dir, "80-reeval-completed", f"${selected_ticket}-reevaluation",
      if reeval_pass { "completed" } else { "failed" }, 1, "controller", "candidate re-evaluation returned")?
    if reeval_pass {
      runtime.emit_event(event_template, run_dir, "85-reeval-validated", f"${selected_ticket}-reevaluation", "validated", 1, "controller", "candidate re-evaluation RUN.md passed")?
    }
  }

  var independent_eval_state = if selected_ticket == "" { "not-applicable" } else { "not-run" }
  var independent_eval_report_state = if selected_ticket == "" { "not-applicable" } else { "not-run" }
  if selected_ticket != "" {
    runtime.emit_event(event_template, run_dir, "10-independent-eval-started", requested_eval, "started", 1, "organization", "running the requested independent eval against XSH main")?
    let independent_eval_ok = run_child(
      fp"${factory_dir}/run-eval.xsh", independent_eval_request, independent_eval_phase, factory_dir,
      xsh_repo, run_dir, xsh_commit.trim(), run_agent, auth_file, pi_command, docker, target, platform,
      ["FACTORY_MODE=eval", f"FACTORY_EVAL_ID=${requested_eval}",
        "FACTORY_REEVAL_TICKET=not-reevaluation", "FACTORY_REEVAL_WORKTREE=not-reevaluation",
        "FACTORY_SKIP_TICKET_RECONCILE=false"],
      fp"${run_dir}/independent-eval.stdout", fp"${run_dir}/independent-eval.stderr"
    )?
    let independent_eval_report_ok = phase_run_pass(independent_eval_phase, "RUN.md")?
    let independent_eval_pass = independent_eval_ok and independent_eval_report_ok
    independent_eval_state = if independent_eval_pass { "pass" } else { "fail" }
    independent_eval_report_state = if independent_eval_report_ok { "pass" } else { "missing-or-failed" }
    runtime.emit_event(event_template, run_dir, "80-independent-eval-completed", requested_eval,
      if independent_eval_pass { "completed" } else { "failed" }, 1, "controller", "independent eval phase returned")?
    if independent_eval_pass {
      runtime.emit_event(event_template, run_dir, "85-independent-eval-validated", requested_eval, "validated", 1, "controller", "independent eval RUN.md passed")?
    }
  }

  var design_state = "not-requested"
  var design_report_state = "not-requested"
  if design_handle != null {
    let design_ok = wait_child(design_handle)?
    let design_report_ok = phase_run_pass(design_phase, "RUN-DESIGN.md")?
    let design_pass = design_ok and design_report_ok
    design_state = if design_pass { "pass" } else { "fail" }
    design_report_state = if design_report_ok { "pass" } else { "missing-or-failed" }
    runtime.emit_event(event_template, run_dir, "80-design-completed", "eval-design",
      if design_pass { "completed" } else { "failed" }, 1, "controller", "eval-design phase returned")?
    if design_pass {
      runtime.emit_event(event_template, run_dir, "85-design-validated", "eval-design", "validated", 1, "controller", "eval-design RUN-DESIGN.md passed")?
    }
  }

  let xsh_path = process.which("xsh")?
  let cost_status = process.run(process.command_argv(
    xsh_path,
    [xsh_path.display(), fp"${factory_dir}/tools/session-report.xsh", "--", "run",
      "--run-dir", run_dir.display(), "--output", fp"${run_dir}/COST.md".display()],
  ))?
  let cost_state = if cost_status.ok { "present" } else { "failed" }
  let reeval_pass_for_result = if selected_ticket == "" { true } else { reeval_state == "pass" }
  let independent_eval_pass_for_result = if selected_ticket == "" { true } else { independent_eval_state == "pass" }
  let design_pass_for_result = design_state == "pass" or design_state == "not-requested"
  let result = if primary_pass and reeval_pass_for_result and independent_eval_pass_for_result and design_pass_for_result and cost_status.ok { "pass" } else { "fail" }
  let run_template = fp"${factory_dir}/templates/RUN-ORGANIZATION.md"
  let run_values: List[control.TemplateValue] = [
    {key: "RUN_ID", value: stamp.float().format(precision: 0)},
    {key: "RESULT", value: result},
    {key: "TICKET_ID", value: if selected_ticket == "" { "none" } else { selected_ticket }},
    {key: "TICKET_EVAL_ID", value: if selected_ticket == "" { "not-applicable" } else { selected_eval }},
    {key: "INDEPENDENT_EVAL_ID", value: requested_eval},
    {key: "XSH_COMMIT", value: xsh_commit.trim()},
    {key: "PRIMARY_MODE", value: primary_mode},
    {key: "PRIMARY_STATE", value: primary_state},
    {key: "PRIMARY_PHASE", value: primary_phase.display()},
    {key: "REEVAL_STATE", value: reeval_state},
    {key: "REEVAL_PHASE", value: if selected_ticket == "" { "not-applicable" } else { reeval_phase.display() }},
    {key: "INDEPENDENT_EVAL_STATE", value: independent_eval_state},
    {key: "INDEPENDENT_EVAL_PHASE", value: if selected_ticket == "" { "not-applicable" } else { independent_eval_phase.display() }},
    {key: "DESIGN_STATE", value: design_state},
    {key: "DESIGN_PHASE", value: if design_requested { design_phase.display() } else { "not-requested" }},
    {key: "PRIMARY_REPORT_STATE", value: if primary_report_ok { "pass" } else { "missing-or-failed" }},
    {key: "REEVAL_REPORT_STATE", value: reeval_report_state},
    {key: "INDEPENDENT_EVAL_REPORT_STATE", value: independent_eval_report_state},
    {key: "DESIGN_REPORT_STATE", value: design_report_state},
    {key: "COST_STATE", value: cost_state},
  ]
  fs.write(fp"${run_dir}/RUN.md", control.fill_template(run_template.read_text()?, run_values))?
  runtime.emit_event(event_template, run_dir, if result == "pass" { "90-cycle-completed" } else { "90-cycle-failed" },
    "organization", if result == "pass" { "completed" } else { "failed" }, 1, "controller", "organization RUN.md and aggregate COST.md written")?
  if result == "pass" {
    runtime.emit_event(event_template, run_dir, "95-cycle-validated", "organization", "validated", 1, "controller", "all required phases passed")?
  }
  if ! skip_cycle_budget {
    runtime.stop_cycle_budget_watch(run_dir)?
  }
  print f"factory organization run: ${run_dir} (${result})"
  abort(if result == "pass" { 0 } else { 1 })
}
