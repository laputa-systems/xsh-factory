##! Package-owned evaluator for task-manifest.
##!
##! New evals do not add a task branch to evaluate_common.xsh or
##! evaluate_legacy.xsh; this script carries the full case/oracle logic and is
##! staged and mounted by the generic evaluator protocol.

use factory_control as control

type Case = {
  name: Str,
  root: Str,
  dirs: List[Str],
  files: List[Str],
  missing_root: Bool,
}

type CaseResult = {
  name: Str,
  exact: Bool,
  candidate_exit: Int,
  oracle_exit: Int,
  candidate_wall_ns: Int,
  oracle_wall_ns: Int,
}

proc copy_results() [fs, error] -> Result[Unit] {
  for name in ["manifest.xsh", "review.md"] {
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
  let out = fp"/session/manifest-out-${index}.txt"
  let oracle_out = fp"/session/manifest-oracle-${index}.txt"
  fs.remove(out, missing_ok: true)?
  fs.remove(oracle_out, missing_ok: true)?
  if ! case.missing_root {
    fs.mkdir(Path(case.root), parents: true)?
    for d in case.dirs {
      fs.mkdir(Path(d), parents: true)?
    }
    for f in case.files {
      fs.write(Path(f), "")?
    }
  }
  let candidate = time.measure(process.command_argv(
    "xsh", ["xsh", "/work/manifest.xsh", case.root, out.display()],
    stderr: fp"/session/manifest-candidate-${index}.stderr",
  ))?
  let oracle = time.measure(process.command_argv(
    "sh", ["sh", "/tmp/manifest-oracle.sh", case.root],
    stdout: oracle_out, stderr: fp"/session/manifest-oracle-${index}.stderr",
  ))?
  let candidate_text = if fs.exists(out)? { out.read_text()? } else { "" }
  let oracle_text = if fs.exists(oracle_out)? { oracle_out.read_text()? } else { "" }
  let exact = if case.missing_root {
    ! candidate.status.ok and ! oracle.status.ok and ! fs.exists(out)?
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
  let artifact = p"/work/manifest.xsh"
  let artifact_present = fs.exists(artifact)?
  var all_exact = artifact_present
  var cases: List[CaseResult] = []
  if artifact_present {
    fs.write(p"/tmp/manifest-oracle.sh", "#!/bin/sh\nroot=\"$1\"\nif [ ! -d \"$root\" ]; then exit 1; fi\nfind \"$root\" -type f | sed \"s|^$root/||\" | LC_ALL=C sort\n")?
    let inputs: List[Case] = [
      {name: "public", root: "/tmp/manifest-1", dirs: ["/tmp/manifest-1/a", "/tmp/manifest-1/m/n"], files: [
        "/tmp/manifest-1/zebra.txt", "/tmp/manifest-1/a/b.txt", "/tmp/manifest-1/a/c.log",
        "/tmp/manifest-1/top.txt", "/tmp/manifest-1/m/n/o.txt",
      ], missing_root: false},
      {name: "hidden_nested", root: "/tmp/manifest-2", dirs: ["/tmp/manifest-2/x/y/z", "/tmp/manifest-2/x"], files: [
        "/tmp/manifest-2/x/y/z/deep.txt", "/tmp/manifest-2/x/a.txt", "/tmp/manifest-2/root.txt",
      ], missing_root: false},
      {name: "hidden_empty_dirs", root: "/tmp/manifest-3", dirs: ["/tmp/manifest-3/d1", "/tmp/manifest-3/d2/e"], files: [
        "/tmp/manifest-3/keep.txt",
      ], missing_root: false},
      {name: "hidden_single", root: "/tmp/manifest-4", dirs: [], files: [
        "/tmp/manifest-4/only.txt",
      ], missing_root: false},
      {name: "hidden_spaces", root: "/tmp/manifest-5", dirs: ["/tmp/manifest-5/dir with space"], files: [
        "/tmp/manifest-5/my file.txt", "/tmp/manifest-5/dir with space/n.txt",
      ], missing_root: false},
      {name: "hidden_utf8", root: "/tmp/manifest-6", dirs: ["/tmp/manifest-6/résumé"], files: [
        "/tmp/manifest-6/café.txt", "/tmp/manifest-6/résumé/notes.txt",
      ], missing_root: false},
      {name: "hidden_empty", root: "/tmp/manifest-7", dirs: ["/tmp/manifest-7/sub"], files: [], missing_root: false},
      {name: "hidden_missing_root", root: "/tmp/manifest-missing", dirs: [], files: [], missing_root: true},
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
  let restriction_ok = artifact_present and
    (source.contains("fs.files") or source.contains("fs.walk")) and
    ! control.source_has_forbidden_subprocess(source)
  let protocol_ok = review_ok()?
  let passed = all_exact and restriction_ok and protocol_ok
  json.write(p"/session/run.json", {
    image_id: env.get_or("FACTORY_IMAGE_ID", "unknown")?,
    platform: env.get_or("FACTORY_PLATFORM", "unknown")?,
    eval_id: env.get_or("FACTORY_EVAL_ID", "task-manifest")?,
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
