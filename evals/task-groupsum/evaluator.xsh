##! Package-owned evaluator for task-groupsum.
##! Writes hidden two-field fixtures, runs the candidate as
##! `xsh /work/groupsum.xsh <file>` for each case, compares candidate stdout
##! byte-for-byte with an independent oracle (printf for success rows,
##! `sh -c 'exit 1'` for failure/empty-stdout semantics), and checks that the
##! source reads through an XSH text API, contains no forbidden subprocess
##! boundary, and completes the review.md protocol. Writes a JSON run manifest
##! to <session>/run.json.
##!
##! The sandbox roots default to the container contract (/work, /session,
##! /export) but may be overridden with GROUPSUM_WORK / GROUPSUM_SESSION /
##! GROUPSUM_EXPORT so the same script can be validated on a host that has no
##! root-level /work. Production does not set these variables.

type GroupsumCase = {name: Str, file_body: Str, expected: Str, expect_fail: Bool, create_file: Bool}

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
pure source_has_forbidden_subprocess(source: Str) -> Bool {
  for line in source.lines() {
    let code = line.split("#").get(0, "")
    if code.contains("process.") or code.contains("spawn ") or code.contains("run ") {
      return true
    }
  }
  return false
}

proc copy_results(work: Path, out_dir: Path) [fs, error] -> Result[Unit] {
  for name in ["groupsum.xsh", "review.md"] {
    let source = fp"${work}/${name}"
    if fs.exists(source)? {
      fs.copy(source, fp"${out_dir}/${name}", overwrite: true)?
    }
  }
  return Ok()
}

proc review_ok(work: Path) [fs, error] -> Result[Bool] {
  let review = fp"${work}/review.md"
  if ! fs.exists(review)? or fs.metadata(review)?.size == 0 {
    return false
  }
  let text = review.read_text()?
  return text.contains("## XSH language proposals") and
    text.contains("## xsht friction") and ! text.contains("{{")
}

proc run_case(index: Int, case: GroupsumCase, work: Path, session: Path) [fs, process, time, error] -> Result[CaseResult] {
  let input = fp"/tmp/groupsum-fixture-${index}.txt"
  let candidate_out = fp"${session}/groupsum-candidate-${index}.stdout"
  let candidate_err = fp"${session}/groupsum-candidate-${index}.stderr"
  let oracle_out = fp"${session}/groupsum-oracle-${index}.stdout"
  let oracle_err = fp"${session}/groupsum-oracle-${index}.stderr"
  for cleanup in [input, candidate_out, candidate_err, oracle_out, oracle_err] {
    if fs.exists(cleanup)? {
      fs.remove(cleanup)?
    }
  }
  if case.create_file {
    fs.write(input, case.file_body)?
  }
  let candidate = time.measure(process.command_argv(
    "xsh", ["xsh", fp"${work}/groupsum.xsh".display(), input.display()],
    stdout: candidate_out, stderr: candidate_err,
  ))?
  let oracle = if case.expect_fail {
    time.measure(process.command_argv(
      "sh", ["sh", "-c", "exit 1"],
      stdout: oracle_out, stderr: oracle_err,
    ))?
  } else {
    time.measure(process.command_argv(
      "printf", ["printf", case.expected],
      stdout: oracle_out, stderr: oracle_err,
    ))?
  }
  let candidate_text = if fs.exists(candidate_out)? { candidate_out.read_text()? } else { "" }
  let oracle_text = if fs.exists(oracle_out)? { oracle_out.read_text()? } else { "" }
  let candidate_ok = candidate.status.ok
  let oracle_ok = oracle.status.ok
  let exact = if case.expect_fail {
    ! candidate_ok and ! oracle_ok and candidate_text == ""
  } else {
    candidate_ok and oracle_ok and candidate_text == oracle_text
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
  let work = Path(env.get_or("GROUPSUM_WORK", "/work")?)
  let session = Path(env.get_or("GROUPSUM_SESSION", "/session")?)
  let export_dir = Path(env.get_or("GROUPSUM_EXPORT", "/export")?)
  let artifact = fp"${work}/groupsum.xsh"
  let artifact_present = fs.exists(artifact)?
  var all_exact = artifact_present
  let cases: List[GroupsumCase] = [
    {name: "public", file_body: "alpha 1\nbeta 2\ngamma 3\n", expected: "alpha 1\nbeta 2\ngamma 3\n", expect_fail: false, create_file: true},
    {name: "hidden_accumulate", file_body: "server 10\nserver 5\ndb 3\ndb 1\n", expected: "db 4\nserver 15\n", expect_fail: false, create_file: true},
    {name: "hidden_order", file_body: "z 1\n10 5\n2 3\na 2\n", expected: "10 5\n2 3\na 2\nz 1\n", expect_fail: false, create_file: true},
    {name: "hidden_many", file_body: "build 1\nbuild 2\nbuild 3\nbuild 4\ntest 7\n", expected: "build 10\ntest 7\n", expect_fail: false, create_file: true},
    {name: "hidden_blank", file_body: "a 1\n\nb 2\n\na 3\n", expected: "a 4\nb 2\n", expect_fail: false, create_file: true},
    {name: "hidden_empty", file_body: "\n  \n\n", expected: "", expect_fail: false, create_file: true},
    {name: "hidden_bad_fields", file_body: "a 1\nb 2 c\n", expected: "", expect_fail: true, create_file: true},
    {name: "hidden_bad_value", file_body: "a 1\nb xyz\n", expected: "", expect_fail: true, create_file: true},
    {name: "hidden_missing", file_body: "a 1\n", expected: "", expect_fail: true, create_file: false},
  ]
  var results: List[CaseResult] = []
  var index = 0
  for case in cases {
    index += 1
    let result = run_case(index, case, work, session)?
    results = results.push(result)
    if ! result.exact { all_exact = false }
  }
  let source = if artifact_present { artifact.read_text()? } else { "" }
  let reads_text = source.contains("read_text")
  let restriction_ok = artifact_present and reads_text and ! source_has_forbidden_subprocess(source)
  let protocol_ok = review_ok(work)?
  let passed = all_exact and restriction_ok and protocol_ok
  json.write(fp"${session}/run.json", {
    image_id: env.get_or("FACTORY_IMAGE_ID", "unknown")?,
    platform: env.get_or("FACTORY_PLATFORM", "unknown")?,
    eval_id: env.get_or("FACTORY_EVAL_ID", "task-groupsum")?,
    trial_id: env.get_or("FACTORY_TRIAL_ID", "1")?,
    result: if passed { "pass" } else { "fail" },
    classification: if ! artifact_present { "worker_missing_artifact" } else if ! protocol_ok { "protocol_failed" } else if ! restriction_ok { "restriction_failed" } else if ! all_exact { "candidate_failed" } else { "pass" },
    protocol: {artifact_present: artifact_present, review_ok: protocol_ok},
    correctness: {cases: results, all_exact: all_exact, passed: all_exact},
    restrictions: {reads_text: reads_text, passed: restriction_ok},
    timings: {passed: true},
  }, pretty: true)?
  let _ = copy_results(work, export_dir)?
  if ! passed { abort(1) }
}
