##! Package-owned evaluator for task-iniget.
##! Writes hidden INI fixtures, runs the candidate as
##! `xsh /work/iniget.xsh <file> <section> <key>` for each case, compares
##! candidate stdout byte-for-byte with an independent oracle, and checks that
##! the source uses the `ini` module, contains no forbidden subprocess
##! boundary, and completes the review.md protocol. Writes a JSON run manifest
##! to <session>/run.json.
##!
##! The sandbox roots default to the container contract (/work, /session,
##! /export) but may be overridden with INIGET_WORK / INIGET_SESSION /
##! INIGET_EXPORT so the same script can be validated on a host that has no
##! root-level /work. Production does not set these variables.

type InigetCase = {name: Str, file_body: Str, section: Str, key: Str, expected: Str, expect_fail: Bool}

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
  for name in ["iniget.xsh", "review.md"] {
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

proc run_case(index: Int, case: InigetCase, work: Path, session: Path) [fs, process, time, error] -> Result[CaseResult] {
  let input = fp"/tmp/iniget-fixture-${index}.ini"
  let candidate_out = fp"${session}/iniget-candidate-${index}.stdout"
  let candidate_err = fp"${session}/iniget-candidate-${index}.stderr"
  let oracle_out = fp"${session}/iniget-oracle-${index}.stdout"
  let oracle_err = fp"${session}/iniget-oracle-${index}.stderr"
  for cleanup in [input, candidate_out, candidate_err, oracle_out, oracle_err] {
    if fs.exists(cleanup)? {
      fs.remove(cleanup)?
    }
  }
  fs.write(input, case.file_body)?
  let candidate = time.measure(process.command_argv(
    "xsh", ["xsh", fp"${work}/iniget.xsh".display(), input.display(), case.section, case.key],
    stdout: candidate_out, stderr: candidate_err,
  ))?
  let oracle = if case.expect_fail {
    time.measure(process.command_argv(
      "sh", ["sh", "-c", "exit 1"],
      stdout: oracle_out, stderr: oracle_err,
    ))?
  } else {
    time.measure(process.command_argv(
      "printf", ["printf", case.expected + "\\n"],
      stdout: oracle_out, stderr: oracle_err,
    ))?
  }
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
  let work = Path(env.get_or("INIGET_WORK", "/work")?)
  let session = Path(env.get_or("INIGET_SESSION", "/session")?)
  let export_dir = Path(env.get_or("INIGET_EXPORT", "/export")?)
  let artifact = fp"${work}/iniget.xsh"
  let artifact_present = fs.exists(artifact)?
  var all_exact = artifact_present
  let cases: List[InigetCase] = [
    {name: "public", file_body: "# sample config\n[server]\nhost = example.test\nport = 8443\n\n[limits]\nmax_conn = 100\n", section: "server", key: "host", expected: "example.test", expect_fail: false},
    {name: "hidden_port", file_body: "[server]\nhost = node-a\nport = 8080\n", section: "server", key: "port", expected: "8080", expect_fail: false},
    {name: "hidden_spaces", file_body: "[app]\nname = hello world\ndebug = true\n", section: "app", key: "name", expected: "hello world", expect_fail: false},
    {name: "hidden_trim", file_body: "[alpha]\npath = /usr/local/bin   \n", section: "alpha", key: "path", expected: "/usr/local/bin", expect_fail: false},
    {name: "hidden_global", file_body: "owner = root\n[service]\nname = api\n", section: "service", key: "name", expected: "api", expect_fail: false},
    {name: "hidden_missing_key", file_body: "[server]\nhost = a\n", section: "server", key: "absent", expected: "", expect_fail: true},
    {name: "hidden_missing_section", file_body: "[server]\nhost = a\n", section: "nosuch", key: "host", expected: "", expect_fail: true},
    {name: "hidden_malformed", file_body: "[server]\nhost = a\nhost = b\n", section: "server", key: "host", expected: "", expect_fail: true},
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
  let uses_ini = source.contains("ini.")
  let restriction_ok = artifact_present and uses_ini and ! source_has_forbidden_subprocess(source)
  let protocol_ok = review_ok(work)?
  let passed = all_exact and restriction_ok and protocol_ok
  json.write(fp"${session}/run.json", {
    image_id: env.get_or("FACTORY_IMAGE_ID", "unknown")?,
    platform: env.get_or("FACTORY_PLATFORM", "unknown")?,
    eval_id: env.get_or("FACTORY_EVAL_ID", "task-iniget")?,
    trial_id: env.get_or("FACTORY_TRIAL_ID", "1")?,
    result: if passed { "pass" } else { "fail" },
    classification: if ! artifact_present { "worker_missing_artifact" } else if ! protocol_ok { "protocol_failed" } else if ! restriction_ok { "restriction_failed" } else if ! all_exact { "candidate_failed" } else { "pass" },
    protocol: {artifact_present: artifact_present, review_ok: protocol_ok},
    correctness: {cases: results, all_exact: all_exact, passed: all_exact},
    restrictions: {uses_ini: uses_ini, passed: restriction_ok},
    timings: {passed: true},
  }, pretty: true)?
  let _ = copy_results(work, export_dir)?
  if ! passed { abort(1) }
}
