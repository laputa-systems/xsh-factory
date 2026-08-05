##! Package-owned evaluator for task-colsum.
##! This script owns the fixture, oracle, correctness, restriction, and
##! protocol checks; it must not delegate task logic to a legacy dispatcher.

type FixtureTable = {name: Str, data: Str}
type Case = {name: Str, header: Str, table: FixtureTable, expect_fail: Bool}

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
  for name in ["colsum.xsh", "review.md"] {
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

proc seed_table(root: Path, index: Int, table: FixtureTable) [fs, error] -> Result[Path] {
  fs.mkdir(root, parents: true)?
  let destination = fp"${root}/table-${index}.csv"
  fs.write(destination, table.data)?
  return destination
}

proc run_case(index: Int, case: Case, oracle: Path) [fs, process, time, error] -> Result[CaseResult] {
  let root = fp"/tmp/task-colsum-${index}"
  let table = seed_table(root, index, case.table)?
  let candidate_out = fp"/session/task-colsum-candidate-${index}.stdout"
  let candidate_err = fp"/session/task-colsum-candidate-${index}.stderr"
  let oracle_out = fp"/session/task-colsum-oracle-${index}.stdout"
  let oracle_err = fp"/session/task-colsum-oracle-${index}.stderr"
  for cleanup in [candidate_out, candidate_err, oracle_out, oracle_err] {
    fs.remove(cleanup, missing_ok: true)?
  }
  let shelf = table.display()
  let candidate_args = ["xsh", "/work/colsum.xsh", shelf, case.header]
  let oracle_args = ["sh", oracle.display(), shelf, case.header]
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
  let artifact = p"/work/colsum.xsh"
  let artifact_present = fs.exists(artifact)?
  let oracle = p"/tmp/task-colsum-oracle.sh"
  fs.write(oracle, r"""#!/bin/sh
file="$1"; header="$2"
col=$(awk -F, 'NR==1{for(i=1;i<=NF;i++) if($i==h){print i; exit}}' h="$header" "$file")
[ -n "$col" ] || exit 1
awk -F, -v c="$col" 'NR>1{if ($c !~ /^-?[0-9]+$/) {bad=1; exit 2} s+=$c} END{if(!bad) printf "%d\n", s}' "$file"
""")?
  fs.chmod(oracle, 0o755)?

  var all_exact = artifact_present
  var cases: List[CaseResult] = []
  if artifact_present {
    let inputs: List[Case] = [
      {name: "public", header: "age", table: {name: "t1", data: "name,age\nann,3\nbob,4\ncy,5\n"}, expect_fail: false},
      {name: "hidden_order", header: "score", table: {name: "t2", data: "score,name\n7,a\n8,b\n9,c\n"}, expect_fail: false},
      {name: "hidden_negative", header: "delta", table: {name: "t3", data: "delta,note\n-4,x\n10,y\n-6,z\n"}, expect_fail: false},
      {name: "hidden_many", header: "n", table: {name: "t4", data: "n\n1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n"}, expect_fail: false},
      {name: "hidden_single", header: "val", table: {name: "t5", data: "val,extra\n42,pad\n"}, expect_fail: false},
      {name: "hidden_no_data", header: "qty", table: {name: "t6", data: "qty\n"}, expect_fail: false},
      {name: "hidden_extra_cols", header: "mid", table: {name: "t7", data: "left,mid,right\n1,10,2\n3,20,4\n5,30,6\n"}, expect_fail: false},
      {name: "hidden_missing_header", header: "nope", table: {name: "t8", data: "a,b\n1,2\n3,4\n"}, expect_fail: true},
      {name: "hidden_bad_value", header: "num", table: {name: "t9", data: "num\n1\n2\nxyz\n4\n"}, expect_fail: true},
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
    (source.contains("fs.read_text") or source.contains(".read_text")) and
    source.contains("parse_int") and ! source_has_forbidden_subprocess(source)
  let protocol_ok = review_ok()?
  let passed = all_exact and restriction_ok and protocol_ok
  json.write(p"/session/run.json", {
    image_id: env.get_or("FACTORY_IMAGE_ID", "unknown")?,
    platform: env.get_or("FACTORY_PLATFORM", "unknown")?,
    eval_id: env.get_or("FACTORY_EVAL_ID", "task-colsum")?,
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
