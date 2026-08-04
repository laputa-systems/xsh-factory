##! Ticket-cycle controller. The parent run.xsh owns signals.

use factory_control as control
use factory_runtime as runtime
use report_schema as schema

# Starts one controller-assigned engineer through the shared worker runner.
# The controller owns the exact row; no paid agent decides what to launch.
proc spawn_engineer(
  factory_dir: Path,
  run_dir: Path,
  xsh_repo: Path,
  run_agent: Path,
  auth_file: Path,
  pi_command: Str,
  platform: Str,
  xsh_commit: Str,
  ticket_id: Str,
  worktree: Path,
  assignment: Path,
) [fs, process, env, error] -> Result[ProcessHandle] {
  let xsh_path = process.which("xsh")?
  let engineer_env = {
    PATH: env.get("PATH")?,
    HOME: env.get("HOME")?,
    XSH_MODULE_PATH: env.get_or("XSH_MODULE_PATH", factory_dir.display())?,
    FACTORY_DIR: factory_dir.display(),
    FACTORY_RUN_DIR: run_dir.display(),
    FACTORY_RUN_AGENT: run_agent.display(),
    FACTORY_XSH_REPO: xsh_repo.display(),
    FACTORY_XSH_COMMIT: xsh_commit,
    FACTORY_MODE: "ticket-implementation",
    FACTORY_PARENT_ID: "controller",
    FACTORY_TICKET_ID: ticket_id,
    FACTORY_ASSIGNMENT_SHA: hash.sha256(assignment)?.hex(),
    FACTORY_WORKDIR: worktree.display(),
    FACTORY_HANDBOOK_FILE: fp"${factory_dir}/runtime/handbook.md".display(),
    FACTORY_NORTH_STAR_FILE: fp"${factory_dir}/NORTH-STAR.md".display(),
    FACTORY_PLATFORM: platform,
    FACTORY_ENGINEER_PROVIDER: control.configured_role_setting("engineer", "PROVIDER")?,
    FACTORY_ENGINEER_MODEL: control.configured_role_setting("engineer", "MODEL")?,
    FACTORY_ENGINEER_THINKING: control.configured_role_setting("engineer", "THINKING")?,
    FACTORY_ENGINEER_BUDGET_USD: control.configured_role_setting("engineer", "BUDGET_USD")?,
    FACTORY_ENGINEER_MAX_TURNS: control.configured_role_setting("engineer", "MAX_TURNS")?,
    FACTORY_ENGINEER_MAX_WALL_SECONDS: control.configured_role_setting("engineer", "MAX_WALL_SECONDS")?,
    FACTORY_ENGINEER_TOOLS: control.configured_role_setting("engineer", "TOOLS")?,
    PI_AUTH_FILE: auth_file.display(),
    PI_COMMAND: pi_command,
  }
  let worker_dir = fp"${run_dir}/workers/engineer/${ticket_id}"
  fs.mkdir(worker_dir)?
  return spawn process.command_argv(
    xsh_path,
    [xsh_path.display(), run_agent.display(), "--", "engineer", ticket_id,
      fp"${factory_dir}/roles/engineer.md".display(), assignment.display()],
    cwd: factory_dir,
    env: engineer_env,
    stdout: fp"${run_dir}/engineer-${ticket_id}.stdout",
    stderr: fp"${run_dir}/engineer-${ticket_id}.stderr",
  )
}

proc run_ticket_cycle(
  request: Path,
  factory_dir: Path,
  xsh_repo: Path,
  auth_file: Path,
  run_agent: Path,
  pi_command: Str,
) [fs, process, env, time, error, io] -> Result[Int] {
  let tickets = control.request_tickets(request.read_text()?)
  if tickets.len() == 0 {
    eprint "ticket-implementation cycle has no approved tickets"
    return 1
  }
  if tickets.len() > control.max_concurrent_engineers() {
    eprint f"ticket-implementation cycles admit at most ${control.max_concurrent_engineers()} engineer tickets"
    return 1
  }
  let xsh_path = process.which("xsh")?
  let stamp = time.now()
  let configured_phase_dir = env.get_or("FACTORY_PHASE_DIR", "")?
  let run_dir = if configured_phase_dir == "" {
    fp"${factory_dir}/runs/run-${stamp}"
  } else {
    Path(configured_phase_dir)
  }
  let active_run = env.path("FACTORY_ACTIVE_RUN", fp"${factory_dir}/runs/ACTIVE")?
  let lock_path = env.path("FACTORY_LOCK_PATH", fp"${factory_dir}/runs/factory.lock")?
  let _run_lock = runtime.acquire_run_lock_at(lock_path)?
  let worktree_root = fp"${run_dir}/worktrees"
  let patch_root = fp"${run_dir}/patches"
  let event_template = run_dir
  let assignment_template = fp"${factory_dir}/templates/ENGINEER-ASSIGNMENT.md"
  let assignment_template_text = assignment_template.read_text()?
  let platform = env.get_or("FACTORY_PLATFORM", "linux/arm64")?
  fs.mkdir(fp"${factory_dir}/runs")?
  if fs.exists(active_run)? and fs.read_text(active_run)?.trim() != "" {
    eprint "another factory run is already active"
    return 1
  }
  fs.mkdir(run_dir)?
  fs.mkdir(worktree_root)?
  fs.mkdir(patch_root)?
  fs.mkdir(fp"${run_dir}/messages")?
  fs.mkdir(fp"${run_dir}/tickets")?
  runtime.stage_cto_improvement(factory_dir, run_dir)?
  runtime.register_cycle_controller(run_dir)?
  let skip_cycle_budget = env.get_or("FACTORY_SKIP_CYCLE_BUDGET", "false")? == "true"
  let retain_worktree = env.get_or("FACTORY_RETAIN_WORKTREE", "false")? == "true"
  if ! retain_worktree {
    defer runtime.cleanup_run_worktrees(xsh_repo, run_dir)?
  }
  if ! skip_cycle_budget {
    let _cycle_budget_watch = runtime.start_cycle_budget_watch(factory_dir, run_dir)?
  }
  fs.write(active_run, run_dir.display() + "\n")?
  defer fs.remove(active_run, missing_ok: true)?
  fs.copy(request, fp"${run_dir}/CYCLE-REQUEST.md", overwrite: true)?
  runtime.emit_event(event_template, run_dir, "00-cycle-started", "ticket-implementation", "started", 1, "controller", "approved ticket dispatch")?

  let xsh_commit = run.text "git" "-C" $xsh_repo.display() "rev-parse" "HEAD" ?
  let xsh_git_status = run.text "git" "-C" $xsh_repo.display() "status" "--porcelain" ?
  if xsh_git_status.trim() != "" {
    eprint "ticket-implementation requires a clean XSH worktree at admission"
    return 1
  }
  let _merged_tickets = runtime.reconcile_tickets(factory_dir, xsh_repo, xsh_commit.trim())?

  for ticket_id in tickets {
    if ! control.valid_ticket_id(ticket_id) {
      eprint f"unsafe ticket id: ${ticket_id}"
      return 1
    }
    let ticket_path = fp"${factory_dir}/tickets/${ticket_id}.md"
    if ! runtime.accepted_ticket(ticket_path)? {
      let ticket_text = if fs.exists(ticket_path)? { ticket_path.read_text()? } else { "" }
      if control.ticket_is_merged(ticket_text) {
        eprint f"ticket ${ticket_id} is already Merged; run its linked eval cycle for acceptance"
      } else {
        eprint f"ticket is missing or not Approved: ${ticket_id}"
      }
      runtime.emit_event(event_template, run_dir, f"ticket-${ticket_id}-rejected", ticket_id, "failed", 1, "admission", "ticket is not checked-in with Approved status")?
      return 1
    }
    let open_branch = runtime.open_ticket_branch(xsh_repo, ticket_id)?
    if open_branch != "" {
      eprint f"ticket ${ticket_id} already has an unmerged implementation branch: ${open_branch}"
      eprint "replay or review that branch before dispatching another engineer"
      return 1
    }
    let worktree = fp"${worktree_root}/${ticket_id}"
    let branch = f"factory/${ticket_id}/${stamp}"
    let worktree_stdout = fp"${run_dir}/worktrees/${ticket_id}.stdout"
    let worktree_stderr = fp"${run_dir}/worktrees/${ticket_id}.stderr"
    let worktree_status = process.run(process.command_argv(
      "git",
      ["git", "-C", xsh_repo.display(), "worktree", "add", "-b", branch, worktree.display(), xsh_commit.trim()],
      stdout: worktree_stdout,
      stderr: worktree_stderr,
    ))?
    if ! worktree_status.ok {
      eprint f"unable to create XSH worktree for ${ticket_id}"
      runtime.emit_event(event_template, run_dir, f"ticket-${ticket_id}-worktree", ticket_id, "failed", 1, "admission", "git worktree add failed")?
      return 1
    }
    fs.copy(ticket_path, fp"${run_dir}/tickets/${ticket_id}.md", overwrite: true)?
    let ticket_sha = hash.sha256(ticket_path)?.hex()
    let ticket_text = ticket_path.read_text()?
    let assignment_values: List[control.TemplateValue] = [
      {key: "TICKET_ID", value: ticket_id},
      {key: "TICKET_PATH", value: fp"${run_dir}/tickets/${ticket_id}.md".display()},
      {key: "TICKET_SHA", value: ticket_sha},
      {key: "WORKTREE", value: worktree.display()},
      {key: "BRANCH", value: branch},
      {key: "XSH_COMMIT", value: xsh_commit.trim()},
      {key: "ENGINEER_REPORT", value: fp"${run_dir}/workers/engineer/${ticket_id}/REPORT.md".display()},
      {key: "FACTORY_DIR", value: factory_dir.display()},
      {key: "FACTORY_RUN_DIR", value: run_dir.display()},
      {key: "NORTH_STAR_FILE", value: fp"${factory_dir}/NORTH-STAR.md".display()},
      {key: "HANDBOOK_FILE", value: fp"${factory_dir}/runtime/handbook.md".display()},
      {key: "XSH_AGENTS_FILE", value: fp"${worktree}/AGENTS.md".display()},
      {key: "XSH_RATIONALE_FILE", value: fp"${worktree}/docs/CHAPTER-01-why-xsh.md".display()},
      {key: "TICKET_TEXT", value: ticket_text},
    ]
    let assignment = control.fill_template(assignment_template_text, assignment_values)
    let assignment_path = fp"${run_dir}/messages/${ticket_id}.md"
    fs.write(assignment_path, assignment)?
    runtime.emit_event(event_template, run_dir, f"10-ticket-${ticket_id}-admitted", ticket_id, "admitted", 1, "admission", f"worktree ${worktree.display()} on ${branch}")?
  }
  let _initial_report = process.run(process.command_argv(
    xsh_path,
    [xsh_path.display(), fp"${factory_dir}/audit-run.xsh", "--", run_dir.display(), "ticket-implementation"],
    cwd: factory_dir,
  ))?

  let director_message = fp"${run_dir}/DIRECTOR-REQUEST.md"
  let director_template = fp"${factory_dir}/templates/DIRECTOR-REQUEST.md"
  let director_values: List[control.TemplateValue] = [
    {key: "FACTORY_DIR", value: factory_dir.display()},
    {key: "RUN_DIR", value: run_dir.display()},
    {key: "RUN_AGENT", value: run_agent.display()},
    {key: "MODE", value: "ticket-implementation"},
    {key: "EXECUTION_DIRECTIVE", value: "The controller has already launched every assigned engineer row concurrently through the shared runner. Do not launch engineers or eval roles. Inspect each completed worker report and write the director reconciliation report."},
  ]
  fs.write(director_message, control.fill_template(director_template.read_text()?, director_values))?

  var engineer_handles: List[ProcessHandle] = []
  runtime.emit_event(event_template, run_dir, "20-director-started", "director", "started", 1, "controller", "controller-dispatching engineers; director will reconcile")?
  for ticket_id in tickets {
    let assignment = fp"${run_dir}/messages/${ticket_id}.md"
    let worktree = fp"${worktree_root}/${ticket_id}"
    runtime.emit_event(event_template, run_dir, f"20-ticket-${ticket_id}-started", ticket_id, "started", 1, "controller", "controller-dispatching engineer worker")?
    engineer_handles = engineer_handles.push(spawn_engineer(
      factory_dir, run_dir, xsh_repo, run_agent, auth_file, pi_command, platform,
      xsh_commit.trim(), ticket_id, worktree, assignment
    )?)
  }
  var engineer_dispatch_ok = true
  for handle in engineer_handles {
    let engineer_status = wait handle?
    engineer_dispatch_ok = engineer_dispatch_ok and engineer_status.ok
  }

  let director_env = {
    PATH: env.get("PATH")?,
    HOME: env.get("HOME")?,
    XSH_MODULE_PATH: env.get_or("XSH_MODULE_PATH", factory_dir.display())?,
    FACTORY_DIR: factory_dir.display(),
    FACTORY_RUN_DIR: run_dir.display(),
    FACTORY_RUN_AGENT: run_agent.display(),
    FACTORY_XSH_REPO: xsh_repo.display(),
    FACTORY_XSH_COMMIT: xsh_commit.trim(),
    FACTORY_MODE: "ticket-implementation",
    FACTORY_DIRECTOR_RECONCILE_ONLY: "true",
    FACTORY_EVAL_ID: "",
    FACTORY_TICKET_ID: "",
    FACTORY_WORKDIR: "",
    FACTORY_HANDBOOK_FILE: fp"${factory_dir}/runtime/handbook.md".display(),
    FACTORY_NORTH_STAR_FILE: fp"${factory_dir}/NORTH-STAR.md".display(),
    FACTORY_PLATFORM: platform,
    PI_AUTH_FILE: auth_file.display(),
    PI_COMMAND: pi_command,
    FACTORY_DIRECTOR_PROVIDER: control.configured_role_setting("director", "PROVIDER")?,
    FACTORY_DIRECTOR_MODEL: control.configured_role_setting("director", "MODEL")?,
    FACTORY_DIRECTOR_THINKING: control.configured_role_setting("director", "THINKING")?,
    FACTORY_DIRECTOR_BUDGET_USD: control.configured_role_setting("director", "BUDGET_USD")?,
    FACTORY_DIRECTOR_MAX_TURNS: control.configured_role_setting("director", "MAX_TURNS")?,
    FACTORY_DIRECTOR_MAX_WALL_SECONDS: control.configured_role_setting("director", "MAX_WALL_SECONDS")?,
    FACTORY_DIRECTOR_TOOLS: control.configured_role_setting("director", "TOOLS")?,
    FACTORY_ENGINEER_PROVIDER: control.configured_role_setting("engineer", "PROVIDER")?,
    FACTORY_ENGINEER_MODEL: control.configured_role_setting("engineer", "MODEL")?,
    FACTORY_ENGINEER_THINKING: control.configured_role_setting("engineer", "THINKING")?,
    FACTORY_ENGINEER_BUDGET_USD: control.configured_role_setting("engineer", "BUDGET_USD")?,
    FACTORY_ENGINEER_MAX_TURNS: control.configured_role_setting("engineer", "MAX_TURNS")?,
    FACTORY_ENGINEER_MAX_WALL_SECONDS: control.configured_role_setting("engineer", "MAX_WALL_SECONDS")?,
    FACTORY_ENGINEER_TOOLS: control.configured_role_setting("engineer", "TOOLS")?,
  }
  let director_status = process.run(process.command_argv(
    xsh_path,
    [xsh_path.display(), run_agent.display(), "--", "director", "director",
      fp"${factory_dir}/roles/director.md".display(), fp"${run_dir}/DIRECTOR-REQUEST.md".display()],
    cwd: factory_dir,
    env: director_env,
    stdout: fp"${run_dir}/director.stdout",
    stderr: fp"${run_dir}/director.stderr",
  ))?
  if ! director_status.ok {
    # A director can have launched engineer children before its own session
    # fails or reaches a limit. Drain the controller-owned registry before
    # validating reports so failed dispatch cannot leave paid children alive.
    runtime.cleanup_active_run()?
  }
  runtime.emit_event(event_template, run_dir, "80-director-completed", "director", if director_status.ok { "completed" } else { "failed" }, 1, "director", "director process returned")?
  let director_exit = if director_status.ok { 0 } else { director_status.exit_code() ?? 1 }
  runtime.emit_process_output(run_dir, "director", "stdout", fp"${run_dir}/director.stdout", director_exit)?
  runtime.emit_process_output(run_dir, "director", "stderr", fp"${run_dir}/director.stderr", director_exit)?

  var all_tickets_ok = true
  var all_patches_ok = true
  for ticket_id in tickets {
    let worktree = fp"${worktree_root}/${ticket_id}"
    let worker_dir = fp"${run_dir}/workers/engineer/${ticket_id}"
    let engineer_report = fp"${worker_dir}/REPORT.md"
    let worker_report = fp"${worker_dir}/report.json"
    let session = fp"${worker_dir}/session.jsonl"
    let north_star_read_ok = runtime.session_read_path(session, fp"${factory_dir}/NORTH-STAR.md")?
    let handbook_read_ok = runtime.session_read_path(session, fp"${factory_dir}/runtime/handbook.md")?
    let report_ok = fs.exists(worker_report)? and schema.valid(json.read(worker_report)?, "worker") and
      fs.exists(engineer_report)? and ! fs.exists(fp"${worker_dir}/REPORT-MISSING")? and
      control.engineer_report_contract_ok(fs.read_text(engineer_report)?)
    let branch = run.text "git" "-C" $worktree.display() "branch" "--show-current" ?
    var head = run.text "git" "-C" $worktree.display() "rev-parse" "HEAD" ?
    let status = run.text "git" "-C" $worktree.display() "status" "--porcelain" ?
    let branch_ok = branch.trim() == f"factory/${ticket_id}/${stamp}"
    let commit_ok = head.trim() != xsh_commit.trim()
    let clean = status.trim() == ""
    let ticket_ok = fs.exists(session)? and report_ok and north_star_read_ok and handbook_read_ok and branch_ok and commit_ok and clean
    let assignment_sha = hash.sha256(fp"${run_dir}/messages/${ticket_id}.md")?.hex()
    let patch_path = fp"${patch_root}/${ticket_id}.diff"
    let patch_stderr = fp"${patch_root}/${ticket_id}.stderr"
    let patch_ok = if ticket_ok {
      runtime.write_engineer_patch(worktree, xsh_commit.trim(), head.trim(), patch_path, patch_stderr)?
    } else {
      false
    }
    let patch_sha = if patch_ok { hash.sha256(patch_path)?.hex() } else { "" }
    let provenance_head = if ticket_ok and patch_ok {
      runtime.amend_engineer_commit(
        worktree, head.trim(), factory_dir, run_dir, worker_report, session,
        ticket_id, branch.trim(), xsh_commit.trim(), assignment_sha, patch_sha
      )?
    } else {
      ""
    }
    let provenance_ok = ticket_ok and patch_ok and provenance_head != ""
    if provenance_ok {
      head = provenance_head
      runtime.update_engineer_report_commit(engineer_report, head.trim())?
    }
    if provenance_ok {
      let report_sha = hash.sha256(worker_report)?.hex()
      let session_sha = hash.sha256(session)?.hex()
      let assignment_hash = hash.sha256(fp"${run_dir}/messages/${ticket_id}.md")?.hex()
      let patch_sha = hash.sha256(patch_path)?.hex()
      runtime.emit_event(event_template, run_dir, f"75-ticket-${ticket_id}-provenance", ticket_id,
        "started", 1, "controller",
        f"amended=${head.trim()}; report_sha256=${report_sha}; session_sha256=${session_sha}; assignment_sha256=${assignment_hash}; patch_sha256=${patch_sha}")?
    }
    let worktree_action = if ! ticket_ok {
      "retained-after-validation-failure"
    } else if ! patch_ok {
      "retained-after-patch-failure"
    } else if retain_worktree {
      "retained-for-linked-reevaluation"
    } else if runtime.remove_clean_worktree(xsh_repo, worktree)? {
      "removed-after-patch"
    } else {
      "cleanup-failed"
    }
    let final_ticket_ok = provenance_ok and patch_ok and
      (retain_worktree or worktree_action == "removed-after-patch")
    if ! final_ticket_ok { all_tickets_ok = false }
    if ! patch_ok { all_patches_ok = false }
    if final_ticket_ok {
      runtime.emit_event(event_template, run_dir, f"80-ticket-${ticket_id}-completed", ticket_id, "completed", 1, "engineer", f"branch ${branch.trim()} at ${head.trim()}; north star and handbook read from session log")?
      runtime.emit_event(event_template, run_dir, f"85-ticket-${ticket_id}-validated", ticket_id, "validated", 1, "controller", f"report, patch, branch, commit, and worktree checks passed; ${worktree_action}")?
      runtime.emit_event(event_template, run_dir, f"90-ticket-${ticket_id}-ready", ticket_id, "ready-for-review", 1, "controller", "branch and portable patch are pending CTO review")?
    } else {
      runtime.emit_event(event_template, run_dir, f"80-ticket-${ticket_id}-failed", ticket_id, "failed", 1, "controller", f"worker output, patch, or worktree validation failed for ${ticket_id}")?
    }
  }
  let final_worktree_cleanup_ok = if retain_worktree {
    true
  } else {
    runtime.remove_run_worktrees(xsh_repo, run_dir)?
  }
  let director_report = fp"${run_dir}/workers/director/director/REPORT.md"
  let director_report_ok = fs.exists(director_report)? and
    ! fs.exists(fp"${run_dir}/workers/director/director/REPORT-MISSING")? and
    control.director_report_contract_ok(fs.read_text(director_report)?)
  let audit_status = process.run(process.command_argv(
    xsh_path,
    [xsh_path.display(), fp"${factory_dir}/audit-run.xsh", "--", run_dir.display(), "ticket-implementation"],
    cwd: factory_dir,
  ))?
  let audit_file = fp"${run_dir}/report.json"
  let audit_report_ok = audit_status.ok and fs.exists(audit_file)? and schema.valid(json.read(audit_file)?, "phase")
  let audit_result = if audit_report_ok { schema.value_text(json.get(json.read(audit_file)?, ["result"], "missing")) } else { "missing" }
  let audit_pass = audit_report_ok and audit_result == "pass"
  if audit_pass {
    runtime.mark_phase_completed(event_template, run_dir, "85-cycle-audited", "ticket-implementation",
      1, "controller", "deterministic audit artifact written")?
  } else {
    runtime.emit_event(event_template, run_dir, "85-cycle-audited", "ticket-implementation",
      "failed", 1, "controller", "deterministic audit artifact written")?
  }
  let initial_result = if engineer_dispatch_ok and director_status.ok and all_tickets_ok and all_patches_ok and final_worktree_cleanup_ok and director_report_ok and audit_pass { "pass" } else { "fail" }
  let cto_status = runtime.write_cto_report(factory_dir, run_dir, initial_result)?
  let result = if initial_result == "pass" and cto_status { "pass" } else { "fail" }
  if result == "pass" {
    runtime.emit_event(event_template, run_dir, "90-cycle-completed", "ticket-implementation", "completed", 1, "controller", "structured phase report and review patch written")?
    runtime.emit_event(event_template, run_dir, "95-cycle-validated", "ticket-implementation", "validated", 1, "controller", "all required review outputs passed")?
  } else {
    runtime.emit_event(event_template, run_dir, "90-cycle-failed", "ticket-implementation", "failed", 1, "controller", "one or more required outputs failed")?
  }
  if ! skip_cycle_budget {
    runtime.stop_cycle_budget_watch(run_dir)?
  }
  print f"factory run: ${run_dir} (${result})"
  return if result == "pass" { 0 } else { 1 }
}

proc main(...argv: List[Str]) [fs, process, env, time, error, io] {
  if argv.len() < 1 {
    eprint "usage: run-ticket.xsh CYCLE_REQUEST.md"
    abort(2)
  }
  let factory_dir = env.path("FACTORY_DIR", fs.cwd()?)?
  let request = Path(argv[0])
  let xsh_repo = env.path("FACTORY_XSH_REPO", fp"${factory_dir}/../xsh")?
  let home = env.get("HOME")?
  let auth_file = env.path("PI_AUTH_FILE", fp"${home}/.pi/agent/auth.json")?
  let run_agent = fp"${factory_dir}/run-agent.xsh"
  let pi_command = env.get_or("PI_COMMAND", "pi")?
  abort(run_ticket_cycle(request, factory_dir, xsh_repo, auth_file, run_agent, pi_command)?)
}
