##! Organization-cycle controller for one delivery transaction or one discovery eval.
use factory.control as control
use factory.request as typed_request
use factory.runtime as runtime
use factory.schema as schema

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

  let source_sha = env.get_or("FACTORY_SOURCE_SHA", "")?
  if source_sha != "" {
    assignments = assignments.push("FACTORY_SOURCE_SHA=" + source_sha)
  }

  assignments = assignments.push("FACTORY_ACTIVE_RUN=" + fp"${phase_dir}/ACTIVE".display())
  assignments = assignments.push("FACTORY_LOCK_PATH=" + fp"${phase_dir}/factory.lock".display())
  for role in ["director", "eval-designer", "eval-manager", "eval-worker", "engineer"] {
    let prefix = control.role_prefix(role)
    assignments = assignments.push(f"FACTORY_${prefix}_PROVIDER=${control.configured_role_setting(role, "PROVIDER")?}")
    assignments = assignments.push(f"FACTORY_${prefix}_MODEL=${control.configured_role_setting(role, "MODEL")?}")
    assignments = assignments.push(f"FACTORY_${prefix}_THINKING=${control.configured_role_setting(role, "THINKING")?}")
    assignments = assignments.push(
      f"FACTORY_${prefix}_BUDGET_USD=${control.configured_role_setting(role, "BUDGET_USD")?}",
    )
    assignments = assignments.push(
      f"FACTORY_${prefix}_MAX_TURNS=${control.configured_role_setting(role, "MAX_TURNS")?}",
    )
    assignments = assignments.push(
      f"FACTORY_${prefix}_MAX_WALL_SECONDS=${control.configured_role_setting(role, "MAX_WALL_SECONDS")?}",
    )
    assignments = assignments.push(f"FACTORY_${prefix}_TOOLS=${control.configured_role_setting(role, "TOOLS")?}")
  }

  let child_args = assignments.extend(extra_env)
    .extend([child_runner.display(), child.display(), "--", request.display()])
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
    child,
    request,
    phase_dir,
    factory_dir,
    xsh_repo,
    parent_run,
    base_commit,
    run_agent,
    auth_file,
    pi_command,
    docker,
    target,
    platform,
    extra_env,
    stdout,
    stderr,
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

proc phase_request(
  template: Path,
  output_path: Path,
  mode: Str,
  eval_id: Str,
  trial_count: Int,
  new_eval_count: Int,
  ticket_value: Str,
  objective: Str,
) [fs, error] {
  let values = [
    {
      key: "MODE",
      value: mode,
    },
    {
      key: "EVAL_ID",
      value: eval_id,
    },
    {
      key: "TRIAL_COUNT",
      value: trial_count.float().format(precision: 0),
    },
    {
      key: "NEW_EVAL_COUNT",
      value: new_eval_count.float().format(precision: 0),
    },
    {
      key: "TICKET_ID",
      value: ticket_value,
    },
    {
      key: "OBJECTIVE",
      value: objective,
    },
  ]
  fs.write(output_path, control.fill_template(template.read_text()?, values))?
}

proc main(...argv: List[Str]) [fs, process, env, time, error, io] {
  if argv.len() < 1 {
    eprint "usage: xsh factory/controllers/organization.xsh CYCLE_REQUEST.md"
    abort(2)
  }

  let factory_dir = env.path("FACTORY_DIR", fs.cwd()?)?
  let expected_source_sha = env.get_or("FACTORY_SOURCE_SHA", "")?
  if expected_source_sha != "" and ! runtime.verify_factory_source(factory_dir, expected_source_sha)? {
    eprint "factory source changed before organization admission"
    abort(1)
  }

  let request = fp"${argv[0]}"
  let request_text = request.read_text()?
  if typed_request.mode_value(request_text)? != "organization" {
    eprint "organization controller requires a request with mode organization"
    abort(2)
  }

  let trial_count = typed_request.trial_value(request_text)?
  if trial_count < 1 or trial_count > 2 {
    eprint f"unsupported trial count: ${trial_count} (expected 1 or 2)"
    abort(2)
  }

  let new_eval_count = typed_request.design_value(request_text)?
  if new_eval_count < 0 or new_eval_count > 1 {
    eprint "organization cycles allow zero or one eval-design proposal"
    abort(2)
  }

  let design_requested = new_eval_count == 1
  let requested_tickets = typed_request.ticket_values(request_text)?
  if requested_tickets.len() > 1 {
    eprint "organization cycles admit exactly one ticket at most"
    abort(2)
  }

  let xsh_repo = env.path("FACTORY_XSH_REPO", fp"${factory_dir}/../xsh")?
  let xsh_commit = run.text "git" "-C" $xsh_repo "rev-parse" "HEAD" ?
  let xsh_git_status = run.text "git" "-C" $xsh_repo "status" "--porcelain" ?
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

  let _ = fs.lock(fp"${factory_dir}/runs/organization.lock", nonblocking: true)?
  fs.mkdir(run_dir)?
  defer runtime.cleanup_run_worktrees(xsh_repo, run_dir)?
  let retired_tickets = runtime.close_tickets_for_retired_evals(factory_dir)?
  let archived_retired_branches = runtime.archive_retired_ticket_branches(xsh_repo, factory_dir)?
  if retired_tickets.len() > 0 or archived_retired_branches > 0 {
    eprint f"director lifecycle reconciliation closed ${retired_tickets.len()} retired-eval ticket(s) and archived ${archived_retired_branches} branch(es)"
  }

  runtime.write_cto_inventory(factory_dir, run_dir, xsh_repo)?
  let ticket_inventory = runtime.cto_ticket_inventory(factory_dir, xsh_repo)?
  let unreviewed_tickets = runtime.cto_unreviewed_open_tickets(ticket_inventory)
  if unreviewed_tickets.len() > 0 {
    eprint f"CTO review required for Open tickets before organization admission: ${unreviewed_tickets.join(", ")}"
    abort(1)
  }

  runtime.stage_cto_improvement(factory_dir, run_dir)?
  runtime.stage_cto_productivity_report(factory_dir, run_dir)?
  runtime.register_cycle_controller(run_dir)?
  defer runtime.unregister_cycle_controller(run_dir)?
  let skip_cycle_budget = env.get_or("FACTORY_SKIP_CYCLE_BUDGET", "false")? == "true"
  if ! skip_cycle_budget {
    let _ = runtime.start_cycle_budget_watch(factory_dir, run_dir)?
  }

  fs.write(active_run, run_dir.display() + "\n")?
  defer fs.remove(active_run, missing_ok: true)?
  let _ = runtime.reconcile_tickets(factory_dir, xsh_repo, xsh_commit.trim())?
  let queue_counts = runtime.organization_ticket_counts(factory_dir, xsh_repo)?
  let approved_count = queue_counts.get(1, 0)
  let engineer_target = control.organization_ticket_target(approved_count)
  let ticket_policy = typed_request.ticket_policy_value(request_text)?
  let selected_tickets = if requested_tickets.len() > 0 {
    requested_tickets
  } else if ticket_policy == "none" {
    []
  } else {
    runtime.adaptive_approved_tickets(factory_dir, xsh_repo, engineer_target)?
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
  if selected_ticket != "" and control.ticket_change_target(selected_ticket_path.read_text()?) != "product" {
    eprint f"ticket ${selected_ticket} is not a product ticket; CTO owns factory changes and no engineer was dispatched"
    abort(2)
  }

  if selected_ticket != "" {
    let selected_text = selected_ticket_path.read_text()?
    if ! control.ticket_is_accepted(selected_text) {
      eprint f"selected ticket is missing or not Approved: ${selected_ticket}"
      abort(2)
    }

    if ! control.ticket_api_surface_gate_ok(selected_text) {
      eprint f"selected ticket fails the API-surface gate: ${selected_ticket}"
      abort(2)
    }
  }

  for ticket_id in selected_tickets {
    let ticket_path = fp"${factory_dir}/tickets/${ticket_id}.md"
    if control.ticket_change_target(ticket_path.read_text()?) != "product" {
      eprint f"ticket ${ticket_id} is not a product ticket; CTO owns factory changes and no engineer was dispatched"
      abort(2)
    }

    let ticket_text = ticket_path.read_text()?
    if ! control.valid_ticket_id(ticket_id) or ! control.ticket_is_accepted(ticket_text) {
      eprint f"selected ticket is missing or not Approved: ${ticket_id}"
      abort(2)
    }

    if ! control.ticket_api_surface_gate_ok(ticket_text) {
      eprint f"selected ticket fails the API-surface gate: ${ticket_id}"
      abort(2)
    }

    let ticket_eval_id = control.ticket_eval(ticket_path.read_text()?)
    let ticket_eval_path = fp"${factory_dir}/evals/${ticket_eval_id}/EVAL.md"
    let ticket_eval_available = ticket_eval_id != "" and fs.exists(ticket_eval_path)? and ! control.eval_is_disabled(
      ticket_eval_path.read_text()?,
    )
    if ! ticket_eval_available {
      eprint f"selected ticket ${ticket_id} links unsupported or disabled eval: ${ticket_eval_id}"
      abort(2)
    }

    let open_branch = runtime.open_ticket_branch(xsh_repo, ticket_id)?
    if open_branch != "" {
      eprint f"ticket ${ticket_id} already has an unmerged implementation branch: ${open_branch}"
      eprint "review or supersede that branch before dispatching another engineer"
      abort(2)
    }
  }

  let requested_evals = typed_request.eval_values(request_text)?
  let adaptive_eval_limit = control.organization_eval_target(selected_tickets.len())
  let request_evals = if requested_evals.len() == 0 {
    runtime.adaptive_approved_evals(factory_dir, adaptive_eval_limit)?
  } else {
    requested_evals
  }
  if selected_ticket != "" and requested_evals.len() > 0 {
    eprint "ticket organization cycles do not admit an independent eval"
    abort(2)
  }
  if selected_ticket == "" and requested_evals.len() > 0 {
    let expected_evals = runtime.adaptive_approved_evals(factory_dir, 1)?
    if requested_evals != expected_evals {
      eprint f"organization request must select the least-recently-tried approved evals ${expected_evals.join(", ")}; selected ${requested_evals.join(", ")}"
      abort(2)
    }
  }
  if selected_ticket == "" and request_evals.len() != 1 {
    eprint "ticketless organization cycles require exactly one discovery eval"
    abort(2)
  }

  let requested_eval = if request_evals.len() > 0 {
    request_evals[0]
  } else if selected_ticket != "" {
    control.ticket_eval(selected_ticket_path.read_text()?)
  } else {
    ""
  }
  let ticket_eval = if selected_ticket != "" {
    control.ticket_eval(selected_ticket_path.read_text()?)
  } else {
    ""
  }
  for eval_id in request_evals {
    let eval_path = fp"${factory_dir}/evals/${eval_id}/EVAL.md"
    let eval_exists = fs.exists(eval_path)?
    let eval_disabled = eval_exists and control.eval_is_disabled(eval_path.read_text()?)
    if ! control.valid_eval_id(eval_id) or ! eval_exists or eval_disabled {
      eprint f"organization cycle selected unsupported or missing eval: ${eval_id}"
      abort(2)
    }
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
  if selected_ticket != "" and (! control.valid_eval_id(ticket_eval) or ! ticket_eval_exists or ticket_eval_disabled) {
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
  let design_phase = if selected_ticket == "" {
    fp"${phases_dir}/0${request_evals.len() + 1}-eval-design"
  } else {
    fp"${phases_dir}/04-eval-design"
  }
  let primary_request = fp"${phase_requests_dir}/01-primary.md"
  let design_request = if selected_ticket == "" {
    fp"${phase_requests_dir}/0${request_evals.len() + 1}-eval-design.md"
  } else {
    fp"${phase_requests_dir}/04-eval-design.md"
  }
  let event_template = run_dir
  let phase_template = fp"${factory_dir}/templates/ORGANIZATION-PHASE-REQUEST.md"
  let run_agent = fp"${factory_dir}/factory/entrypoints/run-agent.xsh"
  let default_primary_controller = if selected_ticket == "" {
    fp"${factory_dir}/factory/controllers/eval.xsh"
  } else {
    fp"${factory_dir}/factory/controllers/ticket.xsh"
  }
  let primary_controller = env.path("FACTORY_PRIMARY_CONTROLLER", default_primary_controller)?
  let reeval_controller = env.path("FACTORY_REEVAL_CONTROLLER", fp"${factory_dir}/factory/controllers/eval.xsh")?
  let design_controller = env.path("FACTORY_DESIGN_CONTROLLER", fp"${factory_dir}/factory/controllers/design.xsh")?
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

  fs.write(active_run, run_dir.display() + "\n")?
  defer fs.remove(active_run, missing_ok: true)?
  fs.copy(request, fp"${run_dir}/CYCLE-REQUEST.md", overwrite: true)?
  runtime.emit_event(
    event_template,
    run_dir,
    "00-cycle-started",
    "organization",
    "started",
    1,
    "controller",
    "bounded organization cycle with one delivery transaction or one discovery eval",
  )?
  runtime.emit_event(
    event_template,
    run_dir,
    "05-adaptive-queue-selected",
    "organization-queue",
    "started",
    1,
    "controller",
    f"open=${queue_counts.get(0, 0)}; approved=${queue_counts.get(1, 0)}; engineers=${engineer_target}; independent_eval_target=${adaptive_eval_limit}; independent_evals=${request_evals.len()}; linked_replay=mandatory; discovery=least-recently-tried",
  )?

  for ticket_id in selected_tickets {
    runtime.emit_structured_event(
      event_template,
      run_dir,
      "06-ticket-admitted",
      ticket_id,
      {
        status: "admitted",
        delivery_target: true,
      },
    )?
  }

  var ticket_value = "None."
  if selected_tickets.len() > 0 {
    ticket_value = ""
    for ticket_id in selected_tickets {
      ticket_value = if ticket_value == "" { f"`${ticket_id}`" } else { f"""${ticket_value}
- `${ticket_id}`""" }
    }
  }

  let primary_objective = if selected_ticket == "" {
    f"Run one fresh ${selected_eval} eval because no approved ticket was admitted."
  } else {
    f"Implement the approved ticket rows ${ticket_value} in isolated XSH worktrees; every passing engineer row receives a linked pre-merge replay."
  }
  phase_request(
    phase_template,
    primary_request,
    primary_mode,
    selected_eval,
    trial_count,
    0,
    ticket_value,
    primary_objective,
  )?

  if design_requested {
    phase_request(
      phase_template,
      design_request,
      "eval-design",
      requested_eval,
      1,
      1,
      "None.",
      "Design and dry-run one substantive eval proposal meeting the difficulty gate for CTO review.",
    )?
  }

  var design_handle: ProcessHandle? = null
  if design_requested {
    runtime.emit_event(
      event_template,
      run_dir,
      "10-design-started",
      "eval-design",
      "started",
      1,
      "organization",
      "one independent eval-design phase was requested",
    )?
    design_handle = spawn_child(
      design_controller,
      design_request,
      design_phase,
      factory_dir,
      xsh_repo,
      run_dir,
      xsh_commit.trim(),
      run_agent,
      auth_file,
      pi_command,
      docker,
      target,
      platform,
      ["FACTORY_MODE=eval-design", f"FACTORY_EVAL_ID=${requested_eval}"],
      fp"${run_dir}/design.stdout",
      fp"${run_dir}/design.stderr",
    )?
  }

  let primary_subject = if selected_ticket == "" {
    selected_eval
  } else {
    selected_ticket
  }
  runtime.emit_event(
    event_template,
    run_dir,
    "10-primary-started",
    primary_subject,
    "started",
    1,
    "organization",
    primary_mode,
  )?

  let primary_handle = spawn_child(
    primary_controller,
    primary_request,
    primary_phase,
    factory_dir,
    xsh_repo,
    run_dir,
    xsh_commit.trim(),
    run_agent,
    auth_file,
    pi_command,
    docker,
    target,
    platform,
    [
      f"FACTORY_MODE=${primary_mode}",
      f"FACTORY_EVAL_ID=${selected_eval}",
      "FACTORY_REEVAL_TICKET=not-reevaluation",
      "FACTORY_REEVAL_WORKTREE=not-reevaluation",
      "FACTORY_SKIP_TICKET_RECONCILE=false",
      "FACTORY_RETAIN_WORKTREE=true",
    ],
    fp"${run_dir}/primary.stdout",
    fp"${run_dir}/primary.stderr",
  )?
  let primary_ok = wait_child(primary_handle)?
  let primary_report_ok = phase_run_pass(primary_phase, "report.json")?
  let primary_pass = primary_ok and primary_report_ok
  runtime.emit_event(
    event_template,
    run_dir,
    "80-primary-completed",
    primary_subject,
    if primary_pass {
      "completed"
    } else {
      "failed"
    },
    1,
    "controller",
    "primary phase returned",
  )?
  if primary_pass {
    runtime.emit_event(
      event_template,
      run_dir,
      "85-primary-validated",
      primary_subject,
      "validated",
      1,
      "controller",
      "primary phase report.json passed",
    )?
  }

  # Admit every ticket whose own primary evidence passed before waiting for
  # any linked replay. The replay processes may overlap in isolated worktrees;
  # only the merge step below is serialized on XSH main.
  var reeval_pass_for_result = selected_ticket == ""
  var worktree_cleanup_ok = true
  var delivery_ok = selected_tickets.len() == 0
  var reeval_ticket_ids: List[Str] = []
  var reeval_ticket_worktrees: List[Path] = []
  var reeval_ticket_patches: List[Path] = []
  var reeval_handles: List[ProcessHandle] = []
  if selected_ticket != "" {
    reeval_pass_for_result = true
    delivery_ok = true

    # Every admitted row is a fresh engineer implementation. Its own worker
    # report is the precondition for an isolated linked replay, so one failed
    # ticket does not suppress another row's validation.
    for ticket_id in selected_tickets {
      let ticket_path = fp"${factory_dir}/tickets/${ticket_id}.md"
      let ticket_eval_id = control.ticket_eval(ticket_path.read_text()?)
      let ticket_reeval_phase = fp"${phases_dir}/02-reeval-${ticket_id}"
      let ticket_reeval_request = fp"${phase_requests_dir}/02-reeval-${ticket_id}.md"
      let ticket_worktree = runtime.ticket_worktree_path(xsh_repo, primary_phase, ticket_id)
      let ticket_patch = fp"${primary_phase}/patches/${ticket_id}.diff"
      fs.mkdir(ticket_reeval_phase)?
      phase_request(
        phase_template,
        ticket_reeval_request,
        "eval",
        ticket_eval_id,
        trial_count,
        0,
        f"`${ticket_id}`",
        f"Validate the ${ticket_id} implementation against the linked ${ticket_eval_id} eval before merge.",
      )?

      let ticket_primary_pass = ticket_worker_pass(primary_phase, ticket_id)?
      if ! ticket_primary_pass {
        reeval_pass_for_result = false
        delivery_ok = false
        worktree_cleanup_ok = false
        runtime.emit_structured_event(
          event_template,
          run_dir,
          f"86-ticket-${ticket_id}-delivery-failed",
          ticket_id,
          {
            status: "delivery-failed",
            branch: "",
            implementation_commit: "",
            detail: "primary engineer evidence failed; linked replay was not admitted and branch is preserved for review",
          },
        )?
        continue
      }

      let ticket_candidate = ticket_worktree.display()
      runtime.emit_event(
        event_template,
        run_dir,
        "10-reeval-started",
        f"${ticket_id}-reevaluation",
        "started",
        1,
        "organization",
        "linked replay admitted before waiting on sibling replays",
      )?
      let reeval_handle = spawn_child(
        reeval_controller,
        ticket_reeval_request,
        ticket_reeval_phase,
        factory_dir,
        ticket_worktree,
        run_dir,
        xsh_commit.trim(),
        run_agent,
        auth_file,
        pi_command,
        docker,
        target,
        platform,
        [
          "FACTORY_MODE=eval",
          f"FACTORY_EVAL_ID=${ticket_eval_id}",
          f"FACTORY_REEVAL_TICKET=${ticket_id}",
          f"FACTORY_REEVAL_WORKTREE=${ticket_candidate}",
          "FACTORY_SKIP_TICKET_RECONCILE=true",
        ],
        fp"${run_dir}/reeval-${ticket_id}.stdout",
        fp"${run_dir}/reeval-${ticket_id}.stderr",
      )?
      reeval_ticket_ids = reeval_ticket_ids.push(ticket_id)
      reeval_ticket_worktrees = reeval_ticket_worktrees.push(ticket_worktree)
      reeval_ticket_patches = reeval_ticket_patches.push(ticket_patch)
      reeval_handles = reeval_handles.push(reeval_handle)
    }

    var reeval_wait_index = 0
    for ticket_id in reeval_ticket_ids {
      let reeval_phase = fp"${phases_dir}/02-reeval-${ticket_id}"

      # A controller may return nonzero after writing a complete, passing
      # phase report (for example, a recoverable image/tool subprocess error).
      # Preserve that process status as evidence, but let the validated phase
      # report remain the delivery gate.
      let reeval_process_ok = wait_child(reeval_handles[reeval_wait_index])?
      let reeval_required_outputs = fp"${reeval_phase}/required-outputs.json"
      let reeval_required_ok = fs.exists(reeval_required_outputs)? and json.get(
        json.read(reeval_required_outputs)?,
        ["required"],
        false,
      ) == true
      let reeval_report_ok = phase_run_pass(reeval_phase, "report.json")? and reeval_required_ok
      let reeval_pass = reeval_report_ok
      reeval_pass_for_result = reeval_pass_for_result and reeval_pass
      let delivery = if reeval_pass {
        runtime.merge_validated_ticket(
          xsh_repo,
          primary_phase,
          ticket_id,
          xsh_commit.trim(),
        )?
      } else {
        {
          merged: false,
          ticket_id: ticket_id,
          branch: "",
          implementation_commit: "",
        }
      }

      delivery_ok = delivery_ok and delivery.merged
      runtime.emit_structured_event(
        event_template,
        run_dir,
        if delivery.merged {
          f"86-ticket-${ticket_id}-delivered"
        } else {
          f"86-ticket-${ticket_id}-delivery-failed"
        },
        ticket_id,
        {
          status: if delivery.merged {
            "delivered"
          } else {
            "delivery-failed"
          },
          branch: delivery.branch,
          implementation_commit: delivery.implementation_commit,
          detail: if delivery.merged {
            f"${delivery.implementation_commit} is now reachable from XSH HEAD"
          } else {
            "linked replay or exact merge failed; branch is preserved for review"
          },
        },
      )?
      let reeval_exit = if reeval_process_ok { 0 } else { 1 }
      runtime.emit_process_output(
        run_dir,
        f"reeval-${ticket_id}",
        "stdout",
        fp"${run_dir}/reeval-${ticket_id}.stdout",
        reeval_exit,
      )?
      runtime.emit_process_output(
        run_dir,
        f"reeval-${ticket_id}",
        "stderr",
        fp"${run_dir}/reeval-${ticket_id}.stderr",
        reeval_exit,
      )?
      runtime.emit_event(
        event_template,
        run_dir,
        "80-reeval-completed",
        f"${ticket_id}-reevaluation",
        if reeval_pass {
          "completed"
        } else {
          "failed"
        },
        1,
        "controller",
        if reeval_pass {
          if reeval_process_ok {
            "candidate re-evaluation returned with a passing phase report"
          } else {
            "candidate re-evaluation phase report passed; nonzero controller status captured"
          }
        } else {
          "candidate re-evaluation did not produce a passing phase report"
        },
      )?
      if reeval_pass {
        runtime.emit_event(
          event_template,
          run_dir,
          "85-reeval-validated",
          f"${ticket_id}-reevaluation",
          "validated",
          1,
          "controller",
          "candidate re-evaluation report.json passed",
        )?
      }

      # Delivery requires a portable patch before its worktree can be removed.
      let patch_ready = fs.exists(reeval_ticket_patches[reeval_wait_index])?
      let cleanup_allowed = patch_ready and reeval_pass
      let cleaned = cleanup_allowed and runtime.remove_clean_worktree(
        xsh_repo,
        reeval_ticket_worktrees[reeval_wait_index],
      )?
      worktree_cleanup_ok = worktree_cleanup_ok and cleaned
      reeval_wait_index += 1
    }
  }

  let final_worktree_cleanup_ok = runtime.remove_run_worktrees(xsh_repo, run_dir)?
  worktree_cleanup_ok = worktree_cleanup_ok and final_worktree_cleanup_ok
  let delivered_xsh_commit = run.text "git" "-C" $xsh_repo "rev-parse" "HEAD" ?

  # Reconcile only after the primary delivery or discovery phase has closed, so
  # controller-owned lifecycle updates cannot look like a manager mutation.
  let _ = runtime.reconcile_tickets(factory_dir, xsh_repo, delivered_xsh_commit.trim())?

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
    runtime.emit_event(
      event_template,
      run_dir,
      "80-design-completed",
      "eval-design",
      if design_pass {
        "completed"
      } else {
        "failed"
      },
      1,
      "controller",
      "eval-design phase returned",
    )?
    if design_pass {
      runtime.emit_event(
        event_template,
        run_dir,
        "85-design-validated",
        "eval-design",
        "validated",
        1,
        "controller",
        "eval-design report.json passed",
      )?
    }
  }

  let xsh_path = process.which("xsh")?
  let audit_status = process.run(
    process.command_argv(
      xsh_path,
      [xsh_path.display(), fp"${factory_dir}/factory/tools/audit.xsh", "--", run_dir.display(), "organization"],
      cwd: factory_dir,
    ),
  )?
  let audit_file = fp"${run_dir}/report.json"
  let audit_report_ok = audit_status.ok and fs.exists(audit_file)? and schema.valid(json.read(audit_file)?, "run")
  let audit_result = if audit_report_ok {
    schema.value_text(json.get(json.read(audit_file)?, ["result"], "missing"))
  } else {
    "missing"
  }
  let audit_pass = audit_report_ok and audit_result == "pass"
  let design_pass_for_result = design_state == "pass" or design_state == "not-requested"
  let product_result = if selected_ticket == "" or (primary_pass and reeval_pass_for_result and delivery_ok) {
    "pass"
  } else {
    "fail"
  }
  let evaluator_result = if (selected_ticket != "" or primary_pass) and design_pass_for_result { "pass" } else { "fail" }
  let infrastructure_result = if worktree_cleanup_ok and audit_pass { "pass" } else { "fail" }
  let initial_result = if product_result == "pass" and evaluator_result == "pass" and infrastructure_result == "pass" {
    "pass"
  } else {
    "fail"
  }
  let cto_status = runtime.write_cto_report(factory_dir, run_dir, initial_result)?
  let outcome_note = f"product=${product_result}; evaluator=${evaluator_result}; infrastructure=${infrastructure_result}"
  let result = if initial_result == "pass" and cto_status { "pass" } else { "fail" }
  runtime.emit_event(
    event_template,
    run_dir,
    if result == "pass" {
      "90-cycle-completed"
    } else {
      "90-cycle-failed"
    },
    "organization",
    if result == "pass" {
      "completed"
    } else {
      "failed"
    },
    1,
    "controller",
    outcome_note,
  )?
  if result == "pass" {
    runtime.emit_event(
      event_template,
      run_dir,
      "95-cycle-validated",
      "organization",
      "validated",
      1,
      "controller",
      "all required phases passed",
    )?
  }

  if ! skip_cycle_budget {
    runtime.stop_cycle_budget_watch(run_dir)?
  }

  runtime.compress_run_sessions(run_dir)?
  print f"factory organization run: ${run_dir} (${result})"
  abort(if result == "pass" { 0 } else { 1 })
}
