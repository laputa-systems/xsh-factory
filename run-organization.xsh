##! Organization-cycle controller with independent phase overlap.

use factory_control as control
use factory_runtime as runtime
use report_schema as schema

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
  let configured_base_image = env.get_or("FACTORY_BASE_IMAGE", "")?
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
    "FACTORY_SKIP_CYCLE_BUDGET=true",
    "PI_AUTH_FILE=" + auth_file.display(),
    "PI_COMMAND=" + pi_command,
    "DOCKER=" + docker,
    "XSH_MODULE_PATH=" + factory_dir.display(),
  ]
  if configured_base_image != "" {
    assignments = assignments.push("FACTORY_BASE_IMAGE=" + configured_base_image)
  }
  assignments = assignments.push("FACTORY_ACTIVE_RUN=" + fp"${phase_dir}/ACTIVE".display())
  assignments = assignments.push("FACTORY_LOCK_PATH=" + fp"${phase_dir}/factory.lock".display())
  for role in ["director", "eval-designer", "eval-manager", "eval-worker", "engineer"] {
    let prefix = control.role_prefix(role)
    assignments = assignments.push(f"FACTORY_${prefix}_PROVIDER=${control.configured_role_setting(role, "PROVIDER")?}")
    assignments = assignments.push(f"FACTORY_${prefix}_MODEL=${control.configured_role_setting(role, "MODEL")?}")
    assignments = assignments.push(f"FACTORY_${prefix}_THINKING=${control.configured_role_setting(role, "THINKING")?}")
    assignments = assignments.push(f"FACTORY_${prefix}_BUDGET_USD=${control.configured_role_setting(role, "BUDGET_USD")?}")
    assignments = assignments.push(f"FACTORY_${prefix}_MAX_TURNS=${control.configured_role_setting(role, "MAX_TURNS")?}")
    assignments = assignments.push(f"FACTORY_${prefix}_MAX_WALL_SECONDS=${control.configured_role_setting(role, "MAX_WALL_SECONDS")?}")
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
  let _ = report_name
  let report = fp"${phase_dir}/report.json"
  if ! fs.exists(report)? or ! schema.valid(json.read(report)?, "phase") {
    return false
  }
  return schema.value_text(json.get(json.read(report)?, ["result"], "unknown")) == "pass"
}

proc ticket_worker_pass(phase_dir: Path, ticket_id: Str) [fs, error] -> Result[Bool] {
  let report = fp"${phase_dir}/workers/engineer/${ticket_id}/report.json"
  if ! fs.exists(report)? or ! schema.valid(json.read(report)?, "worker") {
    return false
  }
  return schema.value_text(json.get(json.read(report)?, ["result"], "unknown")) == "pass"
}

proc run_reuse_phase(
  phase_dir: Path,
  factory_dir: Path,
  xsh_repo: Path,
  ticket_id: Str,
  branch: Str,
  base_commit: Str,
) [fs, process, env, error] -> Result[Bool] {
  let xsh = process.which("xsh")?
  let env_path = process.which("env")?
  let assignments = [
    f"FACTORY_DIR=${factory_dir.display()}",
    f"FACTORY_PHASE_DIR=${phase_dir.display()}",
    f"FACTORY_XSH_REPO=${xsh_repo.display()}",
    f"FACTORY_XSH_COMMIT=${base_commit}",
    f"FACTORY_TICKET_ID=${ticket_id}",
    f"FACTORY_TICKET_BRANCH=${branch}",
    f"XSH_MODULE_PATH=${factory_dir.display()}",
  ]
  let status = process.run(process.command_argv(
    env_path,
    [env_path.display()].extend(assignments).extend([
      xsh.display(), fp"${factory_dir}/run-ticket-reuse.xsh", "--",
    ]),
    cwd: factory_dir,
    stdout: fp"${phase_dir}/reuse.stdout",
    stderr: fp"${phase_dir}/reuse.stderr",
  ))?
  return status.ok
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
  if requested_tickets.len() > control.max_concurrent_engineers() {
    eprint f"organization cycles admit at most ${control.max_concurrent_engineers()} tickets"
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
  defer runtime.cleanup_run_worktrees(xsh_repo, run_dir)?
  runtime.write_cto_inventory(factory_dir, run_dir, xsh_repo)?
  let ticket_inventory = runtime.cto_ticket_inventory(factory_dir, xsh_repo)?
  let unreviewed_tickets = runtime.cto_unreviewed_open_tickets(ticket_inventory)
  if unreviewed_tickets.len() > 0 {
    eprint f"CTO review required for Open tickets before organization admission: ${unreviewed_tickets.join(", ")}"
    abort(1)
  }
  runtime.stage_cto_improvement(factory_dir, run_dir)?
  runtime.register_cycle_controller(run_dir)?
  let skip_cycle_budget = env.get_or("FACTORY_SKIP_CYCLE_BUDGET", "false")? == "true"
  if ! skip_cycle_budget {
    let _cycle_budget_watch = runtime.start_cycle_budget_watch(factory_dir, run_dir)?
  }
  fs.write(active_run, run_dir.display() + "\n")?
  defer fs.remove(active_run, missing_ok: true)?
  let _ = runtime.reconcile_tickets(factory_dir, xsh_repo, xsh_commit.trim())?
  let ticket_policy = control.request_ticket_policy(request_text)
  let selected_tickets = if requested_tickets.len() > 0 {
    requested_tickets
  } else if ticket_policy == "none" {
    []
  } else {
    runtime.first_approved_tickets(factory_dir, control.max_concurrent_engineers())?
  }
  let selected_ticket = if selected_tickets.len() > 0 { selected_tickets[0] } else { "" }
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
  let selected_open_branch = if selected_tickets.len() == 1 {
    runtime.open_ticket_branch(xsh_repo, selected_ticket)?
  } else {
    ""
  }
  let reuse_existing_branch = selected_open_branch != ""
  if reuse_existing_branch {
    eprint f"reusing existing implementation branch for ${selected_ticket}: ${selected_open_branch}"
  }
  for ticket_id in selected_tickets {
    let ticket_path = fp"${factory_dir}/tickets/${ticket_id}.md"
    if ! control.valid_ticket_id(ticket_id) or ! runtime.accepted_ticket(ticket_path)? {
      eprint f"selected ticket is missing or not Approved: ${ticket_id}"
      abort(2)
    }
    let ticket_eval_id = control.ticket_eval(ticket_path.read_text()?)
    let ticket_eval_path = fp"${factory_dir}/evals/${ticket_eval_id}/EVAL.md"
    let ticket_eval_available = ticket_eval_id != "" and fs.exists(ticket_eval_path)? and
      ! control.eval_is_disabled(ticket_eval_path.read_text()?)
    if ! ticket_eval_available {
      eprint f"selected ticket ${ticket_id} links unsupported or disabled eval: ${ticket_eval_id}"
      abort(2)
    }
    let open_branch = runtime.open_ticket_branch(xsh_repo, ticket_id)?
    if open_branch != "" and ! (reuse_existing_branch and ticket_id == selected_ticket) {
      eprint f"ticket ${ticket_id} already has an unmerged implementation branch: ${open_branch}"
      eprint "replay or review that branch before dispatching another engineer"
      abort(2)
    }
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
  let independent_eval_phase = fp"${phases_dir}/03-eval"
  let design_phase = if selected_ticket == "" {
    fp"${phases_dir}/02-eval-design"
  } else {
    fp"${phases_dir}/04-eval-design"
  }
  let primary_request = fp"${phase_requests_dir}/01-primary.md"
  let independent_eval_request = fp"${phase_requests_dir}/03-eval.md"
  let design_request = if selected_ticket == "" {
    fp"${phase_requests_dir}/02-eval-design.md"
  } else {
    fp"${phase_requests_dir}/04-eval-design.md"
  }
  let event_template = run_dir
  let phase_template = fp"${factory_dir}/templates/ORGANIZATION-PHASE-REQUEST.md"
  let run_agent = fp"${factory_dir}/run-agent.xsh"
  let default_primary_controller = if selected_ticket == "" {
    fp"${factory_dir}/run-eval.xsh"
  } else {
    fp"${factory_dir}/run-ticket.xsh"
  }
  let primary_controller = env.path("FACTORY_PRIMARY_CONTROLLER", default_primary_controller)?
  let eval_controller = env.path("FACTORY_EVAL_CONTROLLER", fp"${factory_dir}/run-eval.xsh")?
  let reeval_controller = env.path("FACTORY_REEVAL_CONTROLLER", fp"${factory_dir}/run-eval.xsh")?
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
  if selected_tickets.len() > 0 {
    fs.mkdir(independent_eval_phase)?
  }
  fs.write(active_run, run_dir.display() + "\n")?
  defer fs.remove(active_run, missing_ok: true)?
  fs.copy(request, fp"${run_dir}/CYCLE-REQUEST.md", overwrite: true)?
  runtime.emit_event(event_template, run_dir, "00-cycle-started", "organization", "started", 1, "controller", "bounded organization cycle with independent eval-design overlap")?

  var ticket_value = "None."
  if selected_tickets.len() > 0 {
    ticket_value = ""
    for ticket_id in selected_tickets {
      ticket_value = if ticket_value == "" { f"`${ticket_id}`" } else { f"${ticket_value}\n- `${ticket_id}`" }
    }
  }
  let primary_objective = if selected_ticket == "" {
    f"Run one fresh ${selected_eval} eval because no approved ticket was admitted."
  } else {
    f"Implement exactly ${selected_ticket} in one isolated XSH worktree."
  }
  phase_request(phase_template, primary_request, primary_mode, selected_eval, trial_count, 0, ticket_value, primary_objective)?
  phase_request(phase_template, independent_eval_request, "eval", requested_eval, trial_count, 0, "None.",
    f"Run the independent ${requested_eval} eval against the XSH main commit.")?
  if design_requested {
    phase_request(phase_template, design_request, "eval-design", requested_eval, 1, 1, "None.",
      "Design and dry-run one small practical eval proposal for CTO review.")?
  }

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

  let candidate_worktree = if selected_ticket == "" {
    "not-reevaluation"
  } else {
    fp"${primary_phase}/worktrees/${selected_ticket}".display()
  }
  let primary_subject = if selected_ticket == "" { selected_eval } else { selected_ticket }
  var independent_eval_handles: List[ProcessHandle] = []
  runtime.emit_event(event_template, run_dir, "10-primary-started", primary_subject, "started", 1, "organization", primary_mode)?
  var primary_ok = false
  if reuse_existing_branch {
    primary_ok = run_reuse_phase(primary_phase, factory_dir, xsh_repo, selected_ticket,
      selected_open_branch, xsh_commit.trim())?
  } else {
    let primary_handle = spawn_child(
      primary_controller,
      primary_request, primary_phase, factory_dir, xsh_repo, run_dir, xsh_commit.trim(), run_agent,
      auth_file, pi_command, docker, target, platform,
      [f"FACTORY_MODE=${primary_mode}", f"FACTORY_EVAL_ID=${selected_eval}",
        "FACTORY_REEVAL_TICKET=not-reevaluation", "FACTORY_REEVAL_WORKTREE=not-reevaluation",
        "FACTORY_SKIP_TICKET_RECONCILE=false", "FACTORY_RETAIN_WORKTREE=true"],
      fp"${run_dir}/primary.stdout", fp"${run_dir}/primary.stderr"
    )?
    primary_ok = wait_child(primary_handle)?
  }
  if selected_ticket != "" {
    runtime.emit_event(event_template, run_dir, "10-independent-eval-started", requested_eval, "started", 1, "organization", "running the requested independent eval in parallel with ticket implementation")?
    let independent_eval_handle = spawn_child(
      eval_controller, independent_eval_request, independent_eval_phase, factory_dir,
      xsh_repo, run_dir, xsh_commit.trim(), run_agent, auth_file, pi_command, docker, target, platform,
      ["FACTORY_MODE=eval", f"FACTORY_EVAL_ID=${requested_eval}",
        "FACTORY_REEVAL_TICKET=not-reevaluation", "FACTORY_REEVAL_WORKTREE=not-reevaluation",
        "FACTORY_SKIP_TICKET_RECONCILE=false"],
      fp"${run_dir}/independent-eval.stdout", fp"${run_dir}/independent-eval.stderr"
    )?
    independent_eval_handles = independent_eval_handles.push(independent_eval_handle)
  }
  let primary_report_ok = phase_run_pass(primary_phase, "report.json")?
  let primary_pass = primary_ok and primary_report_ok
  let primary_state = if primary_pass { "pass" } else { "fail" }
  runtime.emit_event(event_template, run_dir, "80-primary-completed", primary_subject,
    if primary_pass { "completed" } else { "failed" }, 1, "controller", "primary phase returned")?
  if primary_pass {
    runtime.emit_event(event_template, run_dir, "85-primary-validated", primary_subject, "validated", 1, "controller", "primary phase report.json passed")?
  }

  var reeval_pass_for_result = selected_ticket == ""
  var worktree_cleanup_ok = selected_ticket == ""
  if selected_ticket != "" {
    reeval_pass_for_result = primary_pass
    worktree_cleanup_ok = primary_pass
    for ticket_id in selected_tickets {
      let ticket_path = fp"${factory_dir}/tickets/${ticket_id}.md"
      let ticket_eval_id = control.ticket_eval(ticket_path.read_text()?)
      let ticket_reeval_phase = fp"${phases_dir}/02-reeval-${ticket_id}"
      let ticket_reeval_request = fp"${phase_requests_dir}/02-reeval-${ticket_id}.md"
      let ticket_worktree = fp"${primary_phase}/worktrees/${ticket_id}"
      let ticket_patch = fp"${primary_phase}/patches/${ticket_id}.diff"
      fs.mkdir(ticket_reeval_phase)?
      phase_request(phase_template, ticket_reeval_request, "eval", ticket_eval_id, trial_count, 0,
        f"`${ticket_id}`", f"Validate the ${ticket_id} implementation against the linked ${ticket_eval_id} eval before merge.")?
      let ticket_candidate = ticket_worktree.display()
      runtime.emit_event(event_template, run_dir, "10-reeval-started", f"${ticket_id}-reevaluation", "started", 1, "organization", "validated engineer worktree is available")?
      # In reuse mode no engineer worker report exists (the branch is reused,
      # not re-implemented), so the validated phase report is the precondition
      # for the linked candidate replay; otherwise require the engineer worker
      # report. Without this, reuse mode short-circuited the replay child and
      # the linked re-evaluation was never dispatched.
      let ticket_primary_pass = if reuse_existing_branch {
        phase_run_pass(primary_phase, "report.json")?
      } else {
        ticket_worker_pass(primary_phase, ticket_id)?
      }
      let reeval_ok = ticket_primary_pass and run_child(
        reeval_controller, ticket_reeval_request, ticket_reeval_phase, factory_dir,
        ticket_worktree, run_dir, xsh_commit.trim(), run_agent,
        auth_file, pi_command, docker, target, platform,
        ["FACTORY_MODE=eval", f"FACTORY_EVAL_ID=${ticket_eval_id}",
          f"FACTORY_REEVAL_TICKET=${ticket_id}",
          f"FACTORY_REEVAL_WORKTREE=${ticket_candidate}",
          "FACTORY_SKIP_TICKET_RECONCILE=true"],
        fp"${run_dir}/reeval-${ticket_id}.stdout", fp"${run_dir}/reeval-${ticket_id}.stderr"
      )?
      let reeval_report_ok = phase_run_pass(ticket_reeval_phase, "report.json")?
      let reeval_pass = reeval_ok and reeval_report_ok
      reeval_pass_for_result = reeval_pass_for_result and reeval_pass
      let reeval_exit = if reeval_pass { 0 } else { 1 }
      runtime.emit_process_output(run_dir, f"reeval-${ticket_id}", "stdout", fp"${run_dir}/reeval-${ticket_id}.stdout", reeval_exit)?
      runtime.emit_process_output(run_dir, f"reeval-${ticket_id}", "stderr", fp"${run_dir}/reeval-${ticket_id}.stderr", reeval_exit)?
      runtime.emit_event(event_template, run_dir, "80-reeval-completed", f"${ticket_id}-reevaluation",
        if reeval_pass { "completed" } else { "failed" }, 1, "controller", "candidate re-evaluation returned")?
      if reeval_pass {
        runtime.emit_event(event_template, run_dir, "85-reeval-validated", f"${ticket_id}-reevaluation", "validated", 1, "controller", "candidate re-evaluation report.json passed")?
      }
      let patch_ready = ticket_primary_pass and fs.exists(ticket_patch)?
      let cleaned = patch_ready and reeval_pass and runtime.remove_clean_worktree(xsh_repo, ticket_worktree)?
      worktree_cleanup_ok = worktree_cleanup_ok and cleaned
    }
  }

  let final_worktree_cleanup_ok = runtime.remove_run_worktrees(xsh_repo, run_dir)?
  worktree_cleanup_ok = worktree_cleanup_ok and final_worktree_cleanup_ok

  var independent_eval_state = if selected_ticket == "" { "not-applicable" } else { "not-run" }
  var independent_eval_report_state = if selected_ticket == "" { "not-applicable" } else { "not-run" }
  if selected_ticket != "" {
    let independent_eval_ok = if independent_eval_handles.len() == 1 {
      wait_child(independent_eval_handles[0])?
    } else {
      false
    }
    let independent_eval_report_ok = phase_run_pass(independent_eval_phase, "report.json")?
    let independent_eval_pass = independent_eval_ok and independent_eval_report_ok
    let independent_eval_exit = if independent_eval_pass { 0 } else { 1 }
    runtime.emit_process_output(run_dir, f"independent-eval-${requested_eval}", "stdout", fp"${run_dir}/independent-eval.stdout", independent_eval_exit)?
    runtime.emit_process_output(run_dir, f"independent-eval-${requested_eval}", "stderr", fp"${run_dir}/independent-eval.stderr", independent_eval_exit)?
    independent_eval_state = if independent_eval_pass { "pass" } else { "fail" }
    independent_eval_report_state = if independent_eval_report_ok { "pass" } else { "missing-or-failed" }
    runtime.emit_event(event_template, run_dir, "80-independent-eval-completed", requested_eval,
      if independent_eval_pass { "completed" } else { "failed" }, 1, "controller", "independent eval phase returned")?
    if independent_eval_pass {
      runtime.emit_event(event_template, run_dir, "85-independent-eval-validated", requested_eval, "validated", 1, "controller", "independent eval report.json passed")?
    }
  }

  var design_state = "not-requested"
  var design_report_state = "not-requested"
  if design_handle != null {
    let design_ok = wait_child(design_handle)?
    let design_report_ok = phase_run_pass(design_phase, "report.json")?
    let design_pass = design_ok and design_report_ok
    let design_exit = if design_pass { 0 } else { 1 }
    runtime.emit_process_output(run_dir, "eval-design", "stdout", fp"${run_dir}/design.stdout", design_exit)?
    runtime.emit_process_output(run_dir, "eval-design", "stderr", fp"${run_dir}/design.stderr", design_exit)?
    design_state = if design_pass { "pass" } else { "fail" }
    design_report_state = if design_report_ok { "pass" } else { "missing-or-failed" }
    runtime.emit_event(event_template, run_dir, "80-design-completed", "eval-design",
      if design_pass { "completed" } else { "failed" }, 1, "controller", "eval-design phase returned")?
    if design_pass {
      runtime.emit_event(event_template, run_dir, "85-design-validated", "eval-design", "validated", 1, "controller", "eval-design report.json passed")?
    }
  }

  let xsh_path = process.which("xsh")?
  let audit_status = process.run(process.command_argv(
    xsh_path,
    [xsh_path.display(), fp"${factory_dir}/audit-run.xsh", "--", run_dir.display(), "organization"],
    cwd: factory_dir,
  ))?
  let audit_file = fp"${run_dir}/report.json"
  let audit_report_ok = audit_status.ok and fs.exists(audit_file)? and schema.valid(json.read(audit_file)?, "run")
  let audit_result = if audit_report_ok { schema.value_text(json.get(json.read(audit_file)?, ["result"], "missing")) } else { "missing" }
  let audit_pass = audit_report_ok and audit_result == "pass"
  let independent_eval_pass_for_result = if selected_ticket == "" { true } else { independent_eval_state == "pass" }
  let design_pass_for_result = design_state == "pass" or design_state == "not-requested"
  let initial_result = if primary_pass and reeval_pass_for_result and independent_eval_pass_for_result and design_pass_for_result and worktree_cleanup_ok and audit_pass { "pass" } else { "fail" }
  let cto_status = runtime.write_cto_report(factory_dir, run_dir, initial_result)?
  let result = if initial_result == "pass" and cto_status { "pass" } else { "fail" }
  runtime.emit_event(event_template, run_dir, if result == "pass" { "90-cycle-completed" } else { "90-cycle-failed" },
    "organization", if result == "pass" { "completed" } else { "failed" }, 1, "controller", "organization report.json and phase reports written")?
  if result == "pass" {
    runtime.emit_event(event_template, run_dir, "95-cycle-validated", "organization", "validated", 1, "controller", "all required phases passed")?
  }
  if ! skip_cycle_budget {
    runtime.stop_cycle_budget_watch(run_dir)?
  }
  print f"factory organization run: ${run_dir} (${result})"
  abort(if result == "pass" { 0 } else { 1 })
}
