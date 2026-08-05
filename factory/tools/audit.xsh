##! Compile factory evidence into one structured phase or run report.

use factory.control as control
use factory.schema as schema

pure text(value: Any, fallback: Str = "unknown") -> Str {
  let result = schema.value_text(value)
  return if result == "" { fallback } else { result }
}

pure number(value: Any) -> Float {
  match value {
    i is Int => i.float(),
    f is Float => f,
    _ => 0.0,
  }
}

pure integer(value: Any) -> Int {
  match value {
    i is Int => i,
    _ => 0,
  }
}

pure boolean(value: Any) -> Bool {
  match value {
    b is Bool => b,
    _ => false,
  }
}

pure relative_path(root: Str, value: Path) -> Str {
  return control.factory_relative_path(root, value)
}

pure worker_identity(path_value: Path) -> Any {
  let marker = path_value.display().find("workers/")
  if marker >= 0 {
    let suffix = path_value.display().byte_slice(marker, path_value.display().byte_len() - marker)
    let parts = suffix.split("/")
    if parts.len() >= 3 {
      return {role: parts[1], worker_id: parts[2]}
    }
  }
  return {role: "unknown", worker_id: "unknown"}
}

proc worker_report_paths(run_dir: Path) [fs, error] -> Result[List[Path]] {
  var reports: List[Path] = []
  for entry in fs.files(run_dir, gitignore: false, hidden: true)? {
    if entry.name == "report.json" and entry.path.display().contains("/workers/") {
      reports = reports.push(entry.path)
    }
  }
  return reports |> sort-by .display()
}

proc session_paths(run_dir: Path) [fs, error] -> Result[List[Path]] {
  var sessions: List[Path] = []
  for entry in fs.files(run_dir, gitignore: false, hidden: true)? {
    if entry.name == "session.jsonl" or entry.name == "session.jsonl.bz2" {
      sessions = sessions.push(entry.path)
    }
  }
  return sessions |> sort-by .display()
}

proc manifest_paths(run_dir: Path) [fs, error] -> Result[List[Path]] {
  var manifests: List[Path] = []
  for entry in fs.files(run_dir, gitignore: false, hidden: true)? {
    if entry.name == "run.json" and entry.path.display().contains("/workers/") {
      manifests = manifests.push(entry.path)
    }
  }
  return manifests |> sort-by .display()
}

proc narrative_paths(run_dir: Path) [fs, error] -> Result[List[Path]] {
  var reports: List[Path] = []
  for entry in fs.files(run_dir, gitignore: false, hidden: true)? {
    if entry.name == "REPORT.md" and entry.path.display().contains("/workers/") {
      reports = reports.push(entry.path)
    }
  }
  return reports |> sort-by .display()
}

proc open_ticket_snapshot(factory_dir: Path) [fs, error] -> Result[List[Any]] {
  var tickets: List[Any] = []
  let ticket_dir = fp"${factory_dir}/tickets"
  if ! fs.exists(ticket_dir)? { return tickets }
  for entry in fs.files(ticket_dir, gitignore: false, hidden: true) |> sort-by .path.display() {
    if ! entry.name.ends_with(".md") { continue }
    let ticket = entry.path.read_text()?
    let status = control.ticket_status(ticket)
    if status == "Closed." or status == "Merged." { continue }
    tickets = tickets.push({
      id: entry.name.replace(".md", ""),
      status: status,
      eval_id: control.ticket_eval(ticket),
      path: entry.path.display(),
    })
  }
  return tickets
}

proc manifest_evidence(manifest_path: Path) [fs, error] -> Result[Any] {
  if ! fs.exists(manifest_path)? { return {valid: false, result: "missing"} }
  let raw = json.read(manifest_path)?
  let protocol = json.get(raw, ["protocol"], null)
  let correctness = json.get(raw, ["correctness"], null)
  let restrictions = json.get(raw, ["restrictions"], null)
  let timings = json.get(raw, ["timings"], null)
  let protocol_ok = boolean(json.get(protocol, ["artifact_present"], false)) and
    boolean(json.get(protocol, ["review_ok"], false))
  let correctness_value = json.get(correctness, ["passed"], json.get(correctness, ["all_exact"], false))
  let correctness_ok = boolean(correctness_value)
  let restrictions_ok = boolean(json.get(restrictions, ["passed"], false))
  let timing_present = json.get(timings, ["passed"], null)
  let timing_ok = match timing_present {
    b is Bool => b,
    _ => true,
  }
  let result = text(json.get(raw, ["result"], "invalid"), "invalid")
  return {
    valid: true,
    eval_id: text(json.get(raw, ["eval_id"], "unknown")),
    trial_id: text(json.get(raw, ["trial_id"], "unknown")),
    result: result,
    classification: text(json.get(raw, ["classification"], "unknown")),
    protocol: if protocol_ok { "pass" } else { "fail" },
    correctness: if correctness_ok { "pass" } else { "fail" },
    restrictions: if restrictions_ok { "pass" } else { "fail" },
    timing: if timing_ok { "pass" } else { "fail" },
    handbook_sha256: text(json.get(raw, ["inputs", "handbook_sha256"], "unknown")),
    candidate_sha256: text(json.get(raw, ["outputs", "candidate_sha256"], "unknown")),
    oracle_sha256: text(json.get(raw, ["outputs", "oracle_sha256"], "unknown")),
    passed: result == "pass" and protocol_ok and correctness_ok and restrictions_ok and timing_ok,
  }
}

proc worker_data(run_dir: Path, reports: List[Path]) [fs, error] -> Result[Any] {
  var workers: List[Any] = []
  var tool_errors: List[Any] = []
  var findings: List[Any] = []
  var total_cost = 0.0
  var total_tokens = 0.0
  var total_turns = 0
  var total_tool_errors = 0
  var budget_failures = 0
  var unknown_costs = 0
  for report_path in reports {
    let raw = json.read(report_path)?
    let identity = worker_identity(report_path)
    let usage = json.get(raw, ["usage"], null)
    let cost_value = json.get(usage, ["cost_usd"], null)
    let cost_seen = match cost_value {
      f is Float => true,
      i is Int => true,
      _ => false,
    }
    let cost = number(cost_value)
    let budget = number(json.get(usage, ["budget_usd"], null))
    let errors = json.get(raw, ["tool_errors"], [])
    let error_count = match errors {
      values is List[Any] => values.len(),
      _ => 0,
    }
    let worker_result = text(json.get(raw, ["result"], "unknown"))
    let report_ok = schema.valid(raw, "worker")
    let budget_failed = ! cost_seen or budget <= 0.0 or cost > budget
    if ! cost_seen { unknown_costs += 1 }
    if budget_failed { budget_failures += 1 }
    if ! report_ok { findings = findings.push({kind: "invalid-report", path: relative_path(run_dir.display(), report_path)}) }
    if error_count > 0 {
      total_tool_errors += error_count
      match errors {
        values is List[Any] => {
          for error in values {
            tool_errors = tool_errors.push({
              worker: identity,
              turn: json.get(error, ["turn"], null),
              tool: text(json.get(error, ["tool"], "unknown")),
              summary: text(json.get(error, ["summary"], ""), "(no summary)"),
              report: relative_path(run_dir.display(), report_path),
            })
          }
        }
        _ => {}
      }
    }
    total_cost += cost
    total_tokens += number(json.get(usage, ["total_bucket_tokens"], 0))
    total_turns += integer(json.get(usage, ["assistant_turns"], 0))
    workers = workers.push({
      identity: identity,
      path: relative_path(run_dir.display(), report_path),
      result: worker_result,
      valid: report_ok,
      usage: usage,
      tool_errors: error_count,
    })
  }
  return {
    workers: workers,
    tool_errors: tool_errors,
    findings: findings,
    usage: {
      workers: reports.len(),
      assistant_turns: total_turns,
      total_bucket_tokens: total_tokens,
      cost_usd: total_cost,
      tool_errors: total_tool_errors,
      budget_failures: budget_failures,
      unknown_costs: unknown_costs,
    },
  }
}

proc narrative_state(report_path: Path, role: Str) [fs, error] -> Result[Any] {
  if ! fs.exists(report_path)? {
    return {path: report_path.display(), role: role, present: false, valid: false, result: "missing"}
  }
  let report = report_path.read_text()?
  let valid = if role == "eval-manager" {
    control.manager_report_contract_ok(report)
  } else if role == "director" {
    control.director_report_contract_ok(report)
  } else if role == "eval-designer" {
    control.designer_report_contract_ok(report)
  } else if role == "engineer" {
    control.engineer_report_contract_ok(report)
  } else {
    control.narrative_report_contract_ok(report, [])
  }
  return {
    path: report_path.display(),
    role: role,
    present: true,
    valid: valid,
    result: control.report_field(report, "Result"),
  }
}

proc current_xsh_commit(factory_dir: Path) [env, process, error] -> Result[Str] {
  let configured = env.get_or("FACTORY_XSH_COMMIT", "")?
  if configured != "" and configured != "unknown" {
    return Ok(configured)
  }
  let repo = env.path("FACTORY_XSH_REPO", fp"${factory_dir}/../xsh")?
  return run.text "git" "-C" $repo.display() "rev-parse" "HEAD"
}

proc audit_phase(run_dir: Path, mode: Str, factory_dir: Path) [fs, env, process, error] -> Result[Int] {
  let request_path = fp"${run_dir}/CYCLE-REQUEST.md"
  let request_exists = fs.exists(request_path)?
  let request = if request_exists { request_path.read_text()? } else { "" }
  let requested_eval = if request_exists { control.request_eval(request) } else { "" }
  let expected_trials = if mode == "eval" and request_exists { control.request_trial_count(request)? } else { 0 }
  let reports = worker_report_paths(run_dir)?
  let sessions = session_paths(run_dir)?
  let manifests = manifest_paths(run_dir)?
  let narratives = narrative_paths(run_dir)?
  let workers = worker_data(run_dir, reports)?
  var findings: List[Any] = workers.findings
  var trial_rows: List[Any] = []
  var trials_ok = true
  for manifest in manifests {
    let evidence = manifest_evidence(manifest)?
    trial_rows = trial_rows.push({
      path: relative_path(run_dir.display(), manifest),
      evidence: evidence,
    })
    if mode == "eval" and ! boolean(json.get(evidence, ["passed"], false)) {
      trials_ok = false
    }
  }
  if mode == "eval" and manifests.len() != expected_trials {
    trials_ok = false
    findings = findings.push({kind: "trial-count", expected: expected_trials, observed: manifests.len()})
  }
  if mode == "eval" and manifests.len() == 0 {
    trials_ok = false
    findings = findings.push({kind: "missing-evaluator-manifest"})
  }

  var narrative_rows: List[Any] = []
  for narrative in narratives {
    let identity = worker_identity(narrative)
    let role = text(json.get(identity, ["role"], "unknown"))
    narrative_rows = narrative_rows.push(narrative_state(narrative, role)?)
  }
  let manager_path = fp"${run_dir}/workers/eval-manager/${requested_eval}/REPORT.md"
  let director_path = fp"${run_dir}/workers/director/director/REPORT.md"
  let designer_path = fp"${run_dir}/workers/eval-designer/proposal-1/REPORT.md"
  let manager_state = narrative_state(manager_path, "eval-manager")?
  let director_state = if mode == "eval" {
    {path: director_path.display(), role: "director", present: false, valid: true, result: "not-requested"}
  } else {
    narrative_state(director_path, "director")?
  }
  let designer_required = mode == "eval-design" or (request_exists and control.request_new_eval_count(request)? > 0)
  let designer_state = if designer_required {
    narrative_state(designer_path, "eval-designer")?
  } else {
    {path: designer_path.display(), role: "eval-designer", present: false, valid: true, result: "not-requested"}
  }
  let engineer_states = if mode == "ticket-implementation" {
    narrative_rows
  } else {
    []
  }
  let manager_ok = if mode == "eval" { boolean(json.get(manager_state, ["present"], false)) and boolean(json.get(manager_state, ["valid"], false)) } else { true }
  let director_ok = if mode == "ticket-implementation" { boolean(json.get(director_state, ["present"], false)) and boolean(json.get(director_state, ["valid"], false)) } else { true }
  let designer_ok = ! designer_required or (boolean(json.get(designer_state, ["present"], false)) and boolean(json.get(designer_state, ["valid"], false)))
  let engineer_ok = if mode == "ticket-implementation" { engineer_states.len() > 0 } else { true }
  let required_outputs_path = fp"${run_dir}/required-outputs.json"
  let required_outputs_present = fs.exists(required_outputs_path)?
  let required_outputs = if required_outputs_present { json.read(required_outputs_path)? } else { null }
  let required_outputs_ok = ! required_outputs_present or boolean(json.get(required_outputs, ["required"], false))
  if ! manager_ok { findings = findings.push({kind: "manager-report", state: manager_state}) }
  if ! director_ok { findings = findings.push({kind: "director-report", state: director_state}) }
  if ! designer_ok { findings = findings.push({kind: "designer-report", state: designer_state}) }
  if ! engineer_ok { findings = findings.push({kind: "engineer-report", state: "missing"}) }
  if ! required_outputs_ok { findings = findings.push({kind: "required-outputs", state: "failed"}) }

  let lineage_dir = fp"${run_dir}/lineage"
  let lineage_approved = fp"${lineage_dir}/handbook-approved.md"
  let lineage_candidate = fp"${lineage_dir}/handbook-candidate.md"
  let lineage_ok = if mode == "eval" {
    fs.exists(lineage_approved)? and fs.exists(lineage_candidate)?
  } else {
    true
  }
  if ! lineage_ok { findings = findings.push({kind: "handbook-lineage", state: "missing"}) }
  let open_tickets = open_ticket_snapshot(factory_dir)?
  let xsh_commit = current_xsh_commit(factory_dir)?.trim()
  var session_rows: List[Str] = []
  for session in sessions {
    session_rows = session_rows.push(relative_path(run_dir.display(), session))
  }
  let approved_lineage_path = if fs.exists(lineage_approved)? { relative_path(run_dir.display(), lineage_approved) } else { "missing" }
  let candidate_lineage_path = if fs.exists(lineage_candidate)? { relative_path(run_dir.display(), lineage_candidate) } else { "missing" }
  let product_ok = reports.len() > 0 and engineer_ok and trials_ok
  let evaluator_ok = manager_ok and designer_ok and trials_ok
  let infrastructure_ok = required_outputs_ok and lineage_ok and
    workers.usage.budget_failures == 0 and workers.usage.unknown_costs == 0
  let result = if product_ok and evaluator_ok and infrastructure_ok { "pass" } else { "fail" }
  if reports.len() == 0 { findings = findings.push({kind: "worker-reports", state: "missing"}) }
  let report = {
    schema_version: schema.SCHEMA_VERSION,
    kind: "phase",
    identity: {run_id: run_dir.name(), mode: mode, eval_id: requested_eval},
    state: "completed",
    result: result,
    data: {
      mode: mode,
      xsh_commit: xsh_commit,
      sessions: session_rows,
      workers: workers.workers,
      trials: trial_rows,
      narratives: narrative_rows,
      manager: manager_state,
      director: director_state,
      designer: designer_state,
      engineer: engineer_states,
      open_tickets: open_tickets,
      handbook_lineage: {
        approved: approved_lineage_path,
        candidate: candidate_lineage_path,
      },
      required_outputs: required_outputs,
      cost: workers.usage,
      tool_errors: workers.tool_errors,
      outcomes: schema.outcome(product_ok, evaluator_ok, infrastructure_ok),
    },
    findings: findings,
    artifacts: [
      {kind: "session-directory", path: "workers/"},
      {kind: "raw-events", path: "events.jsonl"},
    ],
  }
  json.write(fp"${run_dir}/report.json", report, pretty: true)?
  print f"report: ${run_dir}/report.json (${result})"
  return Ok(0)
}

proc audit_organization(run_dir: Path, factory_dir: Path) [fs, env, process, error] -> Result[Int] {
  let phases_dir = fp"${run_dir}/phases"
  var phases: List[Any] = []
  var findings: List[Any] = []
  var all_pass = true
  if fs.exists(phases_dir)? {
    for entry in fs.children(phases_dir, stat: false, ordered: true) |> where .kind == "dir" |> sort-by .path.display() {
      let report_path = fp"${entry.path}/report.json"
      let present = fs.exists(report_path)?
      let value = if present { json.read(report_path)? } else { null }
      let valid = present and schema.valid(value, "phase")
      let result = if valid { text(json.get(value, ["result"], "unknown")) } else { "missing" }
      phases = phases.push({id: entry.name, path: relative_path(run_dir.display(), report_path), valid: valid, result: result})
      if ! valid or result != "pass" {
        all_pass = false
        findings = findings.push({kind: "phase", id: entry.name, result: result})
      }
    }
  }
  if phases.len() == 0 { all_pass = false; findings = findings.push({kind: "phases", state: "missing"}) }
  let worker_reports = worker_report_paths(run_dir)?
  let workers = worker_data(run_dir, worker_reports)?
  let product_ok = phases.len() > 0 and all_pass
  let evaluator_ok = all_pass
  let infrastructure_ok = workers.usage.budget_failures == 0 and workers.usage.unknown_costs == 0
  let result = if product_ok and evaluator_ok and infrastructure_ok { "pass" } else { "fail" }
  let xsh_commit = current_xsh_commit(factory_dir)?.trim()
  let report = {
    schema_version: schema.SCHEMA_VERSION,
    kind: "run",
    identity: {run_id: run_dir.name(), mode: "organization"},
    state: "completed",
    result: result,
    data: {
      mode: "organization",
      xsh_commit: xsh_commit,
      phases: phases,
      outcomes: schema.outcome(product_ok, evaluator_ok, infrastructure_ok),
      workers: workers.workers,
      cost: workers.usage,
      tool_errors: workers.tool_errors,
    },
    findings: findings.extend(workers.findings),
    artifacts: [{kind: "phase-reports", path: "phases/"}, {kind: "raw-events", path: "events.jsonl"}],
  }
  json.write(fp"${run_dir}/report.json", report, pretty: true)?
  print f"report: ${run_dir}/report.json (${result})"
  return Ok(0)
}

proc main(...argv: List[Str]) [fs, env, error, io] {
  if argv.len() < 1 {
    eprint "usage: xsh factory/tools/audit.xsh RUN_DIR [MODE]"
    abort(2)
  }
  let factory_dir = env.path("FACTORY_DIR", fs.cwd()?)?
  let requested = Path(argv[0])
  let run_dir = if requested.display().starts_with("/") {
    requested
  } else {
    fp"${fs.cwd()?}/${requested.display()}"
  }
  let mode = if argv.len() >= 2 { argv[1] } else { "eval" }
  if mode == "organization" {
    abort(audit_organization(run_dir, factory_dir)?)
  }
  if mode != "eval" and mode != "ticket-implementation" and mode != "eval-design" {
    eprint f"unsupported audit mode: ${mode}"
    abort(2)
  }
  abort(audit_phase(run_dir, mode, factory_dir)?)
}
