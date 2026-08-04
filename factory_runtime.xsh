##! Shared process-boundary helpers for every factory cycle mode.

use factory_control as control

error RuntimeError = InvalidTransition(subject: Str, current: Str, next: Str) : InvalidData

type MergeEvidence = {
  merged: Bool,
  ticket_id: Str,
  branch: Str,
  implementation_commit: Str,
  source_run: Str,
  detected_xsh_commit: Str,
}

## One ticket whose implementation commit is already in XSH HEAD.
export type MergedTicket = {
  ticket_id: Str,
  eval_id: Str,
  branch: Str,
  implementation_commit: Str,
  source_run: Str,
  detected_xsh_commit: Str,
}

## Terminates all registered children of the active run.
export proc cleanup_active_run() [fs, process, env, error] -> Result[Unit] {
  let configured_factory = env.get_or("FACTORY_DIR", "")?
  let factory_dir = if configured_factory == "" { fs.cwd()? } else { Path(configured_factory) }
  let default_active_run = fp"${factory_dir}/runs/ACTIVE"
  let configured_active_run = env.path("FACTORY_ACTIVE_RUN", default_active_run)?
  let organization_run = fp"${factory_dir}/runs/ORGANIZATION-ACTIVE"
  let active_marker = if fs.exists(configured_active_run)? {
    configured_active_run
  } else if fs.exists(organization_run)? {
    organization_run
  } else {
    default_active_run
  }
  if ! fs.exists(active_marker)? {
    return Ok()
  }
  let run_text = fs.read_text(active_marker)?.trim()
  if run_text != "" {
    let xsh_path = process.which("xsh")?
    let self_pid = process.current_pid()?
    let cleanup = fp"${factory_dir}/tools/cleanup-run.xsh"
    let _ = process.run(process.command_argv(
      xsh_path,
      [xsh_path.display(), cleanup.display(), "--", run_text, "--exclude-pid", f"${self_pid}"],
    ))?
  }
  return Ok()
}

## Registers a controller so cleanup covers phase and top-level processes alike.
export proc register_cycle_controller(run_dir: Path) [fs, process, error] -> Result[Unit] {
  let processes = fp"${run_dir}/processes"
  fs.mkdir(processes)?
  let pid = process.current_pid()?
  fs.write_atomic(fp"${processes}/controller.pids", f"${pid}\n")?
  return Ok()
}

## Registers a controller-owned child before waiting on it.
export proc register_process(run_dir: Path, name: Str, pid: Int) [fs, error] -> Result[Unit] {
  let processes = fp"${run_dir}/processes"
  fs.mkdir(processes)?
  fs.write_atomic(fp"${processes}/${name}.pids", f"${pid}\n")?
  return Ok()
}

## Starts the one aggregate watcher owned by a top-level cycle controller.
export proc start_cycle_budget_watch(
  factory_dir: Path,
  run_dir: Path,
) [fs, process, env, error] -> Result[ProcessHandle] {
  let requested = env.get_or("FACTORY_CYCLE_BUDGET_USD", control.default_cycle_budget())?
  let budget = control.clamp_cycle_budget(requested)?
  let xsh = process.which("xsh")?
  let env_path = process.which("env")?
  let watcher = fp"${factory_dir}/tools/cycle-budget-watch.xsh"
  let marker = fp"${run_dir}/AGGREGATE-BUDGET-BREACH"
  let stop = fp"${run_dir}/AGGREGATE-BUDGET-STOP"
  let postmortem = fp"${run_dir}/POSTMORTEM.md"
  let controller_pid = process.current_pid()?
  let module_path = env.get_or("XSH_MODULE_PATH", factory_dir.display())?
  let assignments = [
    "FACTORY_DIR=" + factory_dir.display(),
    "XSH_MODULE_PATH=" + module_path,
  ]
  let command = assignments.extend([
    xsh.display(), watcher.display(), "--",
    "--run-dir", run_dir.display(),
    "--pid", f"${controller_pid}",
    "--budget-usd", budget,
    "--marker", marker.display(),
    "--stop", stop.display(),
    "--postmortem", postmortem.display(),
  ])
  return spawn process.command_argv(
    env_path,
    [env_path.display()].extend(command),
    cwd: factory_dir,
    stdout: fp"${run_dir}/cycle-budget-watch.stdout",
    stderr: fp"${run_dir}/cycle-budget-watch.stderr",
  )
}

## Requests a clean watcher exit after a controller completes normally.
export proc stop_cycle_budget_watch(run_dir: Path) [fs, error] -> Result[Unit] {
  fs.write_atomic(fp"${run_dir}/AGGREGATE-BUDGET-STOP", "normal controller shutdown\n")?
  return Ok()
}

## Stages the CTO handoff in every controller-owned run directory.
## The CTO fills this checked-in template after reviewing the evidence; the
## controller must never leave a completed run without the handoff artifact.
export proc stage_cto_improvement(factory_dir: Path, run_dir: Path) [fs, error] -> Result[Unit] {
  let target = fp"${run_dir}/CTO-IMPROVEMENT.md"
  if ! fs.exists(target)? {
    fs.copy(fp"${factory_dir}/templates/CTO-IMPROVEMENT.md", target, overwrite: true)?
  }
  return Ok()
}

## Writes the deterministic first-pass briefing used by the CTO.
export proc write_cto_report(
  factory_dir: Path,
  run_dir: Path,
  result: Str,
) [fs, process, error] -> Result[Bool] {
  let xsh = process.which("xsh")?
  let tool = fp"${factory_dir}/tools/cto-report.xsh"
  let output = fp"${run_dir}/CTO-REPORT.md"
  let status = process.run(process.command_argv(
    xsh,
    [xsh.display(), tool.display(), "--",
      "--run-dir", run_dir.display(),
      "--output", output.display(),
      "--result", result],
    cwd: factory_dir,
  ))?
  return status.ok and fs.exists(output)?
}

## Promotes one materialized eval proposal after the CTO review, setting
## Approved. only for an accepted package and never overwriting an existing
## checked-in eval. Older proposals may be incomplete; their missing package
## files are recorded in
## the checked-in contract and keep them out of paid admission.
export proc promote_eval_proposal(
  factory_dir: Path,
  proposal_dir: Path,
  run_dir: Path,
  review_result: Str,
) [fs, error] -> Result[Bool] {
  let contract = fp"${proposal_dir}/EVAL.md"
  if ! fs.exists(contract)? {
    return false
  }
  let eval_text = contract.read_text()?
  if control.ticket_status(eval_text) != "Draft." {
    return false
  }
  let eval_id = control.eval_id_from_contract(eval_text)
  if ! control.valid_eval_id(eval_id) {
    return false
  }
  let target = fp"${factory_dir}/evals/${eval_id}"
  if fs.exists(target)? {
    return false
  }
  let package_files = [
    "EVAL.md",
    "executor.xsh",
    "evaluate.xsh",
    "runtime/task.md",
    "runtime/artifact.md",
  ]
  for relative in package_files {
    if ! fs.exists(fp"${proposal_dir}/${relative}")? {
      return false
    }
  }
  let optional_files = ["evaluator.xsh", "Dockerfile"]
  fs.mkdir(target)?
  fs.mkdir(fp"${target}/runtime")?
  for relative in package_files {
    let source = fp"${proposal_dir}/${relative}"
    let destination = fp"${target}/${relative}"
    fs.copy(source, destination, overwrite: false)?
  }
  for relative in optional_files {
    let source = fp"${proposal_dir}/${relative}"
    if fs.exists(source)? {
      fs.copy(source, fp"${target}/${relative}", overwrite: false)?
    }
  }
  let source_run = control.factory_relative_path(factory_dir.display(), run_dir)
  let package_state = if fs.exists(fp"${proposal_dir}/evaluator.xsh")? { "complete" } else { "incomplete" }
  let missing = if package_state == "complete" { "None." } else { "evaluator.xsh (package-owned evaluator)" }
  let status = if review_result == "accepted" { "Approved." } else { "Draft." }
  let updated_contract = control.replace_eval_status(fs.read_text(fp"${target}/EVAL.md")?, status)
  let review = "\n## CTO review\n\n- Result: `" + review_result + "`\n- Promotion: `promoted`\n- Package: `" + package_state + "`\n- Missing package files: `" + missing + "`\n- Status: `" + status + "`\n- Source run: `" + source_run + "`\n"
  fs.write_atomic(fp"${target}/EVAL.md", updated_contract + review)?
  return true
}

## Captures the committed engineer change as a portable patch before any worktree cleanup.
export proc write_engineer_patch(
  worktree: Path,
  base_commit: Str,
  head_commit: Str,
  patch_path: Path,
  stderr_path: Path,
) [fs, process, error] -> Result[Bool] {
  let status = process.run(process.command_argv(
    "git",
    ["git", "-C", worktree.display(), "diff", "--binary", "--no-ext-diff",
      f"${base_commit}..${head_commit}"],
    stdout: patch_path,
    stderr: stderr_path,
  ))?
  if ! status.ok or ! fs.exists(patch_path)? {
    return false
  }
  return fs.metadata(patch_path)?.size > 0
}

## Removes a clean temporary worktree while leaving its review branch intact.
export proc remove_clean_worktree(xsh_repo: Path, worktree: Path) [fs, process, error] -> Result[Bool] {
  if ! fs.exists(worktree)? {
    return true
  }
  let status = process.run(process.command_argv(
    "git",
    ["git", "-C", xsh_repo.display(), "worktree", "remove", worktree.display()],
  ))?
  return status.ok and ! fs.exists(worktree)?
}

## Force-removes only worktrees owned by one completed or interrupted run.
## Branches, patches, reports, and other run evidence remain intact.
export proc remove_run_worktrees(xsh_repo: Path, run_dir: Path) [fs, process, error] -> Result[Bool] {
  if ! fs.exists(run_dir)? {
    return true
  }
  var removed = true
  for entry in fs.walk(run_dir, gitignore: false, hidden: true)? |> where .kind == "dir" and .name == "worktrees" {
    for child in fs.children(entry.path, stat: false, ordered: true)? {
      if child.kind != "dir" {
        continue
      }
      let status = process.run(process.command_argv(
        "git",
        ["git", "-C", xsh_repo.display(), "worktree", "remove", "--force", child.path.display()],
      ))?
      if ! status.ok and fs.exists(child.path)? {
        removed = false
        eprint f"unable to remove run worktree: ${child.path.display()}"
      }
    }
  }
  let prune = process.run(process.command_argv(
    "git", ["git", "-C", xsh_repo.display(), "worktree", "prune"],
  ))?
  return removed and prune.ok
}

## Deferred-cleanup adapter for controller shutdown paths.
export proc cleanup_run_worktrees(xsh_repo: Path, run_dir: Path) [fs, process, error] -> Result[Unit] {
  let _ = remove_run_worktrees(xsh_repo, run_dir)?
  return Ok()
}

## Writes one event and advances its subject state atomically.
export proc emit_event(
  template: Path,
  run_dir: Path,
  name: Str,
  subject: Str,
  state: Str,
  attempt: Int,
  caused_by: Str,
  detail: Str,
) [fs, error] -> Result[Unit] {
  let events = fp"${run_dir}/events.jsonl"
  let states = fp"${run_dir}/states"
  let state_file = fp"${states}/${subject}.state"
  fs.mkdir(run_dir)?
  fs.mkdir(states)?
  let current = if fs.exists(state_file)? { fs.read_text(state_file)?.trim() } else { "created" }
  if ! control.transition_allowed(current, state) {
    return Err(RuntimeError.InvalidTransition(subject: subject, current: current, next: state))
  }
  let _ = template
  let event = {
    schema_version: 1,
    kind: "event",
    event_id: name,
    run_id: run_dir.display(),
    subject: subject,
    state: state,
    attempt: attempt,
    caused_by: caused_by,
    detail: detail,
  }
  let existing = if fs.exists(events)? { fs.read_text(events)? } else { "" }
  fs.write_atomic(events, existing + json.encode(event)? + "\n")?
  fs.write_atomic(state_file, state + "\n")?
  return Ok()
}

## Appends one complete process stream to the canonical cycle ledger. The
## source file remains as optional forensic storage; event consumers do not
## need to chase stdout/stderr paths to reconstruct a controller outcome.
export proc emit_process_output(
  run_dir: Path,
  process_id: Str,
  output_stream: Str,
  output: Path,
  exit_code: Int,
) [fs, error] -> Result[Unit] {
  let events = fp"${run_dir}/events.jsonl"
  let content = if fs.exists(output)? { fs.read_text(output)? } else { "" }
  let event = {
    schema_version: 1,
    kind: "process-output",
    event_id: f"${process_id}:${output_stream}",
    run_id: run_dir.display(),
    subject: process_id,
    state: "completed",
    channel: output_stream,
    exit_code: exit_code,
    content: content,
  }
  let existing = if fs.exists(events)? { fs.read_text(events)? } else { "" }
  fs.write_atomic(events, existing + json.encode(event)? + "\n")?
  return Ok()
}

## Advances an audited started phase to completed before later validation.
export proc mark_phase_completed(
  template: Path,
  run_dir: Path,
  name: Str,
  subject: Str,
  attempt: Int,
  caused_by: Str,
  detail: Str,
) [fs, error] -> Result[Unit] {
  return emit_event(template, run_dir, name, subject, "completed", attempt, caused_by, detail)
}

## Checks the checked-in ticket approval marker.
export proc accepted_ticket(ticket_path: Path) [fs, error] -> Result[Bool] {
  if ! fs.exists(ticket_path)? {
    return false
  }
  return control.ticket_is_accepted(fs.read_text(ticket_path)?)
}

proc budget_breach_section(
  factory_dir: Path,
  worker_dir: Path,
  reason: Str,
  worker_label: Str,
) [fs, error] -> Result[Str] {
  let worker_run = control.factory_relative_path(
    factory_dir.display(), fp"${worker_dir}/report.json"
  )
  let template = fp"${factory_dir}/templates/BUDGET-BREACH.md"
  let values: List[control.TemplateValue] = [
    {key: "REASON", value: reason},
    {key: "WORKER_LABEL", value: worker_label},
    {key: "WORKER_RUN", value: worker_run},
  ]
  return control.fill_template(template.read_text()?, values)
}

## Closes an over-budget engineer assignment in its checked-in ticket.
export proc close_ticket_too_difficult(
  factory_dir: Path,
  ticket_id: Str,
  worker_dir: Path,
) [fs, error] -> Result[Bool] {
  if ! control.valid_ticket_id(ticket_id) {
    return false
  }
  let ticket_path = fp"${factory_dir}/tickets/${ticket_id}.md"
  if ! fs.exists(ticket_path)? {
    return false
  }
  let ticket_text = ticket_path.read_text()?
  if control.ticket_is_merged(ticket_text) {
    return false
  }
  let breach = budget_breach_section(
    factory_dir, worker_dir, "too difficult", "engineer run"
  )?
  var updated = control.replace_status(ticket_text, "Closed.")
  updated = control.replace_section(updated, "Budget breach", breach)
  if updated != ticket_text {
    fs.write_atomic(ticket_path, updated)?
  }
  return true
}

## Disables an eval whose isolated eval-worker exceeded its hard budget.
export proc disable_eval(
  factory_dir: Path,
  eval_id: Str,
  worker_dir: Path,
) [fs, error] -> Result[Bool] {
  if ! control.valid_eval_id(eval_id) {
    return false
  }
  let eval_path = fp"${factory_dir}/evals/${eval_id}/EVAL.md"
  if ! fs.exists(eval_path)? {
    return false
  }
  let eval_text = eval_path.read_text()?
  let breach = budget_breach_section(
    factory_dir, worker_dir, "eval-worker budget exceeded", "eval-worker run"
  )?
  var updated = control.replace_eval_status(eval_text, "Disabled.")
  updated = control.replace_section(updated, "Budget breach", breach)
  if updated != eval_text {
    fs.write_atomic(eval_path, updated)?
  }
  return true
}

## Selects the first explicitly approved tickets for an organization cycle.
export proc first_approved_tickets(factory_dir: Path, limit: Int) [fs, error] -> Result[List[Str]] {
  let ticket_dir = fp"${factory_dir}/tickets"
  var selected: List[Str] = []
  if limit <= 0 { return selected }
  if ! fs.exists(ticket_dir)? {
    return selected
  }
  let entries = fs.files(ticket_dir, gitignore: false, hidden: true)?
    |> sort-by .path.display()
    |> collect()
  for entry in entries {
    if ! entry.name.ends_with(".md") {
      continue
    }
    if control.ticket_is_accepted(entry.path.read_text()?) {
      selected = selected.push(entry.name.replace(".md", ""))
      if selected.len() >= limit { return selected }
    }
  }
  return selected
}

## Backward-compatible single-ticket selector for focused controllers.
export proc first_approved_ticket(factory_dir: Path) [fs, error] -> Result[Str] {
  let selected = first_approved_tickets(factory_dir, 1)?
  return if selected.len() == 1 { selected[0] } else { "" }
}

## Builds the complete ticket inventory used by the CTO pre-cycle briefing.
## This is deterministic controller state, not a worker-selected work list.
export proc cto_ticket_inventory(
  factory_dir: Path,
  xsh_repo: Path,
) [fs, process, error] -> Result[List[Any]] {
  let ticket_dir = fp"${factory_dir}/tickets"
  var tickets: List[Any] = []
  if ! fs.exists(ticket_dir)? {
    return tickets
  }
  let entries = fs.files(ticket_dir, gitignore: false, hidden: true)?
    |> sort-by .path.display()
    |> collect()
  for entry in entries {
    if ! entry.name.ends_with(".md") {
      continue
    }
    let ticket_text = entry.path.read_text()?
    let status = control.ticket_status(ticket_text)
    let branch = if status == "Open." or status == "Approved." {
      open_ticket_branch(xsh_repo, entry.name.replace(".md", ""))?
    } else {
      ""
    }
    tickets = tickets.push({
      id: entry.name.replace(".md", ""),
      status: status,
      eval_id: control.ticket_eval(ticket_text),
      cto_review: ticket_text.contains("## CTO review"),
      open_branch: branch,
      path: entry.path.display(),
    })
  }
  return tickets
}

## Returns Open tickets that have no durable CTO review marker.
export pure cto_unreviewed_open_tickets(tickets: List[Any]) -> List[Str] {
  var unreviewed: List[Str] = []
  for ticket in tickets {
    if ticket.status == "Open." and ! ticket.cto_review {
      unreviewed = unreviewed.push(ticket.id)
    }
  }
  return unreviewed
}

## Renders the programmatic ticket inventory for a human CTO handoff.
export pure cto_inventory_markdown(tickets: List[Any]) -> Str {
  var open_count = 0
  var approved_count = 0
  var markdown = "# CTO ticket inventory\n\n"
  for ticket in tickets {
    if ticket.status == "Open." { open_count += 1 }
    if ticket.status == "Approved." or ticket.status == "Accepted." {
      approved_count += 1
    }
  }
  markdown = markdown + f"- Open tickets: ${open_count}\n"
  markdown = markdown + f"- Approved tickets: ${approved_count}\n"
  markdown = markdown + f"- Ticket rows: ${tickets.len()}\n\n"
  markdown = markdown + "| Ticket | Status | Linked eval | CTO review marker | Open branch |\n"
  markdown = markdown + "| --- | --- | --- | --- | --- |\n"
  for ticket in tickets {
    let review = if ticket.cto_review { "present" } else { "missing" }
    let branch = if ticket.open_branch == "" { "none" } else { ticket.open_branch }
    markdown = markdown + f"| `${ticket.id}` | `${ticket.status}` | `${ticket.eval_id}` | ${review} | `${branch}` |\n"
  }
  return markdown
}

## Persists the CTO inventory into a controller-owned run directory.
export proc write_cto_inventory(
  factory_dir: Path,
  run_dir: Path,
  xsh_repo: Path,
) [fs, process, error] -> Result[Unit] {
  let tickets = cto_ticket_inventory(factory_dir, xsh_repo)?
  fs.write_atomic(
    fp"${run_dir}/CTO-TICKET-INVENTORY.json",
    json.encode({tickets: tickets})? + "\n",
  )?
  fs.write_atomic(
    fp"${run_dir}/CTO-TICKET-INVENTORY.md",
    cto_inventory_markdown(tickets),
  )?
  return Ok()
}

proc commit_is_ancestor(xsh_repo: Path, commit: Str) [process, error] -> Result[Bool] {
  if commit == "" {
    return false
  }
  let status = process.run(process.command_argv(
    "git",
    ["git", "-C", xsh_repo.display(), "merge-base", "--is-ancestor", commit, "HEAD"],
  ))?
  return status.ok
}

proc commit_is_patch_applied(xsh_repo: Path, branch: Str, commit: Str) [process, error] -> Result[Bool] {
  if branch == "" or commit == "" {
    return false
  }
  let cherry = run.text "git" "-C" $xsh_repo.display() "cherry" "-v" "HEAD" $branch ?
  for line in cherry.lines() {
    if line.starts_with(f"- ${commit} ") {
      return true
    }
  }
  return false
}

proc commit_is_merged(xsh_repo: Path, branch: Str, commit: Str) [process, error] -> Result[Bool] {
  return commit_is_ancestor(xsh_repo, commit)? or commit_is_patch_applied(xsh_repo, branch, commit)?
}

## Finds an implementation branch that is still unmerged for one ticket.
export proc open_ticket_branch(xsh_repo: Path, ticket_id: Str) [process, error] -> Result[Str] {
  if ! control.valid_ticket_id(ticket_id) {
    return ""
  }
  let branch_prefix = f"refs/heads/factory/${ticket_id}/"
  let refs = run.text "git" "-C" $xsh_repo.display() "for-each-ref" "--format=%(refname:short)" $branch_prefix ?
  for branch_line in refs.lines() {
    let branch = branch_line.trim()
    if branch == "" {
      continue
    }
    let commit = run.text "git" "-C" $xsh_repo.display() "rev-parse" $branch ?
    if ! commit_is_merged(xsh_repo, branch, commit.trim())? {
      return branch
    }
  }
  return ""
}

proc find_merged_implementation(
  factory_dir: Path,
  xsh_repo: Path,
  ticket_id: Str,
  detected_xsh_commit: Str,
) [fs, process, error] -> Result[MergeEvidence] {
  let runs = fp"${factory_dir}/runs"
  if fs.exists(runs)? {
    for run_entry in fs.dirs(runs, gitignore: false, hidden: true)? {
      let run_dir = run_entry.path
      let summary = fp"${run_dir}/report.json"
      let report = fp"${run_dir}/workers/engineer/${ticket_id}/REPORT.md"
      if ! fs.exists(summary)? or ! fs.exists(report)? {
        continue
      }
      let report_text = fs.read_text(report)?
      let summary_value = json.read(summary)?
      let summary_result = match json.get(summary_value, ["result"], "") {
        s is Str => s,
        _ => "",
      }
      if summary_result != "pass" or
        ! control.engineer_report_contract_ok(report_text) {
        continue
      }
      let branch = control.report_field(report_text, "Branch")
      let commit = control.report_field(report_text, "Commit")
      if branch != "" and commit != "" and commit_is_merged(xsh_repo, branch, commit)? {
        return {
          merged: true,
          ticket_id: ticket_id,
          branch: branch,
          implementation_commit: commit,
          source_run: run_dir.display(),
          detected_xsh_commit: detected_xsh_commit,
        }
      }
    }
  }

  # Branch ancestry alone is not implementation evidence: an old ticket branch
  # can point at any historical XSH commit already contained in HEAD. Only a
  # passing engineer report with its exact implementation commit can reconcile
  # a ticket as merged.
  return {
    merged: false,
    ticket_id: ticket_id,
    branch: "",
    implementation_commit: "",
    source_run: "",
    detected_xsh_commit: detected_xsh_commit,
  }
}

## Reconciles approved tickets against the current XSH HEAD.
export proc reconcile_tickets(
  factory_dir: Path,
  xsh_repo: Path,
  detected_xsh_commit: Str,
) [fs, process, error] -> Result[List[MergedTicket]] {
  let ticket_dir = fp"${factory_dir}/tickets"
  var merged: List[MergedTicket] = []
  if ! fs.exists(ticket_dir)? {
    return merged
  }
  let ticket_template = fp"${factory_dir}/templates/TICKET.md"
  let merge_section_template = control.section_text(ticket_template.read_text()?, "Merge record")
  if merge_section_template == "" {
    return Err(RuntimeError.InvalidTransition(
      subject: "ticket-template",
      current: "missing-merge-record",
      next: "reconcile",
    ))
  }
  for entry in fs.files(ticket_dir, gitignore: false, hidden: true)? {
    if ! entry.name.ends_with(".md") {
      continue
    }
    let ticket_id = entry.name.replace(".md", "")
    let ticket_path = entry.path
    let ticket_text = fs.read_text(ticket_path)?
    let status = control.ticket_status(ticket_text)
    if status != "Accepted." and status != "Approved." and status != "Merged." {
      continue
    }
    if status == "Merged." and control.ticket_merge_record_complete(ticket_text) {
      continue
    }
    let evidence = find_merged_implementation(
      factory_dir, xsh_repo, ticket_id, detected_xsh_commit
    )?
    if ! evidence.merged {
      continue
    }
    let values: List[control.TemplateValue] = [
      {key: "IMPLEMENTATION_BRANCH", value: evidence.branch},
      {key: "IMPLEMENTATION_COMMIT", value: evidence.implementation_commit},
      {key: "DETECTED_XSH_COMMIT", value: detected_xsh_commit},
      {key: "IMPLEMENTATION_RUN", value: evidence.source_run},
    ]
    let merge_record = control.fill_template(merge_section_template, values)
    let updated_status = control.replace_ticket_status(ticket_text, "Merged.")
    let updated_ticket = control.replace_ticket_section(updated_status, "Merge record", merge_record)
    if updated_ticket != ticket_text {
      fs.write(ticket_path, updated_ticket)?
    }
    merged = merged.push({
      ticket_id: evidence.ticket_id,
      eval_id: control.ticket_eval(ticket_text),
      branch: evidence.branch,
      implementation_commit: evidence.implementation_commit,
      source_run: evidence.source_run,
      detected_xsh_commit: evidence.detected_xsh_commit,
    })
  }
  return merged
}

## Proves that a Pi session called the read tool for one exact path.
export proc session_read_path(session: Path, expected: Path) [fs, error] -> Result[Bool] {
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

## Acquires a run lock at an explicit scope.
export proc acquire_run_lock_at(lock_path: Path) [fs, error] -> Result[Record] {
  return fs.lock(lock_path, nonblocking: true)
}

## Acquires the single-factory run lock and rejects concurrent direct cycles.
export proc acquire_run_lock(factory_dir: Path) [fs, error] -> Result[Record] {
  let runs = fp"${factory_dir}/runs"
  fs.mkdir(runs)?
  return acquire_run_lock_at(fp"${runs}/factory.lock")
}

## Verifies the checked-in handbook has not changed during a run.
export proc verify_factory_handbook(factory_dir: Path, expected_sha: Str) [fs, error] -> Result[Bool] {
  let handbook = fp"${factory_dir}/runtime/handbook.md"
  return fs.exists(handbook)? and hash.sha256(handbook)?.hex() == expected_sha
}

## Counts historical candidate snapshots with no explicit ledger disposition.
## A nonzero result blocks the next paid cycle until the CTO promotes or
## rejects the candidate; lineage files must never become invisible backlog.
export proc unresolved_handbook_candidates(factory_dir: Path) [fs, error] -> Result[Int] {
  let handbook = fp"${factory_dir}/runtime/handbook.md"
  let runs_dir = fp"${factory_dir}/runs"
  let ledger_path = fp"${factory_dir}/runtime/handbook-ledger.md"
  if ! fs.exists(handbook)? or ! fs.exists(runs_dir)? {
    return 0
  }
  let current_sha = hash.sha256(handbook)?.hex()
  let ledger = if fs.exists(ledger_path)? { ledger_path.read_text()? } else { "" }
  var unresolved = 0
  for entry in fs.walk(runs_dir, gitignore: false, hidden: true)? |> where .kind == "file" {
    if entry.name != "handbook-candidate.md" {
      continue
    }
    let sha = hash.sha256(entry.path)?.hex()
    if sha != current_sha and ! ledger.contains(sha) {
      unresolved = unresolved + 1
    }
  }
  return unresolved
}
