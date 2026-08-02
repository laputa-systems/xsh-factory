##! Normalize one factory run into a deterministic audit artifact.

use factory_control as control

type ManifestEvidence = {
  valid: Bool,
  eval_id: Str,
  trial_id: Str,
  result: Str,
  classification: Str,
  protocol: Str,
  correctness: Str,
  restrictions: Str,
  timing: Str,
  timing_gate_failed: Bool,
  handbook: Str,
  candidate: Str,
  oracle: Str,
}

pure json_text(value: Any, fallback: Str = "unknown") -> Str {
  match value {
    s is Str => s,
    i is Int => f"${i}",
    f is Float => f.format(precision: 6),
    b is Bool => if b { "true" } else { "false" },
    _ => fallback,
  }
}

pure json_number(value: Any) -> Float {
  match value {
    i is Int => i.float(),
    f is Float => f,
    _ => 0.0,
  }
}

pure json_is_number(value: Any) -> Bool {
  match value {
    _ is Int => true,
    _ is Float => true,
    _ => false,
  }
}

pure json_bool_text(value: Any) -> Str {
  match value {
    b is Bool => return if b { "true" } else { "false" }
    _ => return "unknown"
  }
}

pure report_value(text: Str, prefix: Str, fallback: Str = "unknown") -> Str {
  for line in text.lines() {
    let trimmed = line.trim()
    if trimmed.starts_with(prefix) {
      return trimmed.byte_slice(prefix.byte_len(), trimmed.byte_len() - prefix.byte_len()).trim().replace("`", "")
    }
  }
  return fallback
}

pure relative_path(root: Str, value: Path) -> Str {
  let displayed = value.display()
  let prefix = root + "/"
  if displayed.starts_with(prefix) {
    return displayed.byte_slice(prefix.byte_len(), displayed.byte_len() - prefix.byte_len())
  }
  let worker_marker = displayed.find("workers/")
  if worker_marker >= 0 {
    return displayed.byte_slice(worker_marker, displayed.byte_len() - worker_marker)
  }
  return displayed
}

pure session_identity(run_name: Str, session: Path, role: Str, worker_id: Str) -> Str {
  if role != "unknown" and worker_id != "unknown" {
    return f"${role}/${worker_id}"
  }
  let relative = relative_path(run_name, session)
  let parts = relative.split("/")
  if parts.len() >= 3 {
    return f"${parts[1]}/${parts[2]}"
  }
  return "unknown"
}

pure ratio(candidate: Any, oracle: Any) -> Float {
  let candidate_value = json_number(candidate)
  let oracle_value = json_number(oracle)
  if oracle_value <= 0.0 { return -1.0 }
  return candidate_value / oracle_value
}

pure timing_summary(timing: Any) -> Str {
  let raw_gate = json.get(timing, ["passed"], null)
  let raw_ratio = json.get(timing, ["ratio"], null)
  if json_is_number(raw_ratio) {
    return f"ratio=${json_number(raw_ratio).format(precision: 3)}; gate=${json_bool_text(raw_gate)}"
  }
  if json_bool_text(raw_gate) != "unknown" {
    return f"gate=${json_bool_text(raw_gate)}"
  }

  let ratios: List[Float] = [
    ratio(
      json.get(timing, ["public_candidate_wall_ns"], null),
      json.get(timing, ["public_oracle_wall_ns"], null),
    ),
    ratio(
      json.get(timing, ["hidden_candidate_wall_ns"], null),
      json.get(timing, ["hidden_oracle_wall_ns"], null),
    ),
    ratio(
      json.get(timing, ["empty_candidate_wall_ns"], null),
      json.get(timing, ["empty_oracle_wall_ns"], null),
    ),
  ]
  var low = 0.0
  var high = 0.0
  var seen = false
  for value in ratios {
    if value >= 0.0 {
      if ! seen or value < low { low = value }
      if ! seen or value > high { high = value }
      seen = true
    }
  }
  if ! seen { return "not-reported; gate=not-requested" }
  return f"diagnostic-ratio=${low.format(precision: 3)}..${high.format(precision: 3)}; gate=not-requested"
}

proc read_manifest(manifest_path: Path) [fs, error] -> Result[ManifestEvidence] {
  let invalid: ManifestEvidence = {
    valid: false,
    eval_id: "unknown",
    trial_id: "unknown",
    result: "invalid",
    classification: "invalid-json",
    protocol: "unknown",
    correctness: "unknown",
    restrictions: "unknown",
    timing: "not-reported",
    timing_gate_failed: false,
    handbook: "unknown",
    candidate: "unknown",
    oracle: "unknown",
  }
  match json.decode(manifest_path.read_text()?) {
    Err(_) => return Ok(invalid),
    Ok(raw) => {
      let protocol = json.get(raw, ["protocol"], null)
      let correctness = json.get(raw, ["correctness"], null)
      let restrictions = json.get(raw, ["restrictions"], null)
      let timing = json.get(raw, ["timings"], null)
      let protocol_value = if json_bool_text(json.get(protocol, ["artifact_present"], null)) == "true" and
        json_bool_text(json.get(protocol, ["review_ok"], null)) == "true" {
        "pass"
      } else if json_bool_text(json.get(protocol, ["artifact_present"], null)) == "false" or
        json_bool_text(json.get(protocol, ["review_ok"], null)) == "false" {
        "fail"
      } else {
        "unknown"
      }
      let correctness_value = json.get(
        correctness,
        ["passed"],
        json.get(correctness, ["all_exact"], null),
      )
      let restrictions_value = json.get(restrictions, ["passed"], null)
      let timing_gate = json_bool_text(json.get(timing, ["passed"], null))
      return Ok({
        valid: true,
        eval_id: json_text(json.get(raw, ["eval_id"], null)),
        trial_id: json_text(json.get(raw, ["trial_id"], null)),
        result: json_text(json.get(raw, ["result"], null)),
        classification: json_text(json.get(raw, ["classification"], null)),
        protocol: protocol_value,
        correctness: json_bool_text(correctness_value),
        restrictions: json_bool_text(restrictions_value),
        timing: timing_summary(timing),
        timing_gate_failed: timing_gate == "false",
        handbook: json_text(json.get(raw, ["inputs", "handbook_sha256"], null)),
        candidate: json_text(json.get(raw, ["outputs", "candidate_sha256"], null)),
        oracle: json_text(json.get(raw, ["outputs", "oracle_sha256"], null)),
      })
    }
  }
}

pure report_document_ok(text: Str, headings: List[Str]) -> Bool {
  if text.contains("{{") or text.contains("}}") { return false }
  return control.report_contract_ok(text, headings, "")
}

proc audit_run(run_dir: Path, requested_mode: Str, factory_dir: Path) [fs, error] -> Result[Int] {
  if requested_mode != "eval" and requested_mode != "ticket-implementation" and
    requested_mode != "eval-design" {
    eprint f"unsupported audit mode: ${requested_mode}"
    return Ok(2)
  }

  let run_name = run_dir.display()
  let request_path = fp"${run_dir}/CYCLE-REQUEST.md"
  let request_exists = fs.exists(request_path)?
  let request_text = if request_exists { fs.read_text(request_path)? } else { "" }
  let requested_eval = if request_exists { control.request_eval(request_text) } else { "" }
  let requested_tickets = if request_exists { control.request_tickets(request_text) } else { [] }
  var sessions: List[Path] = []
  var manifests: List[Path] = []
  var engineer_reports: List[Path] = []
  var manager_reports: List[Path] = []
  var designer_reports: List[Path] = []
  for entry in fs.files(run_dir, gitignore: false, hidden: true)? {
    if entry.name == "session.jsonl" { sessions = sessions.push(entry.path) }
    if entry.name == "run.json" { manifests = manifests.push(entry.path) }
    if entry.name == "ENGINEER-REPORT.md" { engineer_reports = engineer_reports.push(entry.path) }
    if entry.name == "MANAGER-REPORT.md" { manager_reports = manager_reports.push(entry.path) }
    if entry.name == "DESIGNER-REPORT.md" { designer_reports = designer_reports.push(entry.path) }
  }
  sessions = sessions |> sort-by .display()
  manifests = manifests |> sort-by .display()
  engineer_reports = engineer_reports |> sort-by .display()
  manager_reports = manager_reports |> sort-by .display()
  designer_reports = designer_reports |> sort-by .display()

  let eval_id = if requested_eval != "" {
    requested_eval
  } else if manifests.len() > 0 {
    read_manifest(manifests[0])?.eval_id
  } else {
    "not-requested"
  }
  let expected_trials = if requested_mode == "eval" and request_exists {
    control.request_trial_count(request_text)?
  } else if requested_mode == "eval" {
    manifests.len()
  } else {
    0
  }

  let row_template = fp"${factory_dir}/templates/AUDIT-ROW.md"
  let row_template_text = row_template.read_text()?
  var rows = ""
  var findings: List[Str] = []
  var worker_ok = sessions.len() > 0
  var worker_report_count = 0
  for entry in fs.files(run_dir, gitignore: false, hidden: true)? {
    if entry.name == "WORKER-REPORT.md" { worker_report_count += 1 }
  }
  for session in sessions {
    let worker_dir = session.parent()
    let report = fp"${worker_dir}/WORKER-REPORT.md"
    let report_present = fs.exists(report)?
    let report_text = if report_present { report.read_text()? } else { "" }
    let report_marker = fp"${worker_dir}/REPORT-MISSING"
    let report_contract = report_present and ! fs.exists(report_marker)? and
      control.worker_report_contract_ok(report_text)
    let role = if report_present { report_value(report_text, "- Role:", "unknown") } else { "unknown" }
    let worker_id = if report_present { report_value(report_text, "- Worker:", "unknown") } else { "unknown" }
    let identity = session_identity(run_name, session, role, worker_id)
    let outcome = if report_present { report_value(report_text, "- Budget status:", "unknown") } else { "missing-report" }
    let contract = if ! report_present { "missing-report" } else if report_contract { "pass" } else { "fail" }
    let metrics = if report_present {
      f"turns=${report_value(report_text, "- Assistant turns:")}; tools=${report_value(report_text, "- Tool calls:")}; thinking=${report_value(report_text, "- Thinking blocks:")}; reasoning=${report_value(report_text, "- Reasoning/thinking tokens (provider subset of output):")}; provider-total=${report_value(report_text, "- Provider-reported total tokens:")}; cost=${report_value(report_text, "- Provider cost:")}; tool-errors=${report_value(report_text, "- Tool errors:")}; span=${report_value(report_text, "- Session span:")}; session-sha=${hash.sha256(session)?.hex()}"
    } else {
      f"session-sha=${hash.sha256(session)?.hex()}"
    }
    let values: List[control.TemplateValue] = [
      {key: "KIND", value: "worker"},
      {key: "IDENTIFIER", value: identity},
      {key: "OUTCOME", value: outcome},
      {key: "CLASSIFICATION", value: "pi-session"},
      {key: "CONTRACT", value: contract},
      {key: "SESSION", value: relative_path(run_name, session)},
      {key: "REPORT", value: if report_present { relative_path(run_name, report) } else { "missing" }},
      {key: "MANIFEST", value: "not-applicable"},
      {key: "METRICS", value: metrics},
    ]
    rows = rows + control.fill_template(row_template_text, values)
    if ! report_contract {
      worker_ok = false
      findings = findings.push(f"worker ${identity} is missing a valid derived report")
    }
  }
  if worker_report_count != sessions.len() {
    worker_ok = false
    findings = findings.push(f"worker report count ${worker_report_count} does not match session count ${sessions.len()}")
  }

  var evaluator_ok = true
  var observed_trials = 0
  for manifest in manifests {
    let evidence = read_manifest(manifest)?
    let executor_report = fp"${manifest.parent()}/EXECUTOR-REPORT.md"
    let executor_present = fs.exists(executor_report)?
    let executor_ok = executor_present and control.executor_report_contract_ok(fs.read_text(executor_report)?)
    let session = fp"${manifest.parent()}/session.jsonl"
    let trial_id = evidence.trial_id
    let identifier = f"${evidence.eval_id}/${trial_id}"
    let trial_ok = evidence.valid and evidence.result == "pass" and evidence.protocol == "pass" and
      evidence.correctness == "true" and evidence.restrictions == "true" and
      ! evidence.timing_gate_failed and executor_ok and fs.exists(session)?
    observed_trials += 1
    if requested_mode == "eval" and ! trial_ok {
      evaluator_ok = false
      findings = findings.push(f"trial ${identifier} failed normalized evidence checks: result=${evidence.result}; classification=${evidence.classification}; protocol=${evidence.protocol}; correctness=${evidence.correctness}; restrictions=${evidence.restrictions}; timing=${evidence.timing}")
    }
    let values: List[control.TemplateValue] = [
      {key: "KIND", value: "trial"},
      {key: "IDENTIFIER", value: identifier},
      {key: "OUTCOME", value: evidence.result},
      {key: "CLASSIFICATION", value: evidence.classification},
      {key: "CONTRACT", value: f"protocol=${evidence.protocol}; correctness=${evidence.correctness}; restrictions=${evidence.restrictions}; executor=${if executor_ok { "pass" } else { "fail" }}"},
      {key: "SESSION", value: if fs.exists(session)? { relative_path(run_name, session) } else { "missing" }},
      {key: "REPORT", value: if executor_present { relative_path(run_name, executor_report) } else { "missing" }},
      {key: "MANIFEST", value: relative_path(run_name, manifest)},
      {key: "METRICS", value: f"handbook=${evidence.handbook}; candidate=${evidence.candidate}; oracle=${evidence.oracle}; timing=${evidence.timing}"},
    ]
    rows = rows + control.fill_template(row_template_text, values)
  }
  if requested_mode == "eval" {
    if observed_trials != expected_trials {
      evaluator_ok = false
      findings = findings.push(f"expected ${expected_trials} evaluator manifest(s), observed ${observed_trials}")
    }
    if observed_trials == 0 { evaluator_ok = false }
  }

  var ticket_ok = true
  var observed_tickets = 0
  for report in engineer_reports {
    let report_text = report.read_text()?
    let relative = relative_path(run_name, report)
    let parts = relative.split("/")
    let ticket_id = if parts.len() >= 4 { parts[2] } else { "unknown" }
    let session = fp"${report.parent()}/session.jsonl"
    let contract_ok = control.engineer_report_contract_ok(report_text) and fs.exists(session)?
    let outcome = control.report_field(report_text, "Result")
    let branch = control.report_field(report_text, "Branch")
    let commit = control.report_field(report_text, "Commit")
    observed_tickets += 1
    if requested_mode == "ticket-implementation" and (! contract_ok or outcome != "ready-for-review") {
      ticket_ok = false
      findings = findings.push(f"ticket ${ticket_id} is not ready for review: result=${outcome}; contract=${if contract_ok { "pass" } else { "fail" }}")
    }
    let values: List[control.TemplateValue] = [
      {key: "KIND", value: "ticket"},
      {key: "IDENTIFIER", value: ticket_id},
      {key: "OUTCOME", value: outcome},
      {key: "CLASSIFICATION", value: "engineer"},
      {key: "CONTRACT", value: if contract_ok { "pass" } else { "fail" }},
      {key: "SESSION", value: if fs.exists(session)? { relative_path(run_name, session) } else { "missing" }},
      {key: "REPORT", value: relative},
      {key: "MANIFEST", value: "not-applicable"},
      {key: "METRICS", value: f"branch=${branch}; commit=${commit}"},
    ]
    rows = rows + control.fill_template(row_template_text, values)
  }
  if requested_mode == "ticket-implementation" {
    if observed_tickets != requested_tickets.len() {
      ticket_ok = false
      findings = findings.push(f"expected ${requested_tickets.len()} ticket report(s), observed ${observed_tickets}")
    }
    if observed_tickets == 0 { ticket_ok = false }
  }

  let provenance = fp"${run_dir}/PROVENANCE.md"
  let provenance_ok = fs.exists(provenance)? and report_document_ok(
    provenance.read_text()?, ["Run", "XSH input", "Candidate input", "Execution environment", "Lineage and admission"]
  )
  if ! provenance_ok { findings = findings.push("provenance is missing or incomplete") }

  let cost = fp"${run_dir}/COST.md"
  let cost_ok = fs.exists(cost)? and report_document_ok(cost.read_text()?, ["Workers", "Role totals", "Run total"]) and
    cost.read_text()?.contains("- Budget failures or unknown costs: 0")
  if ! cost_ok { findings = findings.push("cost report is missing, incomplete, or has unknown/breached worker cost") }

  let lineage = fp"${run_dir}/LINEAGE.md"
  let lineage_ok = if requested_mode == "eval" {
    fs.exists(lineage)? and report_document_ok(lineage.read_text()?, ["Factory handbook", "Snapshots", "Controller checks"])
  } else {
    true
  }
  if ! lineage_ok { findings = findings.push("handbook lineage is missing or incomplete") }

  let director_report = fp"${run_dir}/DIRECTOR-REPORT.md"
  let director_ok = if requested_mode == "eval-design" {
    true
  } else {
    fs.exists(director_report)? and control.director_report_contract_ok(director_report.read_text()?) and
      control.report_result_is(director_report.read_text()?, "pass")
  }
  let manager_ok = if requested_mode == "eval" {
    manager_reports.len() > 0 and control.manager_report_contract_ok(manager_reports[0].read_text()?) and
      control.report_result_is(manager_reports[0].read_text()?, "pass")
  } else {
    true
  }
  let designer_required = requested_mode == "eval-design" or
    (requested_mode == "eval" and request_exists and control.request_new_eval_count(request_text)? > 0)
  let designer_ok = if designer_required {
    designer_reports.len() > 0 and control.designer_report_contract_ok(designer_reports[0].read_text()?) and
      control.report_result_is(designer_reports[0].read_text()?, "ready-for-review")
  } else {
    true
  }
  let controller_ok = (requested_mode == "eval-design" or director_ok) and manager_ok and designer_ok
  if ! director_ok { findings = findings.push("director report is missing, invalid, or reports failure") }
  if ! manager_ok { findings = findings.push("eval-manager report is missing, invalid, or reports failure") }
  if ! designer_ok { findings = findings.push("required eval-designer report is missing or invalid") }

  let worker_state = if worker_ok { "pass" } else { "fail" }
  let evaluator_state = if requested_mode != "eval" { "not-requested" } else if evaluator_ok { "pass" } else { "fail" }
  let ticket_state = if requested_mode != "ticket-implementation" { "not-requested" } else if ticket_ok { "pass" } else { "fail" }
  let controller_state = if controller_ok { "pass" } else { "fail" }
  let integrity_ok = provenance_ok and cost_ok and lineage_ok and controller_ok and worker_ok
  let result = if integrity_ok and evaluator_ok and ticket_ok { "pass" } else { "fail" }
  let findings_text = if findings.len() == 0 { "none" } else { findings.join("\n") }
  let provenance_text = if provenance_ok { "pass" } else { "fail" }
  let cost_text = if cost_ok { "pass" } else { "fail" }
  let lineage_text = if requested_mode != "eval" { "not-requested" } else if lineage_ok { "pass" } else { "fail" }
  let template = fp"${factory_dir}/templates/AUDIT.md"
  let values: List[control.TemplateValue] = [
    {key: "RESULT", value: result},
    {key: "RUN_ID", value: run_name},
    {key: "MODE", value: requested_mode},
    {key: "XSH_COMMIT", value: report_value(if fs.exists(provenance)? { provenance.read_text()? } else { "" }, "- Commit:")},
    {key: "IMAGE", value: report_value(if fs.exists(provenance)? { provenance.read_text()? } else { "" }, "- Image:")},
    {key: "EVAL_ID", value: eval_id},
    {key: "EXPECTED_TRIALS", value: expected_trials.float().format(precision: 0)},
    {key: "SESSION_COUNT", value: sessions.len().float().format(precision: 0)},
    {key: "MANIFEST_COUNT", value: manifests.len().float().format(precision: 0)},
    {key: "TICKET_COUNT", value: engineer_reports.len().float().format(precision: 0)},
    {key: "PROVENANCE_STATE", value: provenance_text},
    {key: "COST_STATE", value: cost_text},
    {key: "LINEAGE_STATE", value: lineage_text},
    {key: "CONTROLLER_STATE", value: controller_state},
    {key: "WORKER_STATE", value: worker_state},
    {key: "EVALUATOR_STATE", value: evaluator_state},
    {key: "TICKET_STATE", value: ticket_state},
    {key: "ROWS", value: rows},
    {key: "FINDINGS", value: findings_text},
  ]
  fs.write(fp"${run_dir}/AUDIT.md", control.fill_template(template.read_text()?, values))?
  print f"audit: ${run_dir}/AUDIT.md (${result})"
  return Ok(0)
}

proc main(...argv: List[Str]) [fs, env, error, io] {
  if argv.len() < 1 {
    eprint "usage: audit-run.xsh RUN_DIR [MODE]"
    abort(2)
  }
  let factory_dir = env.path("FACTORY_DIR", fs.cwd()?)?
  let mode = if argv.len() >= 2 { argv[1] } else { "eval" }
  abort(audit_run(Path(argv[0]), mode, factory_dir)?)
}
