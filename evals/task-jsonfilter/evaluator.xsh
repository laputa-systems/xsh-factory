##! Package-owned evaluator for task-jsonfilter.

type Case = {name: Str, document: Str, missing: Bool, expect_fail: Bool}

type CaseResult = {
  name: Str,
  exact: Bool,
  candidate_exit: Int,
  oracle_exit: Int,
  candidate_wall_ns: Int,
  oracle_wall_ns: Int,
}

proc copy_results() [fs, error] -> Result[Unit] {
  for name in ["jsonfilter.xsh", "review.md"] {
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
  let output = fp"/tmp/task-jsonfilter-candidate-${index}.json"
  let oracle_file = fp"/tmp/task-jsonfilter-oracle-${index}.json"
  let oracle_output = fp"/session/task-jsonfilter-oracle-${index}.stdout"
  fs.remove(output, missing_ok: true)?
  fs.remove(oracle_file, missing_ok: true)?
  fs.remove(oracle_output, missing_ok: true)?
  let candidate = time.measure(process.command_argv(
    "xsh", ["xsh", "/work/jsonfilter.xsh", output.display()],
    env: if case.missing { {} } else { {CFG_DOC: case.document} },
    stdout: fp"/session/task-jsonfilter-candidate-${index}.stdout",
    stderr: fp"/session/task-jsonfilter-candidate-${index}.stderr",
  ))?
  let oracle_script = p"/tmp/task-jsonfilter-oracle.sh"
  let oracle = time.measure(process.command_argv(
    "sh", ["sh", oracle_script.display(), oracle_file.display()],
    env: if case.missing { {} } else { {CFG_DOC: case.document} },
    stdout: oracle_output, stderr: fp"/session/task-jsonfilter-oracle-${index}.stderr",
  ))?
  let candidate_text = if fs.exists(output)? { output.read_text()? } else { "" }
  let oracle_text = if fs.exists(oracle_file)? { oracle_file.read_text()? } else { "" }
  let exact = if case.expect_fail {
    ! candidate.status.ok and ! oracle.status.ok and ! fs.exists(output)? and ! fs.exists(oracle_file)?
  } else {
    candidate.status.ok and oracle.status.ok and fs.exists(output)? and fs.exists(oracle_file)? and candidate_text == oracle_text
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
  let artifact = p"/work/jsonfilter.xsh"
  let artifact_present = fs.exists(artifact)?
  fs.write(p"/tmp/task-jsonfilter-oracle.sh", r"""#!/bin/sh
set -eu
out="$1"
test -n "${CFG_DOC-}" || exit 1
rendered="$(printf '%s' "$CFG_DOC" | jq -cS '.records | map(select(.active == true)) | sort_by(.name) | map({name, count})')" || exit 1
printf '%s\n' "$rendered" > "$out"
""")?
  fs.chmod(p"/tmp/task-jsonfilter-oracle.sh", 0o755)?
  var all_exact = artifact_present
  var cases: List[CaseResult] = []
  if artifact_present {
    let inputs: List[Case] = [
      {name: "public", document: "{\"records\":[{\"name\":\"beta\",\"active\":true,\"count\":3},{\"name\":\"alpha\",\"active\":false,\"count\":2},{\"name\":\"gamma\",\"active\":true,\"count\":7}]}", missing: false, expect_fail: false},
      {name: "hidden_empty", document: "{\"records\":[]}", missing: false, expect_fail: false},
      {name: "hidden_all_inactive", document: "{\"records\":[{\"name\":\"a\",\"active\":false,\"count\":1}]}", missing: false, expect_fail: false},
      {name: "hidden_single", document: "{\"records\":[{\"name\":\"only\",\"active\":true,\"count\":0}]}", missing: false, expect_fail: false},
      {name: "hidden_unicode", document: "{\"records\":[{\"name\":\"héllo\",\"active\":true,\"count\":2},{\"name\":\"äpple\",\"active\":true,\"count\":1}]}", missing: false, expect_fail: false},
      {name: "hidden_spaces", document: "{\"records\":[{\"name\":\"us east 1\",\"active\":true,\"count\":4}]}", missing: false, expect_fail: false},
      {name: "hidden_zero", document: "{\"records\":[{\"name\":\"zero\",\"active\":true,\"count\":0}]}", missing: false, expect_fail: false},
      {name: "hidden_large", document: "{\"records\":[{\"name\":\"large\",\"active\":true,\"count\":1048576}]}", missing: false, expect_fail: false},
      {name: "hidden_malformed", document: "not-json", missing: false, expect_fail: true},
      {name: "hidden_missing", document: "", missing: true, expect_fail: true},
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
  let restriction_ok = artifact_present and source.contains("json.") and
    ! source.contains("process.") and ! source.contains("spawn ") and
    ! source.contains("run ") and ! source.contains("jq")
  let protocol_ok = review_ok()?
  let passed = all_exact and restriction_ok and protocol_ok
  json.write(p"/session/run.json", {
    image_id: env.get_or("FACTORY_IMAGE_ID", "unknown")?,
    platform: env.get_or("FACTORY_PLATFORM", "unknown")?,
    eval_id: env.get_or("FACTORY_EVAL_ID", "task-jsonfilter")?,
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
