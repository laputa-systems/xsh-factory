##! Stop a Pi process when its reported session cost crosses the hard cap.

type CostReport = {total: Float, seen: Bool}

pure json_number(value: Any) -> Float {
  match value {
    i is Int => return i.float()
    f is Float => return f
    _ => return 0.0
  }
}

proc reported_cost(session_path: Path) [fs, error] -> Result[CostReport] {
  var total = 0.0
  var seen = false
  if ! fs.exists(session_path)? { return Ok({total: total, seen: seen}) }
  for line in session_path.read_text()?.lines() {
    match json.decode(line) {
      Ok(entry) => {
        match json.get(entry, ["message"], null) {
          message is Record => {
            match json.get(message, ["usage"], null) {
              usage is Record => {
                match json.get(usage, ["cost"], null) {
                  cost is Record => {
                    let value = json.get(cost, ["total"], null)
                    match value {
                      _ is Int => { total += json_number(value); seen = true }
                      _ is Float => { total += json_number(value); seen = true }
                      _ => {}
                    }
                  }
                  _ => {}
                }
              }
              _ => {}
            }
          }
          _ => {}
        }
      }
      Err(_) => {}
    }
  }
  return Ok({total: total, seen: seen})
}

proc process_live(pid: Int) [process, error] -> Result[Bool] {
  return Ok(process.list()? |> any .pid == pid)
}

proc parse_budget(value: Str) [error] -> Result[Float] {
  let parts = value.split(".", maxsplit: 1)
  let whole = parts[0].parse_int()?
  if parts.len() == 1 or parts[1] == "" { return Ok(whole.float()) }
  let fraction = parts[1].parse_int()?
  var divisor = 1
  for _ in range(parts[1].count_chars()) { divisor *= 10 }
  if whole < 0 { return Ok(whole.float() - fraction.float() / divisor.float()) }
  return Ok(whole.float() + fraction.float() / divisor.float())
}

proc main(...argv: List[Str]) [fs, process, time, error, io] {
  if argv.len() < 8 {
    eprint "usage: budget-watch.xsh --session PATH --pid PID --budget-usd USD --marker PATH"
    abort(2)
  }
  let session = Path(argv[1])
  let pid = argv[3].parse_int()?
  let budget = parse_budget(argv[5])?
  let marker = Path(argv[7])
  while process_live(pid)? {
    let cost = reported_cost(session)?
    if cost.total > budget {
      fs.write(marker, f"budget exceeded: ${cost.total.format(precision: 6)} > ${budget.format(precision: 2)}\n")?
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
