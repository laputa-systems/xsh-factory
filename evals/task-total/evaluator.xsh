##! Package-owned evaluator for task-total.
##! Runs the candidate and an external BusyBox awk oracle against a set of
##! public and hidden fixtures, checks the no-subprocess restriction and the
##! review.md protocol, and writes a JSON run manifest to /session/run.json.

type Fixture = {name: Str, data: Str, missing: Bool, expect_fail: Bool}

type CaseResult = {
  name: Str,
  exact: Bool,
  candidate_exit: Int,
  oracle_exit: Int,
  candidate_wall_ns: Int,
  oracle_wall_ns: Int,
}

## Detect forbidden subprocess syntax without treating prose in `#` comments
## as code. Self-contained so the evaluator does not depend on a changing
## shared control module inside the eval image.
proc source_has_forbidden_subprocess(source: Str) -> Bool {
  for line in source.lines() {
    let code = line.split("#").get(0, "")
    if code.contains("process.") or code.contains("spawn ") or code.contains("run ") {
      return true
    }
  }
  return false
}

proc copy_results() [fs, error] -> Result[Unit] {
  for name in ["total.xsh", "review.md"] {
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

proc run_case(index: Int, case: Fixture) [fs, process, time, error] -> Result[CaseResult] {
  let input = fp"/tmp/task-total-${index}.txt"
  let candidate_out = fp"/session/task-total-candidate-${index}.stdout"
  let candidate_err = fp"/session/task-total-candidate-${index}.stderr"
  let oracle_out = fp"/session/task-total-oracle-${index}.stdout"
  let oracle_err = fp"/session/task-total-oracle-${index}.stderr"
  for cleanup in [input, candidate_out, candidate_err, oracle_out, oracle_err] {
    if fs.exists(cleanup)? {
      fs.remove(cleanup)?
    }
  }
  if ! case.missing {
    fs.write(input, case.data)?
  }
  let candidate = time.measure(process.command_argv(
    "xsh", ["xsh", "/work/total.xsh", input.display()],
    stdout: candidate_out, stderr: candidate_err,
  ))?
  let oracle_script = p"/tmp/task-total-oracle.sh"
  let oracle = time.measure(process.command_argv(
    "sh", ["sh", oracle_script.display(), input.display()],
    stdout: oracle_out, stderr: oracle_err,
  ))?
  let candidate_text = if fs.exists(candidate_out)? { candidate_out.read_text()? } else { "" }
  let oracle_text = if fs.exists(oracle_out)? { oracle_out.read_text()? } else { "" }
  let candidate_ok = candidate.status.ok
  let oracle_ok = oracle.status.ok
  let exact = if case.expect_fail {
    ! candidate_ok and ! oracle_ok and candidate_text == "" and oracle_text == ""
  } else {
    candidate_ok and oracle_ok and candidate_text == oracle_text and oracle_text != ""
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
  let artifact = p"/work/total.xsh"
  let artifact_present = fs.exists(artifact)?
  let oracle_script = p"/tmp/task-total-oracle.sh"
  fs.write(oracle_script, r"""#!/bin/sh
awk 'NF == 0 { next }
NF != 2 { error = 1 }
$2 !~ /^-?[0-9]+$/ { error = 1 }
error == 0 { count++; total += $2 }
END { if (error) exit 1; printf "count=%d\ntotal=%d\n", count, total }' "$1"
""")?
  fs.chmod(oracle_script, 0o755)?
  var all_exact = artifact_present
  var cases: List[CaseResult] = []
  if artifact_present {
    let inputs: List[Fixture] = [
      {name: "public", data: "alpha 10\nbeta 20\ngamma 30\n", missing: false, expect_fail: false},
      {name: "hidden_blank", data: "a 1\n\nb 2\n  \nc 3\n", missing: false, expect_fail: false},
      {name: "hidden_negative", data: "a -5\nb 3\nc -2\n", missing: false, expect_fail: false},
      {name: "hidden_zero", data: "a 0\nb 0\n", missing: false, expect_fail: false},
      {name: "hidden_leading", data: "  a   5  \n\tb\t7\n", missing: false, expect_fail: false},
      {name: "hidden_unicode", data: "héllo 4\nwörld 6\n", missing: false, expect_fail: false},
      {name: "hidden_single", data: "only 1\n", missing: false, expect_fail: false},
      {name: "hidden_padded", data: "x 007\ny 000\n", missing: false, expect_fail: false},
      {name: "hidden_nonewline", data: "a 3\nb 4", missing: false, expect_fail: false},
      {name: "hidden_empty", data: "", missing: false, expect_fail: false},
      {name: "hidden_malformed", data: "a 1 b\nother 2\n", missing: false, expect_fail: true},
      {name: "hidden_nonnum", data: "a 1\nb notanumber\n", missing: false, expect_fail: true},
      {name: "hidden_missing", data: "", missing: true, expect_fail: true},
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
    ! source_has_forbidden_subprocess(source)
  let protocol_ok = review_ok()?
  let passed = all_exact and restriction_ok and protocol_ok
  json.write(p"/session/run.json", {
    image_id: env.get_or("FACTORY_IMAGE_ID", "unknown")?,
    platform: env.get_or("FACTORY_PLATFORM", "unknown")?,
    eval_id: env.get_or("FACTORY_EVAL_ID", "task-total")?,
    trial_id: env.get_or("FACTORY_TRIAL_ID", "1")?,
    result: if passed { "pass" } else { "fail" },
    classification: if ! artifact_present { "worker_missing_artifact" } else if ! protocol_ok { "protocol_failed" } else if ! restriction_ok { "restriction_failed" } else if ! all_exact { "candidate_failed" } else { "pass" },
    protocol: {artifact_present: artifact_present, review_ok: protocol_ok},
    correctness: {cases: cases, all_exact: all_exact, passed: all_exact},
    restrictions: {passed: restriction_ok},
    timings: {passed: true},
  }, pretty: true)?
  let _ = copy_results()?
  if ! passed { abort(1) }
}
