##! Drain the process and container registry for an interrupted factory run.

proc signal_registry(run_dir: Path, signal: Str, excluded_pid: Int) [fs, process, error] -> Result[Unit] {
  if ! fs.exists(run_dir)? {
    return Ok()
  }
  for entry in fs.walk(run_dir, gitignore: false, hidden: true)? |> where .kind == "file" {
    if entry.name.ends_with(".pids") {
      for line in entry.path.read_text()?.lines() {
        let text = line.trim()
        if text != "" {
          match text.parse_int() {
            Ok(pid) => {
              if pid == excluded_pid {
                continue
              }
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
  for entry in fs.walk(run_dir, gitignore: false, hidden: true)? |> where .kind == "file" {
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
    eprint "usage: cleanup-run.xsh RUN_DIR [--exclude-pid PID]"
    abort(2)
  }
  let run_dir = Path(argv[0])
  let excluded_pid = if argv.len() >= 3 and argv[1] == "--exclude-pid" {
    argv[2].parse_int()?
  } else {
    -1
  }
  signal_registry(run_dir, "INT", excluded_pid)?
  stop_containers(run_dir)?
  time.sleep(250ms)?
  signal_registry(run_dir, "KILL", excluded_pid)?
  stop_containers(run_dir)?
  fs.remove(fp"${run_dir}/ACTIVE", missing_ok: true)?
  fs.remove(fp"${run_dir.parent()}/ACTIVE", missing_ok: true)?
  fs.remove(fp"${run_dir.parent()}/ORGANIZATION-ACTIVE", missing_ok: true)?
  abort(0)
}
