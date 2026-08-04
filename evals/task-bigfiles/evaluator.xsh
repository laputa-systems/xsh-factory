##! Package-owned evaluator for task-bigfiles.
##! This script owns the fixture, oracle, correctness, restriction, and
##! protocol checks; it must not delegate task logic to a legacy dispatcher.

type FixtureFile = {rel: Str, data: Str}
type Case = {name: Str, n: Str, files: List[FixtureFile], expect_fail: Bool}

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
  for name in ["bigfiles.xsh", "review.md"] {
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

proc seed_fixture(root: Path, files: List[FixtureFile]) [fs, error] -> Result[Unit] {
  fs.mkdir(root, parents: true)?
  for file in files {
    let destination = fp"${root}/${file.rel}"
    let parent = destination.parent()
    if ! fs.exists(parent)? {
      fs.mkdir(parent, parents: true)?
    }
    fs.write(destination, file.data)?
  }
  return Ok()
}

proc run_case(index: Int, case: Case, oracle: Path) [fs, process, time, error] -> Result[CaseResult] {
  let root = fp"/tmp/task-bigfiles-${index}"
  let candidate_out = fp"/session/task-bigfiles-candidate-${index}.stdout"
  let candidate_err = fp"/session/task-bigfiles-candidate-${index}.stderr"
  let oracle_out = fp"/session/task-bigfiles-oracle-${index}.stdout"
  let oracle_err = fp"/session/task-bigfiles-oracle-${index}.stderr"
  for cleanup in [candidate_out, candidate_err, oracle_out, oracle_err] {
    fs.remove(cleanup, missing_ok: true)?
  }
  seed_fixture(root, case.files)?
  let candidate_args = if case.n == "" {
    ["xsh", "/work/bigfiles.xsh", root.display()]
  } else {
    ["xsh", "/work/bigfiles.xsh", root.display(), case.n]
  }
  let oracle_args = if case.n == "" {
    ["sh", oracle.display(), root.display()]
  } else {
    ["sh", oracle.display(), root.display(), case.n]
  }
  let candidate = time.measure(process.command_argv(
    "xsh", candidate_args,
    stdout: candidate_out, stderr: candidate_err,
  ))?
  let oracle_result = time.measure(process.command_argv(
    "sh", oracle_args,
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
  let artifact = p"/work/bigfiles.xsh"
  let artifact_present = fs.exists(artifact)?
  let oracle = p"/tmp/task-bigfiles-oracle.sh"
  fs.write(oracle, r"""#!/bin/sh
set -o pipefail
root="$1"
n="${2:-5}"
find "$root" -type f | while IFS= read -r f; do
  size=$(wc -c < "$f") || exit 1
  printf '%d %s\n' "$size" "$f"
done | sort -k1,1rn | head -n "$n"
""")?
  fs.chmod(oracle, 0o755)?

  var all_exact = artifact_present
  var cases: List[CaseResult] = []
  if artifact_present {
    let inputs: List[Case] = [
      {name: "public", n: "", files: [
        {rel: "small.txt", data: "a"},
        {rel: "medium.txt", data: "bb"},
        {rel: "large.txt", data: "ccc"},
        {rel: "nested/value.txt", data: "dddd"},
      ], expect_fail: false},
      {name: "hidden_default", n: "", files: [
        {rel: "a", data: "a"}, {rel: "b", data: "bb"}, {rel: "c", data: "ccc"},
        {rel: "d", data: "dddd"}, {rel: "e", data: "eeeee"},
        {rel: "f", data: "ffffff"}, {rel: "g", data: "ggggggg"},
      ], expect_fail: false},
      {name: "hidden_n2", n: "2", files: [
        {rel: "one", data: "1"}, {rel: "two", data: "22"},
        {rel: "three", data: "333"}, {rel: "four", data: "4444"},
        {rel: "five", data: "55555"},
      ], expect_fail: false},
      {name: "hidden_single", n: "5", files: [
        {rel: "only.txt", data: "only"},
      ], expect_fail: false},
      {name: "hidden_deep", n: "", files: [
        {rel: "one/two/three/deep.txt", data: "deep"},
        {rel: "one/top.txt", data: "top-file"},
        {rel: "root.txt", data: "root-file!"},
      ], expect_fail: false},
      {name: "hidden_spaces", n: "", files: [
        {rel: "dir with space/short file", data: "s"},
        {rel: "dir with space/long file", data: "longer"},
      ], expect_fail: false},
      {name: "hidden_utf8", n: "", files: [
        {rel: "résumé/café.txt", data: "utf8"},
        {rel: "日本語.txt", data: "utf-eight"},
      ], expect_fail: false},
      {name: "hidden_empty", n: "", files: [], expect_fail: false},
      {name: "hidden_bad_n", n: "abc", files: [
        {rel: "present.txt", data: "present"},
      ], expect_fail: true},
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
    (source.contains("fs.files") or source.contains("fs.walk")) and
    source.contains("sort-by") and ! source_has_forbidden_subprocess(source)
  let protocol_ok = review_ok()?
  let passed = all_exact and restriction_ok and protocol_ok
  json.write(p"/session/run.json", {
    image_id: env.get_or("FACTORY_IMAGE_ID", "unknown")?,
    platform: env.get_or("FACTORY_PLATFORM", "unknown")?,
    eval_id: env.get_or("FACTORY_EVAL_ID", "task-bigfiles")?,
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
