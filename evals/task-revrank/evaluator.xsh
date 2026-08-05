##! Package-owned evaluator for task-revrank.
##! This script owns the fixture, oracle, correctness, restriction, and
##! protocol checks; it must not delegate task logic to a legacy dispatcher.

type Case = {name: Str, content: Str, missing: Bool, expect_fail: Bool}

type CaseResult = {
  name: Str,
  exact: Bool,
  candidate_exit: Int,
  oracle_exit: Int,
  candidate_wall_ns: Int,
  oracle_wall_ns: Int,
}

pure source_has_forbidden_subprocess(source: Str) -> Bool {
  for line in source.lines() {
    let code = line.split("#").get(0, "")
    if code.contains("process.") or code.contains("spawn ") or code.contains("run ") {
      return true
    }
  }
  return false
}

proc copy_results() [fs, error] -> Result[Unit] {
  for name in ["revrank.xsh", "review.md"] {
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

proc seed_fixture(target: Path, content: Str) [fs, error] -> Result[Unit] {
  fs.write(target, content)?
  return Ok()
}

proc run_case(index: Int, case: Case, oracle: Path) [fs, process, time, error] -> Result[CaseResult] {
  let data_file = fp"/tmp/task-revrank-${index}.txt"
  let candidate_out = fp"/session/task-revrank-candidate-${index}.stdout"
  let candidate_err = fp"/session/task-revrank-candidate-${index}.stderr"
  let oracle_out = fp"/session/task-revrank-oracle-${index}.stdout"
  let oracle_err = fp"/session/task-revrank-oracle-${index}.stderr"
  for cleanup in [data_file, candidate_out, candidate_err, oracle_out, oracle_err] {
    fs.remove(cleanup, missing_ok: true)?
  }
  if ! case.missing {
    seed_fixture(data_file, case.content)?
  }
  let candidate = time.measure(process.command_argv(
    "xsh",
    ["xsh", "/work/revrank.xsh", data_file.display()],
    stdout: candidate_out, stderr: candidate_err,
  ))?
  let oracle_result = time.measure(process.command_argv(
    "sh",
    ["sh", oracle.display(), data_file.display()],
    stdout: oracle_out, stderr: oracle_err,
  ))?
  let candidate_text = if fs.exists(candidate_out)? { candidate_out.read_text()? } else { "" }
  let oracle_text = if fs.exists(oracle_out)? { oracle_out.read_text()? } else { "" }
  let exact = if case.expect_fail {
    ! candidate.status.ok and ! oracle_result.status.ok and
      candidate_text == "" and oracle_text == ""
  } else {
    candidate.status.ok and oracle_result.status.ok and candidate_text == oracle_text
  }
  return {
    name: case.name,
    exact: exact,
    candidate_exit: candidate.status.exit_code() ?? -1,
    oracle_exit: oracle_result.status.exit_code() ?? -1,
    candidate_wall_ns: candidate.wall_ns,
    oracle_wall_ns: oracle_result.wall_ns,
  }
}

proc main() [fs, process, env, time, error, io] {
  defer copy_results()?
  let artifact = p"/work/revrank.xsh"
  let artifact_present = fs.exists(artifact)?
  let oracle = p"/tmp/task-revrank-oracle.sh"
  fs.write(oracle, r"""#!/bin/sh
set -o pipefail
file="$1"
awk '{
  if (NF == 0) next
  if (NF != 4) { bad = 1; exit 2 }
  if ($3 !~ /^-?[0-9]+$/ || $4 !~ /^-?[0-9]+$/) { bad = 1; exit 2 }
  rev[$1] += $3 * $4
}
END { if (bad) exit 2; for (r in rev) print rev[r], r }' "$file" | sort -k1,1rn -k2,2 | awk '{print $2 " " $1}'
""")?
  fs.chmod(oracle, 0o755)?

  var all_exact = artifact_present
  var cases: List[CaseResult] = []
  if artifact_present {
    let inputs: List[Case] = [
      {name: "public", content: "north gadget 2 10\nsouth widget 3 5\neast tool 1 4\n", missing: false, expect_fail: false},
      {name: "hidden_multiproduct", content: "north gadget 2 10\nnorth widget 5 4\nsouth tool 3 5\nnorth spare 1 8\n", missing: false, expect_fail: false},
      {name: "hidden_tie", content: "alpha a 1 10\nbeta b 2 5\ngamma g 10 1\n", missing: false, expect_fail: false},
      {name: "hidden_negative", content: "north gadget 2 10\nsouth widget -3 5\nnorth refund 1 -8\n", missing: false, expect_fail: false},
      {name: "hidden_order", content: "zebra z 1 9\napple a 3 3\n", missing: false, expect_fail: false},
      {name: "hidden_many", content: "r1 p 1 1\nr2 q 2 2\nr1 p 3 3\nr3 s 4 4\nr2 q 5 5\n", missing: false, expect_fail: false},
      {name: "hidden_empty", content: "", missing: false, expect_fail: false},
      {name: "hidden_bad_fields", content: "north gadget 2\n", missing: false, expect_fail: true},
      {name: "hidden_bad_unit", content: "north gadget x 10\n", missing: false, expect_fail: true},
      {name: "hidden_missing", content: "", missing: true, expect_fail: true},
    ]
    var index = 0
    for case in inputs {
      index += 1
      let result = run_case(index, case, oracle)?
      cases = cases.push(result)
      if ! result.exact { all_exact = false }
    }
  }

  let source = if artifact_present { artifact.read_text()? } else { "" }
  let restriction_ok = artifact_present and
    (source.contains("read_text")) and
    source.contains("parse_int") and
    source.contains("sort-by") and
    source.contains("Map[Int]") and
    ! source_has_forbidden_subprocess(source)
  let protocol_ok = review_ok()?
  let passed = all_exact and restriction_ok and protocol_ok
  json.write(p"/session/run.json", {
    image_id: env.get_or("FACTORY_IMAGE_ID", "unknown")?,
    platform: env.get_or("FACTORY_PLATFORM", "unknown")?,
    eval_id: env.get_or("FACTORY_EVAL_ID", "task-revrank")?,
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
