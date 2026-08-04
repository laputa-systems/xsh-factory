##! Package-owned evaluator for task-keyjoin.

use factory_control as control

type Case = {name: Str, left: Str, right: Str}

type FixtureFiles = {left: Path, right: Path}

type CaseResult = {
  name: Str,
  exact: Bool,
  candidate_exit: Int,
  oracle_exit: Int,
  candidate_wall_ns: Int,
  oracle_wall_ns: Int,
}

proc copy_results() [fs, error] -> Result[Unit] {
  for name in ["keyjoin.xsh", "review.md"] {
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

proc write_fixtures(index: Int, case: Case) [fs, error] -> Result[FixtureFiles] {
  let dir = fp"/tmp/task-keyjoin-${index}"
  fs.mkdir(dir)?
  let left = fp"${dir}/left.txt"
  let right = fp"${dir}/right.txt"
  fs.write(left, case.left)?
  fs.write(right, case.right)?
  return {left: left, right: right}
}

proc run_case(index: Int, case: Case, oracle: Path) [fs, process, time, error] -> Result[CaseResult] {
  let files = write_fixtures(index, case)?
  fs.remove(fp"/session/task-keyjoin-candidate-${index}.stdout", missing_ok: true)?
  fs.remove(fp"/session/task-keyjoin-oracle-${index}.stdout", missing_ok: true)?
  let candidate = time.measure(process.command_argv(
    "xsh", ["xsh", "/work/keyjoin.xsh", files.left.display(), files.right.display()],
    stdout: fp"/session/task-keyjoin-candidate-${index}.stdout",
    stderr: fp"/session/task-keyjoin-candidate-${index}.stderr",
  ))?
  let oracle_result = time.measure(process.command_argv(
    "sh", ["sh", oracle.display(), files.left.display(), files.right.display()],
    stdout: fp"/session/task-keyjoin-oracle-${index}.stdout",
    stderr: fp"/session/task-keyjoin-oracle-${index}.stderr",
  ))?
  let candidate_text = if fs.exists(fp"/session/task-keyjoin-candidate-${index}.stdout")? {
    fs.read_text(fp"/session/task-keyjoin-candidate-${index}.stdout")?
  } else { "" }
  let oracle_text = if fs.exists(fp"/session/task-keyjoin-oracle-${index}.stdout")? {
    fs.read_text(fp"/session/task-keyjoin-oracle-${index}.stdout")?
  } else { "" }
  let exact = candidate.status.ok and oracle_result.status.ok and candidate_text == oracle_text
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
  let artifact = p"/work/keyjoin.xsh"
  let artifact_present = fs.exists(artifact)?
  let oracle = p"/tmp/task-keyjoin-oracle.sh"
  fs.write(oracle, r"""#!/bin/sh
grep -v '^[[:space:]]*#' "$1" | awk 'NF>=2{print $1"\t"$2}' | sort > /tmp/task-keyjoin-L
grep -v '^[[:space:]]*#' "$2" | awk 'NF>=2{print $1"\t"$2}' | sort > /tmp/task-keyjoin-R
join -a 1 -e - -o '1.1 1.2 2.2' /tmp/task-keyjoin-L /tmp/task-keyjoin-R
""")?
  fs.chmod(oracle, 0o755)?
  var all_exact = artifact_present
  var cases: List[CaseResult] = []
  if artifact_present {
    let inputs: List[Case] = [
      {name: "public", left: "alpha 10\nbeta 20\ngamma 30\n", right: "beta X\nepsilon Z\n"},
      {name: "hidden_comments", left: "# head\n  alpha   10  \n\nbeta 20\n   # indented\n   gamma   30\n", right: "\nbeta X\nbeta X\ngamma Y\n"},
      {name: "hidden_tabs", left: "alpha\t10\ndelta\t40\n", right: "delta\tY\nomega\tW\n"},
      {name: "hidden_left_only", left: "app one\nbee two\n", right: "zed nine\n"},
      {name: "hidden_right_extra", left: "app one\nbee two\n", right: "bee X\nother Z\n"},
      {name: "hidden_single", left: "solo 7\n", right: "solo hit\n"},
      {name: "hidden_empty_left", left: "", right: "beta X\n"},
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
  let restriction_ok = artifact_present and source.contains("read_text") and
    source.contains("Map[") and ! control.source_has_forbidden_subprocess(source)
  let protocol_ok = review_ok()?
  let passed = all_exact and restriction_ok and protocol_ok
  json.write(p"/session/run.json", {
    image_id: env.get_or("FACTORY_IMAGE_ID", "unknown")?,
    platform: env.get_or("FACTORY_PLATFORM", "unknown")?,
    eval_id: env.get_or("FACTORY_EVAL_ID", "task-keyjoin")?,
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
