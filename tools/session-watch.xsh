use factory_runtime as runtime
##! Stop a Pi process when its turn or wall-clock ceiling is reached.

pure json_text(value: Any) -> Str {
  match value {
    s is Str => return s
    i is Int => return f"${i}"
    f is Float => return f.format(precision: 0)
    b is Bool => return if b { "true" } else { "false" }
    _ => return ""
  }
}

proc assistant_turns(session_path: Path) [fs, process, error] -> Result[Int] {
  var turns = 0
  if ! fs.exists(session_path)? { return Ok(turns) }
  let session_text = runtime.session_text(session_path)?
  for line in session_text.lines() {
    match json.decode(line) {
      Ok(entry) => {
        if json_text(json.get(entry, ["type"], "")) != "message" { continue }
        match json.get(entry, ["message"], null) {
          message is Record => {
            if json_text(json.get(message, ["role"], "")) == "assistant" {
              turns += 1
            }
          }
          _ => {}
        }
      }
      Err(_) => {}
    }
  }
  return Ok(turns)
}

proc process_live(pid: Int) [process, error] -> Result[Bool] {
  return Ok(process.list()? |> any .pid == pid)
}

proc parse_positive(value: Str) [error] -> Result[Int] {
  let parsed = value.parse_int()?
  if parsed <= 0 { return Ok(1) }
  return Ok(parsed)
}

proc main(...argv: List[Str]) [fs, process, time, error, io] {
  if argv.len() < 12 {
    eprint "usage: session-watch.xsh --session PATH --pid PID --max-turns N --max-seconds N --marker PATH"
    abort(2)
  }
  let session = Path(argv[1])
  let pid = argv[3].parse_int()?
  let max_turns = parse_positive(argv[5])?
  let max_seconds = parse_positive(argv[7])?
  let marker = Path(argv[9])
  let role = if argv.len() > 11 { argv[11] } else { "worker" }
  let started = time.now()
  while process_live(pid)? {
    let turns = assistant_turns(session)?
    if turns >= max_turns {
      fs.write_atomic(marker, f"${role} session turn limit exceeded: ${turns} >= ${max_turns}\n")?
      match process.kill(pid, signal: "TERM") {
        Ok(_) => {}
        Err(_) => {}
      }
      abort(3)
    }
    let elapsed = time.now() - started
    if elapsed >= max_seconds * 1000 {
      fs.write_atomic(marker, f"${role} session wall limit exceeded: ${elapsed}ms >= ${max_seconds}s\n")?
      match process.kill(pid, signal: "TERM") {
        Ok(_) => {}
        Err(_) => {}
      }
      abort(3)
    }
    time.sleep(100ms)?
  }
  abort(0)
}
