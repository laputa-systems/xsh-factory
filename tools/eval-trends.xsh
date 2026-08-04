##! Summarize historical eval-worker effort by eval and run.

use report_schema as schema

type Sample = {
  eval_id: Str,
  run_id: Str,
  path: Str,
  turns: Int,
  tokens: Int,
  errors: Int,
  wall_ms: Int,
  retries: Int,
  provider_errors: Int,
  result: Str,
  classification: Str,
}

pure text(value: Any, fallback: Str = "unknown") -> Str {
  let rendered = schema.value_text(value)
  return if rendered == "" { fallback } else { rendered }
}

pure number(value: Any) -> Float {
  match value {
    i is Int => return i.float()
    f is Float => return f
    _ => return 0.0
  }
}

pure integer(value: Any) -> Int {
  match value {
    i is Int => return i
    _ => return 0
  }
}

pure run_id_for(path_value: Path) -> Str {
  let parts = path_value.display().split("/")
  var after_runs = false
  for part in parts {
    if after_runs { return part }
    if part == "runs" { after_runs = true }
  }
  return "unknown"
}

pure eval_id_for(report: Any, path_value: Path) -> Str {
  let identity = json.get(report, ["identity"], null)
  let explicit = text(json.get(identity, ["eval_id"], ""), "")
  if explicit != "" { return explicit }
  let parts = path_value.display().split("/")
  var after_worker = false
  for part in parts {
    if after_worker { return part.replace("-1", "").replace("-2", "") }
    if part == "eval-worker" { after_worker = true }
  }
  return "unknown"
}

proc read_samples(factory_dir: Path) [fs, error] -> Result[List[Sample]] {
  var samples: List[Sample] = []
  let runs = fp"${factory_dir}/runs"
  if ! fs.exists(runs)? { return samples }
  for entry in fs.walk(runs, gitignore: false, hidden: true) |> where .kind == "file" {
    if entry.name != "report.json" or ! entry.path.display().contains("/workers/eval-worker/") {
      continue
    }
    let report = json.read(entry.path)?
    if ! schema.valid(report, "worker") { continue }
    let identity = json.get(report, ["identity"], null)
    let execution = json.get(report, ["execution"], null)
    let usage = json.get(report, ["usage"], null)
    let timing = json.get(report, ["timing"], null)
    let telemetry = json.get(report, ["provider_telemetry"], null)
    let provider_errors = json.get(telemetry, ["provider_errors"], [])
    let provider_error_count = match provider_errors {
      values is List[Any] => values.len()
      _ => 0
    }
    samples = samples.push({
      eval_id: eval_id_for(report, entry.path),
      run_id: text(json.get(identity, ["run_id"], run_id_for(entry.path)), run_id_for(entry.path)),
      path: entry.path.display(),
      turns: integer(json.get(usage, ["assistant_turns"], 0)),
      tokens: integer(json.get(usage, ["total_bucket_tokens"], 0)),
      errors: integer(json.get(usage, ["tool_errors"], 0)),
      wall_ms: integer(json.get(timing, ["session_span_ms"], 0)),
      retries: integer(json.get(telemetry, ["retry_count"], 0)),
      provider_errors: provider_error_count,
      result: text(json.get(report, ["result"], "unknown")),
      classification: text(json.get(execution, ["classification"], "unknown")),
    })
  }
  return samples
}

pure ordered_samples(samples: List[Sample]) -> List[Sample] {
  return samples |> sort-by .path
}

pure median_int(values: List[Int]) -> Int {
  if values.len() == 0 { return 0 }
  return values[values.len() / 2]
}

pure percentile_int(values: List[Int], percent: Int) -> Int {
  if values.len() == 0 { return 0 }
  return values[((values.len() - 1) * percent) / 100]
}

pure median_metric(values: List[Int]) -> Int {
  if values.len() == 0 { return 0 }
  return values[values.len() / 2]
}

pure percentile_metric(values: List[Int], percent: Int) -> Int {
  if values.len() == 0 { return 0 }
  return values[((values.len() - 1) * percent) / 100]
}

pure row(eval_id: Str, run_id: Str, samples: List[Sample]) -> Any {
  var turns: List[Int] = []
  var tokens: List[Int] = []
  var errors: List[Int] = []
  var wall: List[Int] = []
  var passed = 0
  var retries = 0
  var provider_errors = 0
  let ordered = samples |> sort-by .turns
  for sample in samples {
    turns = turns.push(sample.turns)
    tokens = tokens.push(sample.tokens)
    errors = errors.push(sample.errors)
    wall = wall.push(sample.wall_ms)
    retries += sample.retries
    provider_errors += sample.provider_errors
    if sample.result == "pass" and sample.classification == "pass" { passed += 1 }
  }
  return {
    eval_id: eval_id,
    run_id: run_id,
    trials: samples.len(),
    passed: passed,
    median_turns: median_int(turns |> sort-by .),
    p90_turns: percentile_int(turns |> sort-by ., 90),
    median_tokens: median_metric(tokens),
    p90_tokens: percentile_metric(tokens, 90),
    median_tool_errors: median_int(errors |> sort-by .),
    median_wall_ms: median_int(wall |> sort-by .),
    provider_retries: retries,
    provider_errors: provider_errors,
  }
}

proc trend_rows(samples: List[Sample], selected: Str) [error] -> Result[List[Any]] {
  let ordered = ordered_samples(samples)
  var rows: List[Any] = []
  var index = 0
  while index < ordered.len() {
    let current = ordered[index]
    if selected != "" and current.eval_id != selected {
      index += 1
      continue
    }
    var batch: List[Sample] = []
    let eval_id = current.eval_id
    let run_id = current.run_id
    while index < ordered.len() {
      let sample = ordered[index]
      if sample.eval_id != eval_id or sample.run_id != run_id { break }
      batch = batch.push(sample)
      index += 1
    }
    rows = rows.push(row(eval_id, run_id, batch))
  }
  return Ok(rows)
}

pure row_text(value: Any) -> Str {
  match value {
    f is Float => return f.format(precision: 0)
    _ => return text(value, "0")
  }
}

proc main(...argv: List[Str]) [fs, env, error, io] {
  var factory_dir = env.path("FACTORY_DIR", fs.cwd()?)?
  var selected = ""
  var format = "table"
  var index = 0
  while index < argv.len() {
    if argv[index] == "--factory-dir" and index + 1 < argv.len() {
      factory_dir = Path(argv[index + 1])
      index += 2
    } else if argv[index] == "--eval" and index + 1 < argv.len() {
      selected = argv[index + 1]
      index += 2
    } else if argv[index] == "--format" and index + 1 < argv.len() {
      format = argv[index + 1]
      index += 2
    } else {
      eprint "usage: eval-trends.xsh [--factory-dir PATH] [--eval ID] [--format table|json]"
      abort(2)
    }
  }
  if format != "table" and format != "json" {
    eprint "eval-trends format must be table or json"
    abort(2)
  }
  let rows = trend_rows(read_samples(factory_dir)?, selected)?
  if format == "json" {
    print json.encode(rows, pretty: true)?
    return
  }
  print "EVAL RUN TRIALS PASS MED_TURNS P90_TURNS MED_TOKENS P90_TOKENS MED_ERRORS MED_WALL_MS RETRIES PROVIDER_ERRORS"
  for value in rows {
    let eval_id = text(json.get(value, ["eval_id"], "unknown"))
    let run_id = text(json.get(value, ["run_id"], "unknown"))
    let trials = text(json.get(value, ["trials"], 0))
    let passed = text(json.get(value, ["passed"], 0))
    let median_turns = text(json.get(value, ["median_turns"], 0))
    let p90_turns = text(json.get(value, ["p90_turns"], 0))
    let median_tokens = row_text(json.get(value, ["median_tokens"], 0.0))
    let p90_tokens = row_text(json.get(value, ["p90_tokens"], 0.0))
    let median_errors = text(json.get(value, ["median_tool_errors"], 0))
    let median_wall = text(json.get(value, ["median_wall_ms"], 0))
    let retries = text(json.get(value, ["provider_retries"], 0))
    let provider_errors = text(json.get(value, ["provider_errors"], 0))
    print f"${eval_id} ${run_id} ${trials} ${passed} ${median_turns} ${p90_turns} ${median_tokens} ${p90_tokens} ${median_errors} ${median_wall} ${retries} ${provider_errors}"
  }
}
