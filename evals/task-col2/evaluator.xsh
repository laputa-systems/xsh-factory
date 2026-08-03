##! Package-owned evaluator for task-col2.

use factory_control as control

type Case = {name: Str, data: Str, missing: Bool}

type CaseResult = {
  name: Str,
  exact: Bool,
  candidate_exit: Int,
  oracle_exit: Int,
  candidate_wall_ns: Int,
  oracle_wall_ns: Int,
}

proc copy_results() [fs, error] -> Result[Unit] {
  for name in ["col2.xsh", "review.md"] {
    let source = fp"/work/${name}"
    if fs.exists(source)? {
      fs.copy(source, fp"/export/${name}", overwrite: true)?
    }
  }
  return Ok()
}

proc review_ok() [fs, error] -> Result[Bool] {
  let review = p"/work/review.md"
  if ! fs.exists(review)? or fs.metadata(review)?.size == 0 {
    return false
  }
  let text = review.read_text()?
  return text.contains("## XSH language proposals") and
    text.contains("## xsht friction") and ! text.contains("{{")
}

proc run_case(index: Int, case: Case) [fs, process, time, error] -> Result[CaseResult] {
  let input = fp"/tmp/task-col2-${index}.txt"
  let candidate_output = fp"/session/task-col2-candidate-${index}.stdout"
  let oracle_output = fp"/session/task-col2-oracle-${index}.stdout"
  fs.remove(input, missing_ok: true)?
  fs.remove(candidate_output, missing_ok: true)?
  fs.remove(oracle_output, missing_ok: true)?
  if ! case.missing {
    fs.write(input, case.data)?
  }
  let candidate = time.measure(process.command_argv(
    "xsh", ["xsh", "/work/col2.xsh", input.display()],
    stdout: candidate_output, stderr: fp"/session/task-col2-candidate-${index}.stderr",
  ))?
  let oracle = time.measure(process.command_argv(
    "awk", ["awk", "{print $2}", input.display()],
    stdout: oracle_output, stderr: fp"/session/task-col2-oracle-${index}.stderr",
  ))?
  let candidate_text = if fs.exists(candidate_output)? { candidate_output.read_text()? } else { "" }
  let oracle_text = if fs.exists(oracle_output)? { oracle_output.read_text()? } else { "" }
  let exact = if case.missing {
    ! candidate.status.ok and ! oracle.status.ok and candidate_text == ""
  } else {
    candidate.status.ok and oracle.status.ok and candidate_text == oracle_text
  }
  return {
    name: case.name,
    exact: exact,
    candidate_exit: candidate.status.exit_code() ?? -1,
    oracle_exit: oracle.status.exit_code() ?? -1,
    candidate_wall_ns: candidate.wall_ns,
    oracle_wall_ns: oracle.wall_ns,
  }
}

proc main() [fs, process, env, time, error, io] {
  defer copy_results()?
  let artifact = p"/work/col2.xsh"
  let artifact_present = fs.exists(artifact)?
  var all_exact = artifact_present
  var cases: List[CaseResult] = []
  if artifact_present {
    let inputs: List[Case] = [
      {name: "public", data: "alpha 1\nbeta 22\n", missing: false},
      {name: "hidden_single", data: "alpha\nbeta\n", missing: false},
      {name: "hidden_blank", data: "alpha 1\n\n beta 2\n", missing: false},
      {name: "hidden_leading", data: "  alpha 1\n\tbeta 22\n", missing: false},
      {name: "hidden_multi_ws", data: "alpha   1\nbeta\t22\n", missing: false},
      {name: "hidden_trailing", data: "alpha 1   \nbeta 22\t\n", missing: false},
      {name: "hidden_unicode", data: "héllo wörld 42\n", missing: false},
      {name: "hidden_no_newline", data: "alpha 1\nbeta 22", missing: false},
      {name: "hidden_empty", data: "", missing: false},
      {name: "hidden_missing", data: "", missing: true},
    ]
    var index = 0
    for case in inputs {
      index += 1
      let result = run_case(index, case)?
      cases = cases.push(result)
      if ! result.exact { all_exact = false }
    }
  }
  let source = if artifact_present { artifact.read_text()? } else { "" }
  let restriction_ok = artifact_present and source.contains("read_text") and
    ! control.source_has_forbidden_subprocess(source)
  let protocol_ok = review_ok()?
  let passed = all_exact and restriction_ok and protocol_ok
  json.write(p"/session/run.json", {
    image_id: env.get_or("FACTORY_IMAGE_ID", "unknown")?,
    platform: env.get_or("FACTORY_PLATFORM", "unknown")?,
    eval_id: env.get_or("FACTORY_EVAL_ID", "task-col2")?,
    trial_id: env.get_or("FACTORY_TRIAL_ID", "1")?,
    result: if passed { "pass" } else { "fail" },
    classification: if ! artifact_present { "worker_missing_artifact" } else if ! protocol_ok { "protocol_failed" } else if ! restriction_ok { "restriction_failed" } else if ! all_exact { "candidate_failed" } else { "pass" },
    protocol: {artifact_present: artifact_present, review_ok: protocol_ok},
    correctness: {cases: cases, all_exact: all_exact, passed: all_exact},
    restrictions: {passed: restriction_ok},
    timings: {passed: true},
  }, pretty: true)?
  if ! passed { abort(1) }
}
