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
    let cleanup = fp"${factory_dir}/tools/cleanup-run.xsh"
    let _ = process.run(process.command_argv(
      xsh_path,
      [xsh_path.display(), cleanup.display(), "--", run_text],
    ))?
  }
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
  let events = fp"${run_dir}/events"
  let states = fp"${run_dir}/states"
  let state_file = fp"${states}/${subject}.state"
  fs.mkdir(events)?
  fs.mkdir(states)?
  let current = if fs.exists(state_file)? { fs.read_text(state_file)?.trim() } else { "created" }
  if ! control.transition_allowed(current, state) {
    return Err(RuntimeError.InvalidTransition(subject: subject, current: current, next: state))
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

## Checks the checked-in ticket approval marker.
export proc accepted_ticket(ticket_path: Path) [fs, error] -> Result[Bool] {
  if ! fs.exists(ticket_path)? {
    return false
  }
  return control.ticket_is_accepted(fs.read_text(ticket_path)?)
}

## Selects the first explicitly approved ticket for an organization cycle.
export proc first_approved_ticket(factory_dir: Path) [fs, error] -> Result[Str] {
  let ticket_dir = fp"${factory_dir}/tickets"
  if ! fs.exists(ticket_dir)? {
    return ""
  }
  let entries = fs.files(ticket_dir, gitignore: false, hidden: true)?
    |> sort-by .path.display()
    |> collect()
  for entry in entries {
    if ! entry.name.ends_with(".md") {
      continue
    }
    if control.ticket_is_accepted(entry.path.read_text()?) {
      return entry.name.replace(".md", "")
    }
  }
  return ""
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
      let summary = fp"${run_dir}/RUN.md"
      let report = fp"${run_dir}/workers/xsh-swe/${ticket_id}/SWE-REPORT.md"
      if ! fs.exists(summary)? or ! fs.exists(report)? {
        continue
      }
      let summary_text = fs.read_text(summary)?
      let report_text = fs.read_text(report)?
      if ! summary_text.contains("## Result\n\npass") or
        ! control.swe_report_contract_ok(report_text) {
        continue
      }
      let branch = control.report_field(report_text, "Branch")
      let commit = control.report_field(report_text, "Commit")
      if branch != "" and commit != "" and commit_is_ancestor(xsh_repo, commit)? {
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

  let branch_prefix = f"refs/heads/factory/${ticket_id}/"
  let refs = run.text "git" "-C" $xsh_repo.display() "for-each-ref" "--format=%(refname:short)" $branch_prefix ?
  for branch_line in refs.lines() {
    let branch = branch_line.trim()
    if branch == "" {
      continue
    }
    let commit = run.text "git" "-C" $xsh_repo.display() "rev-parse" $branch ?
    if commit_is_ancestor(xsh_repo, commit.trim())? {
      return {
        merged: true,
        ticket_id: ticket_id,
        branch: branch,
        implementation_commit: commit.trim(),
        source_run: "git branch provenance",
        detected_xsh_commit: detected_xsh_commit,
      }
    }
  }

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
