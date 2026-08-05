##! Idempotent, run-scoped cleanup that preserves durable evidence.

use factory.paths as paths

## A transient run file may be removed after ownership has been proven.
export pure transient_name(name: Str) -> Bool {
  return name == "ACTIVE" or name == "ORGANIZATION-ACTIVE" or name == "factory.lock" or
    name.ends_with(".pids") or name.ends_with(".cid") or name.ends_with(".stdout") or
    name.ends_with(".stderr") or name.ends_with(".claimed") or name.ends_with(".lock")
}

## Durable reports, sessions, patches, and lifecycle events are never transient.
export pure durable_name(name: Str) -> Bool {
  return name == "report.json" or name == "REPORT.md" or name == "CTO-REPORT.md" or
    name == "events.jsonl" or name == "POSTMORTEM.md" or name.ends_with(".jsonl.bz2") or
    name.ends_with(".diff")
}

## Returns whether a path is safe to remove under a run root.
export pure removable(run_root: Path, candidate: Path, name: Str) -> Result[Bool] {
  if ! paths.within(run_root, candidate)? { return Ok(false) }
  if durable_name(name) { return Ok(false) }
  return Ok(transient_name(name))
}

## Removes only known transient files under one run; evidence is preserved.
export proc run_scoped(run_dir: Path) [fs, error] -> Result[Unit] {
  if ! fs.exists(run_dir)? { return Ok() }
  for entry in fs.walk(run_dir, gitignore: false, hidden: true)? |> where .kind == "file" {
    if paths.real_within(run_dir, entry.path)? and removable(run_dir, entry.path, entry.name)? {
      fs.remove(entry.path, missing_ok: true)?
    }
  }
  return Ok()
}
