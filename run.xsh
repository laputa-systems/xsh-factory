##! Runs one complete Markdown-directed factory cycle.

use factory_control as control

error ControllerError = InvalidTransition(subject: Str, current: Str, next: Str) : InvalidData

proc cleanup_active_run() [fs, process, env, error] -> Result[Unit] {
  let configured_factory = env.get_or("FACTORY_DIR", "")?
  let factory_dir = if configured_factory == "" { fs.cwd()? } else { Path(configured_factory) }
  let active_run = fp"${factory_dir}/runs/ACTIVE"
  if fs.exists(active_run)? {
    let run_text = fs.read_text(active_run)?.trim()
    if run_text != "" {
      let xsh_path = process.which("xsh")?
      let cleanup = fp"${factory_dir}/tools/cleanup-run.xsh"
      let _ = process.run(process.command_argv(
        xsh_path,
        [xsh_path.display(), cleanup.display(), "--", run_text],
      ))?
    }
  }
  return Ok()
}

# A run owns every child process group started by its XSH process. The active
# run registry is also drained here because a Pi worker can launch a nested
# run-agent or Docker client in a new process group that the XSH runtime cannot
# discover through its direct child handle alone.
on SIGINT --pre-cancel=0ms [fs, process, env, error] {
  cleanup_active_run()?
  abort(130)
}

on SIGTERM --pre-cancel=0ms [fs, process, env, error] {
  cleanup_active_run()?
  abort(143)
}

pure supported_eval(eval_id: Str) -> Bool {
  return eval_id == "task-tags" or eval_id == "task-ecount"
}

proc emit_event(
  template: Path,
  run_dir: Path,
  name: Str,
  subject: Str,
  state: Str,
  attempt: Int,
  caused_by: Str,
  detail: Str,
) [fs, error] -> Result[Unit] {
  let events = fp"${run_dir}/events"
  let states = fp"${run_dir}/states"
  let state_file = fp"${states}/${subject}.state"
  fs.mkdir(events)?
  fs.mkdir(states)?
  let current = if fs.exists(state_file)? { fs.read_text(state_file)?.trim() } else { "created" }
  if ! control.transition_allowed(current, state) {
    return Err(ControllerError.InvalidTransition(subject: subject, current: current, next: state))
  }
  let values: List[control.TemplateValue] = [
    {key: "EVENT_ID", value: name},
    {key: "RUN_ID", value: run_dir.display()},
    {key: "KIND", value: name},
    {key: "SUBJECT", value: subject},
    {key: "STATE", value: state},
    {key: "ATTEMPT", value: attempt.float().format(precision: 0)},
    {key: "CAUSED_BY", value: caused_by},
    {key: "DETAIL", value: detail},
  ]
  fs.write_atomic(fp"${events}/${name}.md", control.fill_template(template.read_text()?, values))?
  fs.write_atomic(state_file, state + "\n")?
  return Ok()
}

proc accepted_ticket(ticket_path: Path) [fs, error] -> Result[Bool] {
  if ! fs.exists(ticket_path)? {
    return false
  }
  return control.ticket_is_accepted(fs.read_text(ticket_path)?)
}

proc session_read_path(session: Path, expected: Path) [fs, error] -> Result[Bool] {
  if ! fs.exists(session)? {
    return false
  }
  var found = false
  for line in fs.read_text(session)?.lines() {
    if line.contains("\"name\":\"read\"") and line.contains(expected.display()) {
      found = true
    }
  }
  return found
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
  let xsh_path = process.which("xsh")?
  let stamp = time.now()
  let run_dir = fp"${factory_dir}/runs/run-${stamp}"
  let active_run = fp"${factory_dir}/runs/ACTIVE"
  let worktree_root = fp"${run_dir}/worktrees"
  let event_template = fp"${factory_dir}/templates/EVENT.md"
  let provenance_template = fp"${factory_dir}/templates/PROVENANCE.md"
  let assignment_template = fp"${factory_dir}/templates/XSH-SWE-ASSIGNMENT.md"
  let assignment_template_text = assignment_template.read_text()?
  let platform = env.get_or("FACTORY_PLATFORM", "linux/arm64")?
  fs.mkdir(fp"${factory_dir}/runs")?
  fs.mkdir(run_dir)?
  fs.mkdir(worktree_root)?
  fs.mkdir(fp"${run_dir}/messages")?
  fs.mkdir(fp"${run_dir}/tickets")?
  fs.write(active_run, run_dir.display() + "\n")?
  defer fs.remove(active_run, missing_ok: true)?
  fs.copy(request, fp"${run_dir}/CYCLE-REQUEST.md", overwrite: true)?
  emit_event(event_template, run_dir, "00-cycle-started", "ticket-implementation", "started", 1, "controller", "approved ticket dispatch")?

  let xsh_commit = run.text "git" "-C" $xsh_repo.display() "rev-parse" "HEAD" ?
  let xsh_git_status = run.text "git" "-C" $xsh_repo.display() "status" "--porcelain" ?
  if xsh_git_status.trim() != "" {
    eprint "ticket-implementation requires a clean XSH worktree at admission"
    return 1
  }

  var dispatch = "# Approved ticket dispatch\n\n"
  var ticket_names = ""
  var ticket_snapshots = ""
  for ticket_id in tickets {
    if ! control.valid_ticket_id(ticket_id) {
      eprint f"unsafe ticket id: ${ticket_id}"
      return 1
    }
    let ticket_path = fp"${factory_dir}/tickets/${ticket_id}.md"
    if ! accepted_ticket(ticket_path)? {
      eprint f"ticket is missing or not accepted: ${ticket_id}"
      emit_event(event_template, run_dir, f"ticket-${ticket_id}-rejected", ticket_id, "failed", 1, "admission", "ticket is not checked-in with Accepted status")?
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
      emit_event(event_template, run_dir, f"ticket-${ticket_id}-worktree", ticket_id, "failed", 1, "admission", "git worktree add failed")?
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
    dispatch = dispatch + f"- Ticket: `${ticket_id}`\n  - Source: `tickets/${ticket_id}.md`\n  - Worktree: `${worktree.display()}`\n  - Branch: `${branch}`\n  - Base commit: `${xsh_commit.trim()}`\n  - Assignment: `messages/${ticket_id}.md`\n  - Assignment SHA-256: `${assignment_sha}`\n\n"
    ticket_names = if ticket_names == "" { ticket_id } else { ticket_names + ", " + ticket_id }
    emit_event(event_template, run_dir, f"10-ticket-${ticket_id}-admitted", ticket_id, "admitted", 1, "admission", f"worktree ${worktree.display()} on ${branch}")?
  }
  fs.write(fp"${run_dir}/TICKET-DISPATCH.md", dispatch)?
  let provenance_values: List[control.TemplateValue] = [
    {key: "RUN_ID", value: run_dir.display()},
    {key: "MODE", value: "ticket-implementation"},
    {key: "REQUEST", value: "CYCLE-REQUEST.md"},
    {key: "XSH_COMMIT", value: xsh_commit.trim()},
    {key: "IMAGE", value: "not-used-ticket-cycle"},
    {key: "IMAGE_ID", value: "not-used-ticket-cycle"},
    {key: "PLATFORM", value: platform},
    {key: "APPROVED_HANDBOOK_SHA", value: "not-used-ticket-cycle"},
    {key: "CANDIDATE_HANDBOOK_SHA", value: "not-used-ticket-cycle"},
    {key: "TICKET_SNAPSHOT_SHA", value: ticket_snapshots},
  ]
  fs.write(fp"${run_dir}/PROVENANCE.md", control.fill_template(provenance_template.read_text()?, provenance_values))?

  let director_message = f"# Director assignment\n\nRead `NORTH-STAR.md`, the cycle request at `${run_dir}/CYCLE-REQUEST.md`, `PROVENANCE.md`, `TICKET-DISPATCH.md`, and the shared Pi-session briefing. This is a `ticket-implementation` cycle; do not launch an eval-manager, eval-worker, or eval-designer.\n\nThe controller has already admitted the complete ticket set and created one immutable assignment file per ticket. The dispatch table is the only worker list. For every row, launch exactly one `xsh-swe` through the shared runner with that row's exact ticket ID, worktree, assignment file, and assignment SHA-256. Do not discover tickets, search the factory ticket directory, select a different ticket, create a second worker for a row, or launch a worker for any ticket absent from `TICKET-DISPATCH.md`:\n\n```sh\nFACTORY_PARENT_ID=director FACTORY_TICKET_ID=<exact-ticket-id> FACTORY_ASSIGNMENT_SHA=<exact-assignment-sha> FACTORY_WORKDIR=<exact-worktree> xsh `${run_agent.display()}` -- xsh-swe <exact-ticket-id> `${factory_dir}/roles/xsh-swe.md` `${run_dir}/messages/<exact-ticket-id>.md`\n```\n\nThe assignment file inlines the controller-selected ticket and is the worker's sole ticket authority. The shared runner rejects a mismatched or already-claimed assignment before starting Pi. Wait for each child process to finish, inspect its session report and `SWE-REPORT.md`, and do not merge any branch. Finish `${run_dir}/DIRECTOR-REPORT.md` with the child result table, branch and commit links, required-output status, and an exact `## North-star impact` section. A branch is pending user review; do not alter the accepted ticket's diagnosis or status.\n"
  fs.write(fp"${run_dir}/DIRECTOR-REQUEST.md", director_message)?

  let director_env = {
    PATH: env.get("PATH")?,
    HOME: env.get("HOME")?,
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
    FACTORY_DIRECTOR_PROVIDER: env.get_or("FACTORY_DIRECTOR_PROVIDER", "openrouter")?,
    FACTORY_DIRECTOR_MODEL: env.get_or("FACTORY_DIRECTOR_MODEL", "deepseek/deepseek-v4-flash-0731")?,
    FACTORY_DIRECTOR_THINKING: env.get_or("FACTORY_DIRECTOR_THINKING", "high")?,
    FACTORY_DIRECTOR_BUDGET_USD: env.get_or("FACTORY_DIRECTOR_BUDGET_USD", "2")?,
    FACTORY_DIRECTOR_TOOLS: env.get_or("FACTORY_DIRECTOR_TOOLS", "read,write,edit,bash,grep,find,ls")?,
    FACTORY_XSH_SWE_PROVIDER: env.get_or("FACTORY_XSH_SWE_PROVIDER", "openrouter")?,
    FACTORY_XSH_SWE_MODEL: env.get_or("FACTORY_XSH_SWE_MODEL", "deepseek/deepseek-v4-flash-0731")?,
    FACTORY_XSH_SWE_THINKING: env.get_or("FACTORY_XSH_SWE_THINKING", "high")?,
    FACTORY_XSH_SWE_BUDGET_USD: env.get_or("FACTORY_XSH_SWE_BUDGET_USD", "2")?,
    FACTORY_XSH_SWE_TOOLS: env.get_or("FACTORY_XSH_SWE_TOOLS", "read,write,edit,bash,grep,find,ls")?,
  }
  emit_event(event_template, run_dir, "20-director-started", "director", "started", 1, "controller", "dispatching admitted XSH SWE workers")?
  for ticket_id in tickets {
    emit_event(event_template, run_dir, f"20-ticket-${ticket_id}-started", ticket_id, "started", 1, "director", "dispatching xsh-swe worker")?
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
  emit_event(event_template, run_dir, "80-director-completed", "director", if director_status.ok { "completed" } else { "failed" }, 1, "director", "director process returned")?

  let cost_status = process.run(process.command_argv(
    xsh_path,
    [xsh_path.display(), fp"${factory_dir}/tools/session-report.xsh", "--", "run", "--run-dir", run_dir.display(),
      "--output", fp"${run_dir}/COST.md".display()],
  ))?
  var all_tickets_ok = true
  var results = "# SWE dispatch results\n\n| Ticket | Worker report | North-star read | Handbook read | Branch | Commit | Worktree clean | Result |\n| --- | --- | --- | --- | --- | --- | --- | --- |\n"
  for ticket_id in tickets {
    let worktree = fp"${worktree_root}/${ticket_id}"
    let worker_dir = fp"${run_dir}/workers/xsh-swe/${ticket_id}"
    let swe_report = fp"${worker_dir}/SWE-REPORT.md"
    let session = fp"${worker_dir}/session.jsonl"
    let north_star_read_ok = session_read_path(session, fp"${factory_dir}/NORTH-STAR.md")?
    let handbook_read_ok = session_read_path(session, fp"${factory_dir}/runtime/handbook.md")?
    let report_ok = fs.exists(swe_report)? and fs.read_text(swe_report)?.contains("## Result\n\nready-for-review") and
      fs.read_text(swe_report)?.contains("## North-star impact")
    let branch = run.text "git" "-C" $worktree.display() "branch" "--show-current" ?
    let head = run.text "git" "-C" $worktree.display() "rev-parse" "HEAD" ?
    let status = run.text "git" "-C" $worktree.display() "status" "--porcelain" ?
    let branch_ok = branch.trim() == f"factory/${ticket_id}/${stamp}"
    let commit_ok = head.trim() != xsh_commit.trim()
    let clean = status.trim() == ""
    let ticket_ok = fs.exists(session)? and report_ok and north_star_read_ok and handbook_read_ok and branch_ok and commit_ok and clean
    if ! ticket_ok { all_tickets_ok = false }
    let state = if ticket_ok { "ready-for-review" } else { "failed" }
    let report_state = if fs.exists(swe_report)? { "present" } else { "missing" }
    results = results + f"| `${ticket_id}` | `${report_state}` | `${north_star_read_ok}` | `${handbook_read_ok}` | `${branch.trim()}` | `${head.trim()}` | `${clean}` | `${state}` |\n"
    if ticket_ok {
      emit_event(event_template, run_dir, f"80-ticket-${ticket_id}-completed", ticket_id, "completed", 1, "xsh-swe", f"branch ${branch.trim()} at ${head.trim()}; north star and handbook read from session log")?
      emit_event(event_template, run_dir, f"85-ticket-${ticket_id}-validated", ticket_id, "validated", 1, "controller", "report, branch, commit, and clean-worktree checks passed")?
      emit_event(event_template, run_dir, f"90-ticket-${ticket_id}-ready", ticket_id, "ready-for-review", 1, "controller", "branch is pending user review")?
    } else {
      emit_event(event_template, run_dir, f"80-ticket-${ticket_id}-failed", ticket_id, "failed", 1, "controller", f"worker output validation failed for ${ticket_id}")?
    }
  }
  fs.write(fp"${run_dir}/SWE-RESULTS.md", results)?
  let director_report = fp"${run_dir}/DIRECTOR-REPORT.md"
  let director_report_ok = fs.exists(director_report)? and fs.read_text(director_report)?.contains("## North-star impact")
  let result = if director_status.ok and cost_status.ok and all_tickets_ok and director_report_ok { "pass" } else { "fail" }
  let director_state = if fs.exists(fp"${run_dir}/workers/director/director/session.jsonl")? { "present" } else { "missing" }
  let cost_state = if cost_status.ok { "present" } else { "failed" }
  let swe_state = if all_tickets_ok { "ready-for-review" } else { "failed" }
  let director_report_state = if director_report_ok { "present" } else { "missing north-star section" }
  let run_report = f"# Factory run ${stamp}\n\n## Result\n\n${result}\n\n## Mode\n\n`ticket-implementation`\n\n## North-star status\n\nThis cycle implements user-approved XSH tickets in isolated worktrees. It does not merge product changes or claim that an implementation is accepted; the branch remains pending user review.\n\n## Cycle\n\n- Request: `CYCLE-REQUEST.md`\n- Approved tickets: `${ticket_names}`\n- XSH base commit: `${xsh_commit.trim()}`\n\n## Required outputs\n\n- Director session: `${director_state}`\n- SWE dispatch: `${swe_state}`\n- Cost report: `${cost_state}`\n- Director report: `${director_report_state}`\n\nAll product worktrees remain under `worktrees/` for user review. See `TICKET-DISPATCH.md`, `SWE-RESULTS.md`, `DIRECTOR-REPORT.md`, `PROVENANCE.md`, and `COST.md`.\n"
  fs.write(fp"${run_dir}/RUN.md", run_report)?
  if result == "pass" {
    emit_event(event_template, run_dir, "90-cycle-completed", "ticket-implementation", "completed", 1, "controller", "run report and review branches written")?
    emit_event(event_template, run_dir, "95-cycle-validated", "ticket-implementation", "validated", 1, "controller", "all required review outputs passed")?
  } else {
    emit_event(event_template, run_dir, "90-cycle-failed", "ticket-implementation", "failed", 1, "controller", "one or more required outputs failed")?
  }
  print f"factory run: ${run_dir} (${result})"
  return if result == "pass" { 0 } else { 1 }
}

proc main(...argv: List[Str]) [fs, process, env, time, error, io] {
  if argv.len() < 1 {
    eprint "usage: xsh run.xsh CYCLE_REQUEST.md [EVAL_ID]"
    abort(2)
  }
  let factory_dir = env.path("FACTORY_DIR", fs.cwd()?)?
  let request = Path(argv[0])
  let mode = control.request_mode(request.read_text()?)
  if mode == "ticket-implementation" {
    let xsh_repo = env.path("FACTORY_XSH_REPO", fp"${factory_dir}/../xsh")?
    let home = env.get("HOME")?
    let auth_file = env.path("PI_AUTH_FILE", fp"${home}/.pi/agent/auth.json")?
    let run_agent = fp"${factory_dir}/run-agent.xsh"
    let pi_command = env.get_or("PI_COMMAND", "pi")?
    abort(run_ticket_cycle(request, factory_dir, xsh_repo, auth_file, run_agent, pi_command)?)
  }
  if mode != "eval" {
    eprint f"unsupported cycle mode: `${mode}`"
    abort(2)
  }
  let requested_eval = if argv.len() >= 2 { argv[1] } else { control.request_eval(request.read_text()?) }
  if ! supported_eval(requested_eval) {
    eprint f"cycle request selected unsupported or missing eval: `${requested_eval}`"
    abort(2)
  }
  let eval_id = requested_eval
  let eval_dir = fp"${factory_dir}/evals/${eval_id}"
  let task_file = if eval_id == "task-tags" { "task-tags.md" } else { "task-ecount.md" }
  let artifact_file = if eval_id == "task-tags" { "tag.xsh" } else { "ecount.xsh" }
  let default_image = if eval_id == "task-tags" {
    "xsh-factory-task-tags:latest"
  } else {
    "xsh-factory-task-ecount:latest"
  }
  let image = if eval_id == "task-tags" {
    env.get_or("FACTORY_TASK_TAGS_IMAGE", default_image)?
  } else {
    env.get_or("FACTORY_TASK_ECOUNT_IMAGE", default_image)?
  }
  let home = env.get("HOME")?
  let auth_file = env.path("PI_AUTH_FILE", fp"${home}/.pi/agent/auth.json")?
  let docker = env.get_or("DOCKER", "docker")?
  let platform = env.get_or("FACTORY_PLATFORM", "linux/arm64")?
  let target = env.get_or("XSH_TARGET", "aarch64-unknown-linux-musl")?
  let xsh_repo = env.path("FACTORY_XSH_REPO", fp"${factory_dir}/../xsh")?
  let stamp = time.now()
  let run_dir = fp"${factory_dir}/runs/run-${stamp}"
  let worker_root = fp"${run_dir}/workers"
  let active_run = fp"${factory_dir}/runs/ACTIVE"
  let event_template = fp"${factory_dir}/templates/EVENT.md"
  let provenance_template = fp"${factory_dir}/templates/PROVENANCE.md"
  let lineage_dir = fp"${run_dir}/lineage"
  let baseline_handbook = fp"${lineage_dir}/handbook-approved.md"
  let candidate_handbook = fp"${lineage_dir}/handbook-candidate.md"
  fs.mkdir(fp"${factory_dir}/runs")?
  fs.mkdir(worker_root)?
  fs.mkdir(lineage_dir)?
  fs.write(active_run, run_dir.display() + "\n")?
  defer fs.remove(active_run, missing_ok: true)?
  emit_event(event_template, run_dir, "00-cycle-started", eval_id, "started", 1, "controller", "eval-manager cycle")?
  fs.copy(request, fp"${run_dir}/CYCLE-REQUEST.md", overwrite: true)?
  fs.copy(fp"${factory_dir}/runtime/handbook.md", baseline_handbook, overwrite: true)?

  let xsh_commit = run.text "git" "-C" $xsh_repo.display() "rev-parse" "HEAD" ?
  let xsh_git_status = run.text "git" "-C" $xsh_repo.display() "status" "--porcelain" ?
  if xsh_git_status.trim() != "" {
    eprint "eval cycle requires a clean XSH worktree at admission"
    abort(2)
  }
  let dist_dir = fp"${xsh_repo}/target/docker-${target}-release/${target}/dist"
  let dist_xsh = fp"${dist_dir}/xsh"
  let dist_xsht = fp"${dist_dir}/xsht"
  if ! fs.exists(dist_xsh)? or ! fs.exists(dist_xsht)? {
    let build = process.run(
      process.command_argv(
        "make",
        ["make", "-C", xsh_repo.display(), "dist-Linux-docker", f"TARGET=${target}"],
        stdout: fp"${run_dir}/xsh-build.stdout",
        stderr: fp"${run_dir}/xsh-build.stderr",
      ),
    )?
    if ! build.ok {
      eprint "unable to build the local XSH distribution"
      abort(build.exit_code() ?? 1)
    }
  }
  let staged_dir = fp"${factory_dir}/evals/.dist"
  fs.mkdir(staged_dir)?
  let stage_xsh = process.run(process.command_argv(
    "cp", ["cp", "-fL", dist_xsh.display(), fp"${staged_dir}/xsh".display()],
  ))?
  let stage_xsht = process.run(process.command_argv(
    "cp", ["cp", "-fL", dist_xsht.display(), fp"${staged_dir}/xsht".display()],
  ))?
  if ! stage_xsh.ok or ! stage_xsht.ok {
    eprint f"unable to stage local XSH binaries for the ${eval_id} image"
    abort(1)
  }
  let base_image = env.get_or("FACTORY_BASE_IMAGE", "xsh-factory-base:latest")?
  let base_status = process.run(process.command_argv(
    docker,
    [docker, "build", "--platform", platform, "-t", base_image,
      "-f", fp"${factory_dir}/evals/Dockerfile.base".display(), fp"${factory_dir}/evals".display()],
    stdout: fp"${run_dir}/base-image-build.stdout",
    stderr: fp"${run_dir}/base-image-build.stderr",
  ))?
  if ! base_status.ok {
    eprint "unable to build the shared factory eval base image"
    abort(base_status.exit_code() ?? 1)
  }
  let image_status = process.run(process.command_argv(
    docker,
    [docker, "build", "--platform", platform, "--build-arg", f"BASE_IMAGE=${base_image}", "-t", image,
      "-f", fp"${eval_dir}/Dockerfile".display(), eval_dir.display()],
    stdout: fp"${run_dir}/image-build.stdout",
    stderr: fp"${run_dir}/image-build.stderr",
  ))?
  if ! image_status.ok {
    eprint f"unable to build the ${eval_id} eval image"
    abort(image_status.exit_code() ?? 1)
  }
  let image_id = run.text docker image inspect "--format" "{{.Id}}" $image ?
  let approved_handbook_sha = hash.sha256(baseline_handbook)?.hex()
  let provenance_values: List[control.TemplateValue] = [
    {key: "RUN_ID", value: run_dir.display()},
    {key: "MODE", value: "eval"},
    {key: "REQUEST", value: "CYCLE-REQUEST.md"},
    {key: "XSH_COMMIT", value: xsh_commit.trim()},
    {key: "IMAGE", value: image},
    {key: "IMAGE_ID", value: image_id.trim()},
    {key: "PLATFORM", value: platform},
    {key: "APPROVED_HANDBOOK_SHA", value: approved_handbook_sha},
    {key: "CANDIDATE_HANDBOOK_SHA", value: "pending-manager"},
    {key: "TICKET_SNAPSHOT_SHA", value: "not-ticket-cycle"},
  ]
  fs.write(fp"${run_dir}/PROVENANCE.md", control.fill_template(provenance_template.read_text()?, provenance_values))?

  let xsh_path = process.which("xsh")?
  let run_agent = fp"${factory_dir}/run-agent.xsh"
  let director_message = fp"${run_dir}/DIRECTOR-REQUEST.md"
  fs.write(director_message, f"# Director assignment\n\nRead `NORTH-STAR.md`, the cycle request at `${run_dir}/CYCLE-REQUEST.md`, `PROVENANCE.md`, and the shared Pi-session briefing before running the bounded cycle. The selected eval is `${eval_id}`. The durable objective is to improve XSH and agents' ability to use it.\n\nLaunch its eval-manager with:\n\n```sh\nFACTORY_ROLE=eval-manager FACTORY_WORKER_ID=${eval_id} FACTORY_PARENT_ID=director FACTORY_EVAL_ID=${eval_id} xsh \"${run_agent}\" -- eval-manager ${eval_id} \"${factory_dir}/roles/eval-manager.md\" \"${run_dir}/messages/${eval_id}-manager.md\"\n```\n\nThe manager must run two fresh trials through `${eval_dir}/executor.xsh`: trial 1 with the approved handbook and trial 2 with a provisional handbook candidate, even when the candidate is an unchanged copy. It must write its manager report in `$FACTORY_WORKER_DIR`. If the request asks for a designer, launch it through the same runner after the manager. Do not launch xsh-swe unless an open ticket existed at cycle start. Finish by writing `$FACTORY_RUN_DIR/DIRECTOR-REPORT.md` with the child results, `## North-star impact`, and required-output status.\n")?
  fs.mkdir(fp"${run_dir}/messages")?
  fs.write(fp"${run_dir}/messages/${eval_id}-manager.md", f"# ${eval_id} manager assignment\n\nRead `NORTH-STAR.md`, `roles/pi-session-briefing.md`, `${eval_dir}/EVAL.md`, and `PROVENANCE.md`. The executor is a black box. All evals consume the one factory-wide handbook; do not look for or create an eval-local handbook. Run exactly two fresh trials and preserve separate evidence:\n\n## Trial 1\n\nUse the approved shared-handbook snapshot:\n\n```sh\nFACTORY_EVAL_ID=${eval_id} FACTORY_TRIAL_ID=1 FACTORY_EVAL_WORKER_DIR=\"$FACTORY_RUN_DIR/workers/eval-worker/${eval_id}-1\" FACTORY_HANDBOOK_FILE=\"$FACTORY_RUN_DIR/lineage/handbook-approved.md\" xsh \"${eval_dir}/executor.xsh\"\n```\n\nInspect the executor report, worker report, thinking transcript, evaluator manifest, artifact, and quantitative session results. If a handbook change is justified, write it to `$FACTORY_RUN_DIR/lineage/handbook-candidate.md`; otherwise copy the approved snapshot there unchanged. Do not edit the approved snapshot or the checked-in `runtime/handbook.md`.\n\n## Trial 2\n\nRun a fresh worker with the shared-handbook candidate:\n\n```sh\nFACTORY_EVAL_ID=${eval_id} FACTORY_TRIAL_ID=2 FACTORY_EVAL_WORKER_DIR=\"$FACTORY_RUN_DIR/workers/eval-worker/${eval_id}-2\" FACTORY_HANDBOOK_FILE=\"$FACTORY_RUN_DIR/lineage/handbook-candidate.md\" xsh \"${eval_dir}/executor.xsh\"\n```\n\nCompare the two trials. Classify correctness, restriction, timing, worker friction, handbook guidance, product/tooling defect, harness mismatch, evaluator failure, or noise. Write `$FACTORY_WORKER_DIR/MANAGER-REPORT.md` with both trial results, handbook hashes, effort and thinking metrics, candidate/oracle timing, a `## North-star impact` section, the shared-handbook decision, tickets, and the next replay. A promoted candidate becomes `runtime/handbook.md` for every eval only after review.\n")?

  let director_env = {
    PATH: env.get("PATH")?,
    HOME: env.get("HOME")?,
    FACTORY_DIR: factory_dir.display(),
    FACTORY_RUN_DIR: run_dir.display(),
    FACTORY_RUN_AGENT: run_agent.display(),
    FACTORY_XSH_REPO: xsh_repo.display(),
    FACTORY_XSH_COMMIT: xsh_commit.trim(),
    FACTORY_IMAGE_ID: image_id.trim(),
    FACTORY_EVAL_ID: eval_id,
    FACTORY_EVAL_DIR: eval_dir.display(),
    FACTORY_EVAL_IMAGE: image,
    FACTORY_EVAL_TASK_FILE: task_file,
    FACTORY_EVAL_ARTIFACT: artifact_file,
    FACTORY_LINEAGE_DIR: lineage_dir.display(),
    FACTORY_TASK_TAGS_IMAGE: env.get_or("FACTORY_TASK_TAGS_IMAGE", "xsh-factory-task-tags:latest")?,
    FACTORY_TASK_ECOUNT_IMAGE: env.get_or("FACTORY_TASK_ECOUNT_IMAGE", "xsh-factory-task-ecount:latest")?,
    FACTORY_PLATFORM: platform,
    PI_AUTH_FILE: auth_file.display(),
    PI_COMMAND: env.get_or("PI_COMMAND", "pi")?,
    FACTORY_DIRECTOR_PROVIDER: env.get_or("FACTORY_DIRECTOR_PROVIDER", "openrouter")?,
    FACTORY_DIRECTOR_MODEL: env.get_or("FACTORY_DIRECTOR_MODEL", "deepseek/deepseek-v4-flash-0731")?,
    FACTORY_DIRECTOR_THINKING: env.get_or("FACTORY_DIRECTOR_THINKING", "high")?,
    FACTORY_DIRECTOR_BUDGET_USD: env.get_or("FACTORY_DIRECTOR_BUDGET_USD", "2")?,
    FACTORY_DIRECTOR_TOOLS: env.get_or("FACTORY_DIRECTOR_TOOLS", "read,write,edit,bash,grep,find,ls")?,
    FACTORY_EVAL_DESIGNER_PROVIDER: env.get_or("FACTORY_EVAL_DESIGNER_PROVIDER", "openrouter")?,
    FACTORY_EVAL_DESIGNER_MODEL: env.get_or("FACTORY_EVAL_DESIGNER_MODEL", "deepseek/deepseek-v4-flash-0731")?,
    FACTORY_EVAL_DESIGNER_THINKING: env.get_or("FACTORY_EVAL_DESIGNER_THINKING", "high")?,
    FACTORY_EVAL_DESIGNER_BUDGET_USD: env.get_or("FACTORY_EVAL_DESIGNER_BUDGET_USD", "2")?,
    FACTORY_EVAL_DESIGNER_TOOLS: env.get_or("FACTORY_EVAL_DESIGNER_TOOLS", "read,write,edit,bash,grep,find,ls")?,
    FACTORY_EVAL_MANAGER_PROVIDER: env.get_or("FACTORY_EVAL_MANAGER_PROVIDER", "openrouter")?,
    FACTORY_EVAL_MANAGER_MODEL: env.get_or("FACTORY_EVAL_MANAGER_MODEL", "deepseek/deepseek-v4-flash-0731")?,
    FACTORY_EVAL_MANAGER_THINKING: env.get_or("FACTORY_EVAL_MANAGER_THINKING", "high")?,
    FACTORY_EVAL_MANAGER_BUDGET_USD: env.get_or("FACTORY_EVAL_MANAGER_BUDGET_USD", "2")?,
    FACTORY_EVAL_MANAGER_TOOLS: env.get_or("FACTORY_EVAL_MANAGER_TOOLS", "read,write,edit,bash,grep,find,ls")?,
    FACTORY_EVAL_WORKER_PROVIDER: env.get_or("FACTORY_EVAL_WORKER_PROVIDER", "openrouter")?,
    FACTORY_EVAL_WORKER_MODEL: env.get_or("FACTORY_EVAL_WORKER_MODEL", "deepseek/deepseek-v4-flash-0731")?,
    FACTORY_EVAL_WORKER_THINKING: env.get_or("FACTORY_EVAL_WORKER_THINKING", "high")?,
    FACTORY_EVAL_WORKER_BUDGET_USD: env.get_or("FACTORY_EVAL_WORKER_BUDGET_USD", "2")?,
    FACTORY_EVAL_WORKER_TOOLS: env.get_or("FACTORY_EVAL_WORKER_TOOLS", "read,write,edit,bash")?,
    FACTORY_XSH_SWE_PROVIDER: env.get_or("FACTORY_XSH_SWE_PROVIDER", "openrouter")?,
    FACTORY_XSH_SWE_MODEL: env.get_or("FACTORY_XSH_SWE_MODEL", "deepseek/deepseek-v4-flash-0731")?,
    FACTORY_XSH_SWE_THINKING: env.get_or("FACTORY_XSH_SWE_THINKING", "high")?,
    FACTORY_XSH_SWE_BUDGET_USD: env.get_or("FACTORY_XSH_SWE_BUDGET_USD", "2")?,
    FACTORY_XSH_SWE_TOOLS: env.get_or("FACTORY_XSH_SWE_TOOLS", "read,write,edit,bash,grep,find,ls")?,
  }
  emit_event(event_template, run_dir, "20-director-started", "director", "started", 1, "controller", "dispatching eval-manager")?
  let director_status = process.run(process.command_argv(
    xsh_path,
    [xsh_path.display(), run_agent, "--", "director", "director",
      fp"${factory_dir}/roles/director.md".display(), director_message.display()],
    env: director_env,
  ))?
  emit_event(event_template, run_dir, "80-director-completed", "director", if director_status.ok { "completed" } else { "failed" }, 1, "director", "director process returned")?

  let cost_status = process.run(process.command_argv(
    xsh_path,
    [xsh_path.display(), fp"${factory_dir}/tools/session-report.xsh", "--", "run", "--run-dir", run_dir.display(),
      "--output", fp"${run_dir}/COST.md".display()],
  ))?
  let manager_session = fp"${run_dir}/workers/eval-manager/${eval_id}/session.jsonl"
  let trial1_report = fp"${run_dir}/workers/eval-worker/${eval_id}-1/EXECUTOR-REPORT.md"
  let trial2_report = fp"${run_dir}/workers/eval-worker/${eval_id}-2/EXECUTOR-REPORT.md"
  let trial1_handbook = fp"${run_dir}/workers/eval-worker/${eval_id}-1/work/handbook.md"
  let trial2_handbook = fp"${run_dir}/workers/eval-worker/${eval_id}-2/work/handbook.md"
  let candidate_exists = fs.exists(candidate_handbook)?
  let trial1_report_ok = fs.exists(trial1_report)? and fs.read_text(trial1_report)?.contains("## Result\n\npass")
  let trial2_report_ok = fs.exists(trial2_report)? and fs.read_text(trial2_report)?.contains("## Result\n\npass")
  let baseline_sha = approved_handbook_sha
  let candidate_sha = if candidate_exists { hash.sha256(candidate_handbook)?.hex() } else { "" }
  let trial1_sha = if fs.exists(trial1_handbook)? { hash.sha256(trial1_handbook)?.hex() } else { "" }
  let trial2_sha = if fs.exists(trial2_handbook)? { hash.sha256(trial2_handbook)?.hex() } else { "" }
  let lineage_ok = candidate_exists and trial1_sha == baseline_sha and trial2_sha == candidate_sha
  let director_report = fp"${run_dir}/DIRECTOR-REPORT.md"
  let director_report_ok = fs.exists(director_report)? and fs.read_text(director_report)?.contains("## North-star impact")
  let manager_report = fp"${run_dir}/workers/eval-manager/${eval_id}/MANAGER-REPORT.md"
  let manager_report_ok = fs.exists(manager_report)? and fs.read_text(manager_report)?.contains("## North-star impact")
  let required = fs.exists(manager_session)? and fs.exists(trial1_report)? and fs.exists(trial2_report)? and
    cost_status.ok and candidate_exists and lineage_ok and trial1_report_ok and trial2_report_ok and
    director_report_ok and manager_report_ok
  let result = if director_status.ok and required { "pass" } else { "fail" }
  let director_state = if fs.exists(fp"${run_dir}/workers/director/director/session.jsonl")? { "present" } else { "missing" }
  let manager_state = if fs.exists(manager_session)? { "present" } else { "missing" }
  let trial1_state = if trial1_report_ok { "pass" } else { "fail" }
  let trial2_state = if trial2_report_ok { "pass" } else { "fail" }
  let lineage_state = if lineage_ok { "pass" } else { "fail" }
  let cost_state = if cost_status.ok { "present" } else { "failed" }
  let run_report = f"# Factory run ${stamp}\n\n## Result\n\n${result}\n\n## North-star status\n\nThis `${eval_id}` cycle measures a practical XSH capability and preserves the evidence needed for durable handbook or product decisions. See `DIRECTOR-REPORT.md` and the manager report for the explicit mission impact.\n\n## Cycle\n\n- Request: `CYCLE-REQUEST.md`\n- Eval: `${eval_id}`\n- XSH commit: `${xsh_commit.trim()}`\n- Image: `${image}`\n- Image ID: `${image_id.trim()}`\n\n## Required outputs\n\n- Director session: `${director_state}`\n- Eval-manager session: `${manager_state}`\n- Trial 1 executor: `${trial1_state}`\n- Trial 2 executor: `${trial2_state}`\n- Handbook lineage: `${lineage_state}`\n- Cost report: `${cost_state}`\n\n## Handbook hashes\n\n- Approved snapshot: `${baseline_sha}`\n- Provisional snapshot: `${candidate_sha}`\n- Trial 1 staged handbook: `${trial1_sha}`\n- Trial 2 staged handbook: `${trial2_sha}`\n\n## Evidence\n\nAll Pi sessions, extracted thinking transcripts, worker reports, evaluator\nmanifests, container logs, and artifacts are under `workers/`. See\n`PROVENANCE.md`, `LINEAGE.md`, and `COST.md` for the run inputs and accounting.\n"
  fs.write(fp"${run_dir}/LINEAGE.md", f"# Shared handbook lineage\n\n## Factory handbook\n\nAll evals in this factory consume `runtime/handbook.md`. This run snapshots that one approved document and tests one candidate against it.\n\n## Snapshots\n\n- Approved: `lineage/handbook-approved.md` (`${baseline_sha}`)\n- Candidate: `lineage/handbook-candidate.md` (`${candidate_sha}`)\n- Trial 1 used: `${trial1_sha}`\n- Trial 2 used: `${trial2_sha}`\n\n## Result\n\n`${lineage_state}`\n\nTrial 1 must use the approved shared snapshot and trial 2 must use the candidate shared snapshot. Promotion, if approved, updates the single checked-in `runtime/handbook.md`; it is never eval-local.\n")?
  fs.write(fp"${run_dir}/RUN.md", run_report)?
  if result == "pass" {
    emit_event(event_template, run_dir, "90-cycle-completed", eval_id, "completed", 1, "controller", "run report and cost report written")?
    emit_event(event_template, run_dir, "95-cycle-validated", eval_id, "validated", 1, "controller", "all required outputs passed")?
  } else {
    emit_event(event_template, run_dir, "90-cycle-failed", eval_id, "failed", 1, "controller", "one or more required outputs failed")?
  }
  print f"factory run: ${run_dir} (${result})"
  abort(if result == "pass" { 0 } else { 1 })
}
