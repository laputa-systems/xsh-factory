##! Shared process-boundary helpers for every factory cycle mode.

use factory_control as control

error RuntimeError = InvalidTransition(subject: Str, current: Str, next: Str) : InvalidData

## Terminates all registered children of the active run.
export proc cleanup_active_run() [fs, process, env, error] -> Result[Unit] {
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

## Acquires the single-factory run lock and rejects concurrent cycles.
export proc acquire_run_lock(factory_dir: Path) [fs, error] -> Result[Record] {
  let runs = fp"${factory_dir}/runs"
  fs.mkdir(runs)?
  return fs.lock(fp"${runs}/factory.lock", nonblocking: true)
}

## Verifies the checked-in handbook has not changed during a run.
export proc verify_factory_handbook(factory_dir: Path, expected_sha: Str) [fs, error] -> Result[Bool] {
  let handbook = fp"${factory_dir}/runtime/handbook.md"
  return fs.exists(handbook)? and hash.sha256(handbook)?.hex() == expected_sha
}
