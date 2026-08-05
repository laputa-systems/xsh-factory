##! Enforce the hard aggregate spend cap for one factory cycle.

use factory.runtime as runtime
use factory.control as control

type CostReport = {total: Float, seen: Bool, unknown: Bool, unavailable: Bool}

pure json_number(value: Any) -> Float {
  match value {
    i is Int => return i.float()
    f is Float => return f
    _ => return 0.0
  }
}

stream walk_failure(run_dir: Path) [fs, error] -> Stream[Record] {
  yield {kind: "__walk_error__", name: "", path: run_dir}
}

proc reported_cost(run_dir: Path) [fs, process, error] -> Result[CostReport] {
  var total = 0.0
  var seen = false
  var unknown = false
  var unavailable = false
  if ! fs.exists(run_dir)? {
    return Ok({total: total, seen: seen, unknown: true, unavailable: true})
  }
  let fallback = walk_failure(run_dir)
  let entries = fs.walk(run_dir, gitignore: false, hidden: true) ?? fallback
  for entry in entries {
    if entry.kind == "__walk_error__" {
      unavailable = true
      continue
    }
    if entry.kind != "file" {
      continue
    }
    if entry.name != "session.jsonl" and entry.name != "session.jsonl.bz2" {
      continue
    }
    let session_text = runtime.session_text(entry.path)?
    for line in session_text.lines() {
      match json.decode(line) {
        Ok(entry_record) => {
          match json.get(entry_record, ["message"], null) {
            message is Record => {
              match json.get(message, ["usage"], null) {
                usage is Record => {
                  match json.get(usage, ["cost"], null) {
                    cost is Record => {
                      let value = json.get(cost, ["total"], null)
                      match value {
                        _ is Int => { total += json_number(value); seen = true }
                        _ is Float => { total += json_number(value); seen = true }
                        _ => { unknown = true }
                      }
                    }
                    _ => { unknown = true }
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
  }
  if unavailable {
    return Ok({total: total, seen: seen, unknown: true, unavailable: true})
  }
  return Ok({total: total, seen: seen, unknown: unknown, unavailable: false})
}

proc process_live(pid: Int) [process, error] -> Result[Bool] {
  return Ok(process.list()? |> any .pid == pid)
}

proc write_postmortem(
  factory_dir: Path,
  run_dir: Path,
  cap: Float,
  observed: Str,
  controller_pid: Int,
  reason: Str,
  output_path: Path,
) [fs, error] -> Result[Unit] {
  let template = fp"${factory_dir}/templates/POSTMORTEM.md"
  let values: List[control.TemplateValue] = [
    {key: "RUN_DIR", value: run_dir.display()},
    {key: "CAP", value: cap.format(precision: 2)},
    {key: "OBSERVED_SPEND", value: observed},
    {key: "CONTROLLER_PID", value: f"${controller_pid}"},
    {key: "REASON", value: reason},
    {key: "CLEANUP", value: "cleanup-run.xsh completed its shutdown pass"},
  ]
  fs.write_atomic(
    output_path,
    control.fill_template(template.read_text()?, values),
  )?
  return Ok()
}

proc stop_controller(controller_pid: Int) [process, error] -> Result[Unit] {
  match process.kill(controller_pid, signal: "TERM") {
    Ok(_) => {}
    Err(_) => {}
  }
  return Ok()
}

proc main(...argv: List[Str]) [fs, process, env, time, error, io] {
  if argv.len() < 12 {
    eprint "usage: cycle-budget-watch.xsh --run-dir PATH --pid PID --budget-usd USD --marker PATH --stop PATH --postmortem PATH"
    abort(2)
  }
  let run_dir = Path(argv[1])
  let controller_pid = argv[3].parse_int()?
  let requested_cap = argv[5]
  let cap = control.clamp_cycle_budget(requested_cap)?.parse_float()?
  let marker = Path(argv[7])
  let stop = Path(argv[9])
  let postmortem = Path(argv[11])
  let factory_dir = env.path("FACTORY_DIR", fs.cwd()?)?

  while true {
    let cost = reported_cost(run_dir)?
    if cost.unavailable or cost.unknown or cost.total > cap {
      let reason = if cost.unavailable {
        "aggregate cost evidence could not be enumerated"
      } else if cost.unknown {
        "worker cost was unknown"
      } else {
        "aggregate cycle budget exceeded"
      }
      let observed = if cost.unknown { "unknown" } else { cost.total.format(precision: 6) }
      fs.write_atomic(
        marker,
        f"budget exceeded: ${observed} > ${cap.format(precision: 2)}\n",
      )?
      write_postmortem(factory_dir, run_dir, cap, observed, controller_pid, reason, postmortem)?
      let cleanup = fp"${factory_dir}/factory/tools/cleanup-run.xsh"
      let xsh = process.which("xsh")?
      let _ = process.run(process.command_argv(
        xsh,
        [xsh.display(), cleanup.display(), "--", run_dir.display()],
      ))?
      stop_controller(controller_pid)?
      abort(3)
    }
    if fs.exists(stop)? or ! process_live(controller_pid)? {
      abort(0)
    }
    time.sleep(100ms)?
  }
  abort(0)
}
