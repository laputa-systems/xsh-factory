##! Package-owned evaluator for task-usagerep.
##! Stages a fresh fixture tree per case under the evaluator's writable /tmp,
##! runs the candidate as `xsh /work/usagerep.xsh <root>`, compares candidate
##! stdout byte-for-byte with an independent oracle (printf for success rows,
##! `sh -c 'exit 1'` for failure/empty-stdout semantics), and checks that the
##! source reads file contents through `read_text`, discovers the tree with
##! `fs.files`/`fs.walk`, contains no forbidden subprocess boundary, and
##! completes the review.md protocol. Writes a JSON run manifest to
##! <session>/run.json.
##!
##! The sandbox roots default to the container contract (/work, /session,
##! /export) but may be overridden with USAGEREP_WORK / USAGEREP_SESSION /
##! USAGEREP_EXPORT so the same script can be validated on a host that has no
##! root-level /work. Production does not set these variables.

type UsageFile = {rel: Str, body: Str}
type UsageCase = {name: Str, files: List[UsageFile], expected: Str, expect_fail: Bool}

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
  for name in ["usagerep.xsh", "review.md"] {
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

proc seed_tree(root: Path, files: List[UsageFile]) [fs, error] -> Result[Unit] {
  fs.mkdir(root, parents: true)?
  for file in files {
    let destination = fp"${root}/${file.rel}"
    let parent = destination.parent()
    if ! fs.exists(parent)? {
      fs.mkdir(parent, parents: true)?
    }
    fs.write(destination, file.body)?
  }
  return Ok()
}

proc run_case(index: Int, case: UsageCase, work: Path, session: Path) [fs, process, time, error] -> Result[CaseResult] {
  let root = fp"/tmp/task-usagerep-${index}"
  let candidate_out = fp"${session}/usagerep-candidate-${index}.stdout"
  let candidate_err = fp"${session}/usagerep-candidate-${index}.stderr"
  let oracle_out = fp"${session}/usagerep-oracle-${index}.stdout"
  let oracle_err = fp"${session}/usagerep-oracle-${index}.stderr"
  for cleanup in [candidate_out, candidate_err, oracle_out, oracle_err] {
    if fs.exists(cleanup)? {
      fs.remove(cleanup)?
    }
  }
  seed_tree(root, case.files)?
  let candidate = time.measure(process.command_argv(
    "xsh", ["xsh", fp"${work}/usagerep.xsh".display(), root.display()],
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
  let work = Path(env.get_or("USAGEREP_WORK", "/work")?)
  let session = Path(env.get_or("USAGEREP_SESSION", "/session")?)
  let export_dir = Path(env.get_or("USAGEREP_EXPORT", "/export")?)
  let artifact = fp"${work}/usagerep.xsh"
  let artifact_present = fs.exists(artifact)?
  var all_exact = artifact_present
  let cases: List[UsageCase] = [
    {name: "public", files: [
      {rel: "a.usage", body: "api 10\ndb 5\nweb 3\n"},
    ], expected: "api 10 1\ndb 5 1\nweb 3 1\n", expect_fail: false},
    {name: "hidden_multi", files: [
      {rel: "dir1/a.usage", body: "api 4\ndb 2\n"},
      {rel: "dir1/sub/x.usage", body: "api 6\n"},
      {rel: "dir2/other.usage", body: "web 1\napi 1\n"},
      {rel: "ignore.txt", body: "api 999\n"},
    ], expected: "api 11 3\ndb 2 1\nweb 1 1\n", expect_fail: false},
    {name: "hidden_ties", files: [
      {rel: "usage.usage", body: "alpha 5\nbeta 5\ngamma 1\n"},
    ], expected: "alpha 5 1\nbeta 5 1\ngamma 1 1\n", expect_fail: false},
    {name: "hidden_order", files: [
      {rel: "usage.usage", body: "z 5\n10 3\n2 9\na 5\n"},
    ], expected: "2 9 1\na 5 1\nz 5 1\n10 3 1\n", expect_fail: false},
    {name: "hidden_blank", files: [
      {rel: "usage.usage", body: "a 1\n\nb 2\n  \na 3\n"},
    ], expected: "a 4 2\nb 2 1\n", expect_fail: false},
    {name: "hidden_empty", files: [
      {rel: "ignore.txt", body: "anything\n"},
    ], expected: "", expect_fail: false},
    {name: "hidden_empty_file", files: [
      {rel: "empty.usage", body: ""},
      {rel: "main.usage", body: "api 2\ndb 3\n"},
    ], expected: "db 3 1\napi 2 1\n", expect_fail: false},
    {name: "hidden_spaces", files: [
      {rel: "dir with space/usage file.usage", body: "api 2\n"},
    ], expected: "api 2 1\n", expect_fail: false},
    {name: "hidden_bad_value", files: [
      {rel: "a.usage", body: "api 5\ndb xyz\n"},
    ], expected: "", expect_fail: true},
    {name: "hidden_bad_fields", files: [
      {rel: "a.usage", body: "api 5\ndb 2 extra\n"},
    ], expected: "", expect_fail: true},
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
  let discovers_tree = source.contains("fs.files") or source.contains("fs.walk")
  let restriction_ok = artifact_present and reads_text and discovers_tree and
    ! source_has_forbidden_subprocess(source)
  let protocol_ok = review_ok(work)?
  let passed = all_exact and restriction_ok and protocol_ok
  json.write(fp"${session}/run.json", {
    image_id: env.get_or("FACTORY_IMAGE_ID", "unknown")?,
    platform: env.get_or("FACTORY_PLATFORM", "unknown")?,
    eval_id: env.get_or("FACTORY_EVAL_ID", "task-usagerep")?,
    trial_id: env.get_or("FACTORY_TRIAL_ID", "1")?,
    result: if passed { "pass" } else { "fail" },
    classification: if ! artifact_present { "worker_missing_artifact" } else if ! protocol_ok { "protocol_failed" } else if ! restriction_ok { "restriction_failed" } else if ! all_exact { "candidate_failed" } else { "pass" },
    protocol: {artifact_present: artifact_present, review_ok: protocol_ok},
    correctness: {cases: results, all_exact: all_exact, passed: all_exact},
    restrictions: {reads_text: reads_text, discovers_tree: discovers_tree, passed: restriction_ok},
    timings: {passed: true},
  }, pretty: true)?
  let _ = copy_results(work, export_dir)?
  if ! passed { abort(1) }
}
