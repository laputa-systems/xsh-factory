##! Read-only live and completed-cycle inspection for the CTO.
use factory.schema as schema

pure text(value: Any, fallback: Str = "unknown") -> Str {
  let rendered = schema.value_text(value)
  return if rendered == "" { fallback } else { rendered }
}

pure integer(value: Any) -> Int {
  match value {
    i is Int => return i
    _ => return 0
  }
}

pure run_id(run_dir: Path) -> Str {
  return run_dir.name()
}

pure phase_id(path_value: Path) -> Str {
  let parts = path_value.display().split("/")
  var after_phases = false
  for part in parts {
    if after_phases {
      return part
    }
    if part == "phases" {
      after_phases = true
    }
  }
  return "unknown"
}

pure worker_identity(path_value: Path) -> Any {
  let parts = path_value.display().split("/")
  var after_workers = false
  var role = "unknown"
  for part in parts {
    if after_workers {
      if role == "unknown" {
        role = part
      } else {
        return {role: role, worker_id: part}
      }
    }
    if part == "workers" {
      after_workers = true
    }
  }
  return {role: role, worker_id: "unknown"}
}

pure relative_path(run_dir: Path, path_value: Path) -> Str {
  let path_text = path_value.display()
  let marker = f"/${run_dir.name()}/"
  let marker_at = path_text.find(marker)
  if marker_at >= 0 {
    return path_text.byte_slice(marker_at + marker.byte_len(), path_text.byte_len() - marker_at - marker.byte_len())
  }
  return path_text.replace(f"${run_dir.display()}/", "")
}

proc event_summary(run_dir: Path) [fs, error] -> Result[Any] {
  let events = fp"${run_dir}/events.jsonl"
  if ! fs.exists(events)? {
    return {event_id: "none", state: "unknown", subject: "unknown", detail: "no events.jsonl"}
  }

  var latest = {event_id: "none", state: "unknown", subject: "unknown", detail: ""}
  var adaptive = "not recorded"
  for line in fs.read_text(events)?.lines() {
    let trimmed = line.trim()
    continue when trimmed == ""
    match json.decode(trimmed) {
      Ok(value) => {
        let event_id = text(json.get(value, ["event_id"], "unknown"))
        let state = text(json.get(value, ["state"], "unknown"))
        let subject = text(json.get(value, ["subject"], "unknown"))
        let detail = text(json.get(value, ["detail"], ""), "")
        latest = {event_id: event_id, state: state, subject: subject, detail: detail}
        if event_id == "05-adaptive-queue-selected" {
          adaptive = detail
        }
      }
      Err(_) => {}
    }
  }

  return {latest: latest, adaptive: adaptive}
}

proc phase_rows(run_dir: Path) [fs, error] -> Result[List[Any]] {
  var rows: List[Any] = []
  for entry in fs.files(run_dir, gitignore: false, hidden: true) {
    let path_text = entry.path.display()
    continue when entry.name != "report.json" or "/phases/" not in path_text or "/workers/" in path_text
    let report = json.read(entry.path)?
    rows = rows.push({
      id: phase_id(entry.path),
      path: relative_path(run_dir, entry.path),
      state: text(json.get(report, ["state"], "unknown")),
      result: text(json.get(report, ["result"], "unknown")),
    })
  }
  rows |> sort-by .id
}

proc worker_rows(run_dir: Path) [fs, error] -> Result[List[Any]] {
  var rows: List[Any] = []
  for entry in fs.files(run_dir, gitignore: false, hidden: true) {
    let path_text = entry.path.display()
    continue when entry.name != "report.json" or "/workers/" not in path_text
    let report = json.read(entry.path)?
    let identity = worker_identity(entry.path)
    let usage = json.get(report, ["usage"], null)
    rows = rows.push({
      role: text(json.get(identity, ["role"], "unknown")),
      worker_id: text(json.get(identity, ["worker_id"], "unknown")),
      path: relative_path(run_dir, entry.path),
      state: text(json.get(report, ["state"], "completed")),
      result: text(json.get(report, ["result"], "unknown")),
      turns: integer(json.get(usage, ["assistant_turns"], 0)),
      cost_usd: json.get(usage, ["cost_usd"], "unknown"),
      tool_errors: integer(json.get(usage, ["tool_errors"], 0)),
    })
  }
  rows |> sort-by .path
}

proc active_processes(run_dir: Path) [fs, process, error] -> Result[List[Any]] {
  var rows: List[Any] = []
  let processes = process.list()?
  for entry in fs.files(run_dir, gitignore: false, hidden: true) {
    continue when ! entry.name.ends_with(".pids")
    let pid_text = entry.path.read_text()?.trim()
    match pid_text.parse_int() {
      Ok(pid) => {
        if processes |> any .pid == pid {
          rows = rows.push({
            label: relative_path(run_dir, entry.path).replace(".pids", ""),
            pid: pid,
          })
        }
      }
      Err(_) => {}
    }
  }
  rows |> sort-by .label
}

proc budget_state(run_dir: Path, root: Any) [fs, error] -> Result[Any] {
  let cost = json.get(json.get(root, ["data"], null), ["cost"], null)
  return {
    observed_usd: json.get(cost, ["cost_usd"], "not reported"),
    breach: fs.exists(fp"${run_dir}/AGGREGATE-BUDGET-BREACH")?,
    stop: fs.exists(fp"${run_dir}/AGGREGATE-BUDGET-STOP")?,
    postmortem: fs.exists(fp"${run_dir}/POSTMORTEM.md")?,
  }
}

proc main(...argv: List[Str]) [fs, process, env, error, io] {
  var run_dir: Path? = null
  var format = "table"
  var index = 0
  while index < argv.len() {
    if argv[index] == "--run-dir" and index + 1 < argv.len() {
      run_dir = fp"${argv[index + 1]}"
      index += 2
    } else if argv[index] == "--format" and index + 1 < argv.len() {
      format = argv[index + 1]
      index += 2
    } else {
      eprint "usage: run-status.xsh --run-dir PATH [--format table|json]"
      abort(2)
    }
  }

  if run_dir == null or (format != "table" and format != "json") {
    eprint "usage: run-status.xsh --run-dir PATH [--format table|json]"
    abort(2)
  }
  let selected = run_dir ?? fp"."
  if ! fs.exists(selected)? {
    eprint f"run directory does not exist: ${selected.display()}"
    abort(2)
  }

  let root_path = fp"${selected}/report.json"
  let root_exists = fs.exists(root_path)?
  let root = if root_exists { json.read(root_path)? } else { null }
  let event_data = event_summary(selected)?
  let latest = json.get(event_data, ["latest"], null)
  let phases = phase_rows(selected)?
  let workers = worker_rows(selected)?
  let active = active_processes(selected)?
  let budget = budget_state(selected, root)?
  let state = if root_exists { text(json.get(root, ["state"], "reported")) } else { "running" }
  let result = if root_exists { text(json.get(root, ["result"], "pending")) } else { "pending" }
  let data = {
    run_id: run_id(selected),
    run_dir: selected.display(),
    state: state,
    result: result,
    latest_event: latest,
    adaptive_queue: json.get(event_data, ["adaptive"], "not recorded"),
    budget: budget,
    active_processes: active,
    phases: phases,
    workers: workers,
  }

  if format == "json" {
    print (json.encode(data, pretty: true)?)
    return
  }

  print f"RUN ${run_id(selected)} STATE ${state} RESULT ${result}"
  print f"PATH ${selected.display()}"
  print f"LAST ${text(json.get(latest, ["event_id"], "none"))} ${text(json.get(latest, ["state"], "unknown"))} ${text(json.get(latest, ["subject"], "unknown"))} ${text(json.get(latest, ["detail"], ""), "")}" 
  print f"QUEUE ${text(json.get(event_data, ["adaptive"], "not recorded"), "not recorded")}"
  print f"BUDGET cost=${text(json.get(budget, ["observed_usd"], "not reported"))} breach=${text(json.get(budget, ["breach"], false))} stop=${text(json.get(budget, ["stop"], false))} postmortem=${text(json.get(budget, ["postmortem"], false))}"
  print f"ACTIVE ${active.len()}"
  for item in active {
    print f"  ${text(json.get(item, ["label"], "unknown"))} pid=${text(json.get(item, ["pid"], "unknown"))}"
  }
  print "PHASES"
  for phase in phases {
    print f"  ${text(json.get(phase, ["id"], "unknown"))} ${text(json.get(phase, ["state"], "unknown"))} ${text(json.get(phase, ["result"], "unknown"))}"
  }
  print "WORKERS"
  for worker in workers {
    print f"  ${text(json.get(worker, ["role"], "unknown"))}/${text(json.get(worker, ["worker_id"], "unknown"))} ${text(json.get(worker, ["result"], "unknown"))} turns=${text(json.get(worker, ["turns"], 0))} cost=${text(json.get(worker, ["cost_usd"], "unknown"))} errors=${text(json.get(worker, ["tool_errors"], 0))}"
  }
}
