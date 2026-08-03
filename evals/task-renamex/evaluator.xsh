##! Package-owned evaluator for task-renamex.
##! Runs the candidate and an external BusyBox sh oracle on fresh copies of the
##! same fixture tree, compares the resulting set of relative file paths, checks
##! the no-subprocess / fs-only restriction and the review.md protocol, and
##! writes a JSON run manifest to /session/run.json.

type Fixture = {rel: List[Str]}

type Case = {name: Str, fixture: Fixture, missing: Bool, expect_fail: Bool}

type CaseResult = {
  name: Str,
  exact: Bool,
  candidate_exit: Int,
  oracle_exit: Int,
  candidate_wall_ns: Int,
  oracle_wall_ns: Int,
}

proc source_has_forbidden_subprocess(source: Str) [] -> Bool {
  for line in source.lines() {
    let code = line.split("#").get(0, "")
    if code.contains("process.") or code.contains("spawn ") or code.contains("mv ") or code.contains("run ") {
      return true
    }
  }
  return false
}

proc copy_results(work_dir: Path) [fs, env, error] -> Result[Unit] {
  let export_dir = env.path("EXPORT_DIR", p"/export")?
  for name in ["renamex.xsh", "review.md"] {
    let source = fp"${work_dir}/${name}"
    if fs.exists(source)? and fs.exists(export_dir)? {
      fs.copy(source, fp"${export_dir}/${name}", overwrite: true)?
    }
  }
  return Ok()
}

proc review_ok(work_dir: Path) [fs, error] -> Result[Bool] {
  let review = fp"${work_dir}/review.md"
  if ! fs.exists(review)? or fs.metadata(review)?.size == 0 {
    return false
  }
  let text = review.read_text()?
  return text.contains("## XSH language proposals") and
    text.contains("## xsht friction") and ! text.contains("{{")
}

proc seed_fixture(root: Path, fixture: Fixture) [fs, error] -> Result[Unit] {
  fs.mkdir(root, parents: true)?
  for rel in fixture.rel {
    let dest = fp"${root}/${rel}"
    let dir = dest.parent()
    if ! fs.exists(dir)? {
      fs.mkdir(dir, parents: true)?
    }
    fs.write(dest, "x")?
  }
  return Ok()
}

proc collect_relative(root: Path) [fs, error] -> Result[Str] {
  let prefix = root.display() + "/"
  let rels = fs.walk(root)
    |> where .kind == "file"
    |> map { |e| e.path.display().replace(prefix, "") }
    |> sort-by { |s| s }
    |> collect()
  return rels.join("\n")
}

proc run_case(index: Int, case: Case, artifact: Path, oracle_script: Path, session_dir: Path) [fs, process, time, error] -> Result[CaseResult] {
  let base = fp"/tmp/task-renamex-${index}"
  let cand_dir = fp"${base}-cand"
  let ora_dir = fp"${base}-ora"
  let cand_out = fp"${session_dir}/renamex-cand-${index}.stdout"
  let cand_err = fp"${session_dir}/renamex-cand-${index}.stderr"
  let ora_out = fp"${session_dir}/renamex-ora-${index}.stdout"
  let ora_err = fp"${session_dir}/renamex-ora-${index}.stderr"
  if ! case.expect_fail {
    seed_fixture(cand_dir, case.fixture)?
    seed_fixture(ora_dir, case.fixture)?
  }
  let cand = time.measure(process.command_argv(
    "xsh", ["xsh", artifact.display(), cand_dir.display()],
    stdout: cand_out, stderr: cand_err,
  ))?
  let ora = time.measure(process.command_argv(
    "sh", ["sh", oracle_script.display(), ora_dir.display()],
    stdout: ora_out, stderr: ora_err,
  ))?
  let cand_ok = cand.status.ok
  let ora_ok = ora.status.ok
  let exact = if case.expect_fail {
    ! cand_ok and ! ora_ok
  } else {
    cand_ok and ora_ok and collect_relative(cand_dir)? == collect_relative(ora_dir)?
  }
  return {
    name: case.name,
    exact: exact,
    candidate_exit: cand.status.exit_code() ?? -1,
    oracle_exit: ora.status.exit_code() ?? -1,
    candidate_wall_ns: cand.wall_ns,
    oracle_wall_ns: ora.wall_ns,
  }
}

proc main(...argv: List[Str]) [fs, process, env, time, error, io] {
  let work_dir = env.path("WORK_DIR", p"/work")?
  let session_dir = env.path("SESSION_DIR", p"/session")?
  let man_path = fp"${session_dir}/run.json"
  let artifact = fp"${work_dir}/renamex.xsh"
  let artifact_present = fs.exists(artifact)?
  let oracle_script = p"/tmp/task-renamex-oracle.sh"
  fs.write(oracle_script, r"""#!/bin/sh
if [ ! -d "$1" ]; then exit 1; fi
for f in $(find "$1" -type f -name '*.tmp'); do
  mv "$f" "${f%.tmp}.bak"
done
exit 0
""")?
  fs.chmod(oracle_script, 0o755)?

  let fixtures: List[Case] = [
    {name: "public", fixture: {rel: ["a.tmp", "b.tmp", "keep.txt"]}, missing: false, expect_fail: false},
    {name: "hidden_nested", fixture: {rel: ["top.tmp", "sub/deep.tmp", "sub/note.txt"]}, missing: false, expect_fail: false},
    {name: "hidden_dotname", fixture: {rel: ["proj/x.tmp", ".hidden.tmp", "proj/doc.md"]}, missing: false, expect_fail: false},
    {name: "hidden_no_suffix", fixture: {rel: ["tmp", "note.txt", "data.log"]}, missing: false, expect_fail: false},
    {name: "hidden_empty", fixture: {rel: []}, missing: false, expect_fail: false},
    {name: "hidden_missing", fixture: {rel: []}, missing: true, expect_fail: true},
  ]

  var all_exact = artifact_present
  var cases: List[CaseResult] = []
  if artifact_present {
    var index = 0
    for case in fixtures {
      index += 1
      let result = run_case(index, case, artifact, oracle_script, session_dir)?
      cases = cases.push(result)
      if ! result.exact { all_exact = false }
    }
  }

  let source = if artifact_present { artifact.read_text()? } else { "" }
  let restriction_ok = artifact_present and source.contains("fs.rename") and
    (source.contains("fs.files") or source.contains("fs.walk")) and
    ! source_has_forbidden_subprocess(source)
  let protocol_ok = review_ok(work_dir)?
  let passed = all_exact and restriction_ok and protocol_ok
  json.write(man_path, {
    image_id: env.get_or("FACTORY_IMAGE_ID", "unknown")?,
    platform: env.get_or("FACTORY_PLATFORM", "unknown")?,
    eval_id: env.get_or("FACTORY_EVAL_ID", "task-renamex")?,
    trial_id: env.get_or("FACTORY_TRIAL_ID", "1")?,
    result: if passed { "pass" } else { "fail" },
    classification: if ! artifact_present { "worker_missing_artifact" } else if ! protocol_ok { "protocol_failed" } else if ! restriction_ok { "restriction_failed" } else if ! all_exact { "candidate_failed" } else { "pass" },
    protocol: {artifact_present: artifact_present, review_ok: protocol_ok},
    correctness: {cases: cases, all_exact: all_exact, passed: all_exact},
    restrictions: {passed: restriction_ok},
    timings: {passed: true},
  }, pretty: true)?
  let _ = copy_results(work_dir)?
  if ! passed { abort(1) }
}
