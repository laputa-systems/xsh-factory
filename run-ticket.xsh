##! Ticket-cycle controller. The parent run.xsh owns signals.

use factory_control as control
use factory_runtime as runtime

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
  let event_template = fp"${factory_dir}/templates/EVENT.md"
  let provenance_template = fp"${factory_dir}/templates/PROVENANCE.md"
  let assignment_template = fp"${factory_dir}/templates/XSH-SWE-ASSIGNMENT.md"
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
  runtime.register_cycle_controller(run_dir)?
  let skip_cycle_budget = env.get_or("FACTORY_SKIP_CYCLE_BUDGET", "false")? == "true"
  let retain_worktree = env.get_or("FACTORY_RETAIN_WORKTREE", "false")? == "true"
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

  var dispatch_rows = ""
  var ticket_names = ""
  var ticket_snapshots = ""
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
    ticket_snapshots = if ticket_snapshots == "" { f"${ticket_id}: ${ticket_sha}" } else { ticket_snapshots + f"\n${ticket_id}: ${ticket_sha}" }
    let assignment_values: List[control.TemplateValue] = [
      {key: "TICKET_ID", value: ticket_id},
      {key: "TICKET_PATH", value: fp"${run_dir}/tickets/${ticket_id}.md".display()},
      {key: "TICKET_SHA", value: ticket_sha},
      {key: "WORKTREE", value: worktree.display()},
      {key: "BRANCH", value: branch},
      {key: "XSH_COMMIT", value: xsh_commit.trim()},
      {key: "SWE_REPORT", value: fp"${run_dir}/workers/xsh-swe/${ticket_id}/SWE-REPORT.md".display()},
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
    let assignment_sha = hash.sha256(assignment_path)?.hex()
    let dispatch_row_template = fp"${factory_dir}/templates/TICKET-DISPATCH-ROW.md"
    let dispatch_row_values: List[control.TemplateValue] = [
      {key: "TICKET_ID", value: ticket_id},
      {key: "WORKTREE", value: worktree.display()},
      {key: "BRANCH", value: branch},
      {key: "XSH_COMMIT", value: xsh_commit.trim()},
      {key: "ASSIGNMENT_SHA", value: assignment_sha},
      {key: "RUN_AGENT", value: run_agent.display()},
      {key: "FACTORY_DIR", value: factory_dir.display()},
      {key: "ASSIGNMENT_FILE", value: assignment_path.display()},
    ]
    dispatch_rows = dispatch_rows + control.fill_template(dispatch_row_template.read_text()?, dispatch_row_values)
    ticket_names = if ticket_names == "" { ticket_id } else { ticket_names + ", " + ticket_id }
    runtime.emit_event(event_template, run_dir, f"10-ticket-${ticket_id}-admitted", ticket_id, "admitted", 1, "admission", f"worktree ${worktree.display()} on ${branch}")?
  }
  let dispatch_template = fp"${factory_dir}/templates/TICKET-DISPATCH.md"
  fs.write(fp"${run_dir}/TICKET-DISPATCH.md", control.fill_template(
    dispatch_template.read_text()?, [{key: "ROWS", value: dispatch_rows}]
  ))?
  let provenance_values: List[control.TemplateValue] = [
    {key: "RUN_ID", value: run_dir.display()},
    {key: "MODE", value: "ticket-implementation"},
    {key: "REQUEST", value: "CYCLE-REQUEST.md"},
    {key: "BUILD_ID", value: "not-used-ticket-cycle"},
    {key: "XSH_COMMIT", value: xsh_commit.trim()},
    {key: "CANDIDATE_TICKET", value: "not-reevaluation"},
    {key: "CANDIDATE_WORKTREE", value: "not-reevaluation"},
    {key: "IMAGE", value: "not-used-ticket-cycle"},
    {key: "IMAGE_ID", value: "not-used-ticket-cycle"},
    {key: "PLATFORM", value: platform},
    {key: "APPROVED_HANDBOOK_SHA", value: "not-used-ticket-cycle"},
    {key: "CANDIDATE_HANDBOOK_SHA", value: "not-used-ticket-cycle"},
    {key: "TICKET_SNAPSHOT_SHA", value: ticket_snapshots},
  ]
  fs.write(fp"${run_dir}/PROVENANCE.md", control.fill_template(provenance_template.read_text()?, provenance_values))?

  let director_message = fp"${run_dir}/DIRECTOR-REQUEST.md"
  let director_template = fp"${factory_dir}/templates/DIRECTOR-REQUEST.md"
  let director_values: List[control.TemplateValue] = [
    {key: "FACTORY_DIR", value: factory_dir.display()},
    {key: "RUN_DIR", value: run_dir.display()},
    {key: "RUN_AGENT", value: run_agent.display()},
    {key: "MODE", value: "ticket-implementation"},
    {key: "DISPATCH_FILE", value: "TICKET-DISPATCH.md"},
  ]
  fs.write(director_message, control.fill_template(director_template.read_text()?, director_values))?

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
    FACTORY_DIRECTOR_TOOLS: control.configured_role_setting("director", "TOOLS")?,
    FACTORY_XSH_SWE_PROVIDER: control.configured_role_setting("xsh-swe", "PROVIDER")?,
    FACTORY_XSH_SWE_MODEL: control.configured_role_setting("xsh-swe", "MODEL")?,
    FACTORY_XSH_SWE_THINKING: control.configured_role_setting("xsh-swe", "THINKING")?,
    FACTORY_XSH_SWE_BUDGET_USD: control.configured_role_setting("xsh-swe", "BUDGET_USD")?,
    FACTORY_XSH_SWE_TOOLS: control.configured_role_setting("xsh-swe", "TOOLS")?,
  }
  runtime.emit_event(event_template, run_dir, "20-director-started", "director", "started", 1, "controller", "dispatching admitted XSH SWE workers")?
  for ticket_id in tickets {
    runtime.emit_event(event_template, run_dir, f"20-ticket-${ticket_id}-started", ticket_id, "started", 1, "director", "dispatching xsh-swe worker")?
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
  runtime.emit_event(event_template, run_dir, "80-director-completed", "director", if director_status.ok { "completed" } else { "failed" }, 1, "director", "director process returned")?

  let cost_status = process.run(process.command_argv(
    xsh_path,
    [xsh_path.display(), fp"${factory_dir}/tools/session-report.xsh", "--", "run", "--run-dir", run_dir.display(),
      "--output", fp"${run_dir}/COST.md".display()],
  ))?
  var all_tickets_ok = true
  var all_patches_ok = true
  var result_rows = ""
  for ticket_id in tickets {
    let worktree = fp"${worktree_root}/${ticket_id}"
    let worker_dir = fp"${run_dir}/workers/xsh-swe/${ticket_id}"
    let swe_report = fp"${worker_dir}/SWE-REPORT.md"
    let session = fp"${worker_dir}/session.jsonl"
    let north_star_read_ok = runtime.session_read_path(session, fp"${factory_dir}/NORTH-STAR.md")?
    let handbook_read_ok = runtime.session_read_path(session, fp"${factory_dir}/runtime/handbook.md")?
    let report_ok = fs.exists(swe_report)? and ! fs.exists(fp"${worker_dir}/REPORT-MISSING")? and
      control.swe_report_contract_ok(fs.read_text(swe_report)?)
    let branch = run.text "git" "-C" $worktree.display() "branch" "--show-current" ?
    let head = run.text "git" "-C" $worktree.display() "rev-parse" "HEAD" ?
    let status = run.text "git" "-C" $worktree.display() "status" "--porcelain" ?
    let branch_ok = branch.trim() == f"factory/${ticket_id}/${stamp}"
    let commit_ok = head.trim() != xsh_commit.trim()
    let clean = status.trim() == ""
    let ticket_ok = fs.exists(session)? and report_ok and north_star_read_ok and handbook_read_ok and branch_ok and commit_ok and clean
    let patch_path = fp"${patch_root}/${ticket_id}.diff"
    let patch_stderr = fp"${patch_root}/${ticket_id}.stderr"
    let patch_ok = if ticket_ok {
      runtime.write_swe_patch(worktree, xsh_commit.trim(), head.trim(), patch_path, patch_stderr)?
    } else {
      false
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
    let final_ticket_ok = ticket_ok and patch_ok and
      (retain_worktree or worktree_action == "removed-after-patch")
    if ! final_ticket_ok { all_tickets_ok = false }
    if ! patch_ok { all_patches_ok = false }
    let state = if final_ticket_ok { "ready-for-review" } else { "failed" }
    let report_state = if fs.exists(swe_report)? { "present" } else { "missing" }
    let patch_state = if patch_ok { "present" } else { "missing" }
    let patch_sha = if patch_ok { hash.sha256(patch_path)?.hex() } else { "missing" }
    let patch_template = fp"${factory_dir}/templates/SWE-PATCH.md"
    fs.write(fp"${patch_root}/${ticket_id}.md", control.fill_template(
      patch_template.read_text()?, [
        {key: "TICKET_ID", value: ticket_id},
        {key: "BASE_COMMIT", value: xsh_commit.trim()},
        {key: "BRANCH", value: branch.trim()},
        {key: "IMPLEMENTATION_COMMIT", value: head.trim()},
        {key: "PATCH_PATH", value: patch_path.display()},
        {key: "PATCH_SHA", value: patch_sha},
        {key: "PATCH_STATE", value: patch_state},
        {key: "WORKTREE_ACTION", value: worktree_action},
      ]
    ))?
    let result_row_template = fp"${factory_dir}/templates/SWE-RESULTS-ROW.md"
    let result_row_values: List[control.TemplateValue] = [
      {key: "TICKET_ID", value: ticket_id},
      {key: "REPORT_STATE", value: report_state},
      {key: "NORTH_STAR_READ", value: if north_star_read_ok { "true" } else { "false" }},
      {key: "HANDBOOK_READ", value: if handbook_read_ok { "true" } else { "false" }},
      {key: "BRANCH", value: branch.trim()},
      {key: "COMMIT", value: head.trim()},
      {key: "PATCH", value: if patch_ok { patch_path.display() } else { "missing" }},
      {key: "WORKTREE_ACTION", value: worktree_action},
      {key: "CLEAN", value: if clean { "true" } else { "false" }},
      {key: "STATE", value: state},
    ]
    result_rows = result_rows + control.fill_template(result_row_template.read_text()?, result_row_values)
    if final_ticket_ok {
      runtime.emit_event(event_template, run_dir, f"80-ticket-${ticket_id}-completed", ticket_id, "completed", 1, "xsh-swe", f"branch ${branch.trim()} at ${head.trim()}; north star and handbook read from session log")?
      runtime.emit_event(event_template, run_dir, f"85-ticket-${ticket_id}-validated", ticket_id, "validated", 1, "controller", f"report, patch, branch, commit, and worktree checks passed; ${worktree_action}")?
      runtime.emit_event(event_template, run_dir, f"90-ticket-${ticket_id}-ready", ticket_id, "ready-for-review", 1, "controller", "branch and portable patch are pending user review")?
    } else {
      runtime.emit_event(event_template, run_dir, f"80-ticket-${ticket_id}-failed", ticket_id, "failed", 1, "controller", f"worker output, patch, or worktree validation failed for ${ticket_id}")?
    }
  }
  let results_template = fp"${factory_dir}/templates/SWE-RESULTS.md"
  fs.write(fp"${run_dir}/SWE-RESULTS.md", control.fill_template(
    results_template.read_text()?, [{key: "ROWS", value: result_rows}]
  ))?
  let director_report = fp"${run_dir}/DIRECTOR-REPORT.md"
  let director_report_ok = fs.exists(director_report)? and
    ! fs.exists(fp"${run_dir}/workers/director/director/REPORT-MISSING")? and
    control.director_report_contract_ok(fs.read_text(director_report)?)
  let audit_status = process.run(process.command_argv(
    xsh_path,
    [xsh_path.display(), fp"${factory_dir}/audit-run.xsh", "--", run_dir.display(), "ticket-implementation"],
    cwd: factory_dir,
  ))?
  let audit_file = fp"${run_dir}/AUDIT.md"
  let audit_report_ok = audit_status.ok and fs.exists(audit_file)? and
    control.audit_report_contract_ok(fs.read_text(audit_file)?)
  let audit_result = if audit_report_ok { control.audit_result(fs.read_text(audit_file)?) } else { "missing" }
  let audit_pass = audit_report_ok and audit_result == "pass"
  if audit_pass {
    runtime.mark_phase_completed(event_template, run_dir, "85-cycle-audited", "ticket-implementation",
      1, "controller", "deterministic audit artifact written")?
  } else {
    runtime.emit_event(event_template, run_dir, "85-cycle-audited", "ticket-implementation",
      "failed", 1, "controller", "deterministic audit artifact written")?
  }
  let result = if director_status.ok and cost_status.ok and all_tickets_ok and all_patches_ok and director_report_ok and audit_pass { "pass" } else { "fail" }
  let director_state = if fs.exists(fp"${run_dir}/workers/director/director/session.jsonl")? { "present" } else { "missing" }
  let cost_state = if cost_status.ok { "present" } else { "failed" }
  let swe_state = if all_tickets_ok { "ready-for-review" } else { "failed" }
  let director_report_state = if director_report_ok { "present" } else { "missing north-star section" }
  let run_template = fp"${factory_dir}/templates/RUN-TICKET.md"
  let run_values: List[control.TemplateValue] = [
    {key: "RUN_ID", value: stamp.float().format(precision: 0)},
    {key: "RESULT", value: result},
    {key: "TICKET_NAMES", value: ticket_names},
    {key: "XSH_COMMIT", value: xsh_commit.trim()},
    {key: "DIRECTOR_STATE", value: director_state},
    {key: "SWE_STATE", value: swe_state},
    {key: "PATCH_STATE", value: if all_patches_ok { "present" } else { "partial-or-missing" }},
    {key: "COST_STATE", value: cost_state},
    {key: "DIRECTOR_REPORT_STATE", value: director_report_state},
    {key: "AUDIT_STATE", value: if audit_report_ok { "present" } else { "failed" }},
    {key: "AUDIT_RESULT", value: audit_result},
  ]
  let run_report = control.fill_template(run_template.read_text()?, run_values)
  fs.write(fp"${run_dir}/RUN.md", run_report)?
  if result == "pass" {
    runtime.emit_event(event_template, run_dir, "90-cycle-completed", "ticket-implementation", "completed", 1, "controller", "run report and review branches written")?
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
