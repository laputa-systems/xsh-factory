##! Drain the process and container registry for an interrupted factory run.

proc signal_registry(run_dir: Path, signal: Str) [fs, process, error] -> Result[Unit] {
  let registry = fp"${run_dir}/processes"
  if ! fs.exists(registry)? {
    return Ok()
  }
  for entry in fs.files(registry, gitignore: false, hidden: true)? {
    if entry.name.ends_with(".pids") {
      for line in entry.path.read_text()?.lines() {
        let text = line.trim()
        if text != "" {
          match text.parse_int() {
            Ok(pid) => {
              match unix.kill_process_group(pid, signal) {
                Ok(_) => {}
                Err(_) => {
                  let _ = process.kill(pid, signal)
                }
              }
            }
            Err(_) => {}
          }
        }
      }
    }
  }
  return Ok()
}

proc stop_containers(run_dir: Path) [fs, process, env, error] -> Result[Unit] {
  let docker = env.get_or("DOCKER", "docker")?
  for entry in fs.files(run_dir, gitignore: false, hidden: true)? {
    if entry.name.ends_with(".cid") {
      let container_id = entry.path.read_text()?.trim()
      if container_id != "" {
        let _ = process.run(process.command_argv(
          docker,
          [docker, "rm", "-f", container_id],
        ))
      }
    }
  }
  return Ok()
}

proc main(...argv: List[Str]) [fs, process, env, time, error, io] {
  if argv.len() < 1 {
    eprint "usage: cleanup-run.xsh RUN_DIR"
    abort(2)
  }
  let run_dir = Path(argv[0])
  signal_registry(run_dir, "INT")?
  stop_containers(run_dir)?
  time.sleep(250ms)?
  signal_registry(run_dir, "KILL")?
  stop_containers(run_dir)?
  fs.remove(fp"${run_dir.parent()}/ACTIVE", missing_ok: true)?
  abort(0)
}
