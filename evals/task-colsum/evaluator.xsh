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
    if "process." in code or "spawn " in code or "run " in code {
      return true
    }
  }

  return false
}

proc copy_results() [fs, error] {
  for name in ["colsum.xsh", "review.md"] {
    let source = fp"/work/${name}"
    if fs.exists(source)? {
      fs.copy(source, fp"/export/${name}", overwrite: true)?
    }
  }
}

proc review_ok() [fs, error] -> Result[Bool] {
  let review = /work/review.md
  if ! fs.exists(review)? or fs.metadata(review)?.size == 0 {
    return false
  }

  let text = review.read_text()?
  return text.contains("## XSH language proposals") and text.contains("## xsht friction") and ! ("{{" in text)
}

proc seed_table(root: Path, index: Int, table: FixtureTable) [fs, error] -> Result[Path] {
  fs.mkdir(root)?
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
  let candidate = time.measure(
    process.command_argv(
      "xsh",
      candidate_args,
      stdout: candidate_out,
      stderr: candidate_err,
    ),
  )?
  let oracle_result = time.measure(
    process.command_argv(
      "sh",
      oracle_args,
      stdout: oracle_out,
      stderr: oracle_err,
    ),
  )?
  let candidate_text = if fs.exists(candidate_out)? { candidate_out.read_text()? } else { "" }
  let oracle_text = if fs.exists(oracle_out)? { oracle_out.read_text()? } else { "" }
  let exact = if case.expect_fail {
    ! candidate.status.ok and ! oracle_result.status.ok and candidate_text == "" and oracle_text == ""
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
  let artifact = /work/colsum.xsh
  let artifact_present = fs.exists(artifact)?
  let oracle = /tmp/task-colsum-oracle.sh
  fs.write(
    oracle,
    r"""#!/bin/sh
file="$1"; header="$2"
col=$(awk -F, 'NR==1{for(i=1;i<=NF;i++) if($i==h){print i; exit}}' h="$header" "$file")
[ -n "$col" ] || exit 1
awk -F, -v c="$col" 'NR>1{if ($c !~ /^-?[0-9]+$/) {bad=1; exit 2} s+=$c} END{if(!bad) printf "%d\n", s}' "$file"
""",
  )?
  fs.chmod(oracle, 0o755)?

  var all_exact = artifact_present
  var cases: List[CaseResult] = []
  if artifact_present {
    let inputs: List[Case] = [
      {
        name: "public",
        header: "age",
        table: {
          name: "t1",
          data: """name,age
ann,3
bob,4
cy,5
""",
        },
        expect_fail: false,
      },
      {
        name: "hidden_order",
        header: "score",
        table: {
          name: "t2",
          data: """score,name
7,a
8,b
9,c
""",
        },
        expect_fail: false,
      },
      {
        name: "hidden_negative",
        header: "delta",
        table: {
          name: "t3",
          data: """delta,note
-4,x
10,y
-6,z
""",
        },
        expect_fail: false,
      },
      {
        name: "hidden_many",
        header: "n",
        table: {
          name: "t4",
          data: """n
1
2
3
4
5
6
7
8
9
10
""",
        },
        expect_fail: false,
      },
      {
        name: "hidden_single",
        header: "val",
        table: {
          name: "t5",
          data: """val,extra
42,pad
""",
        },
        expect_fail: false,
      },
      {
        name: "hidden_no_data",
        header: "qty",
        table: {
          name: "t6",
          data: """qty
""",
        },
        expect_fail: false,
      },
      {
        name: "hidden_extra_cols",
        header: "mid",
        table: {
          name: "t7",
          data: """left,mid,right
1,10,2
3,20,4
5,30,6
""",
        },
        expect_fail: false,
      },
      {
        name: "hidden_missing_header",
        header: "nope",
        table: {
          name: "t8",
          data: """a,b
1,2
3,4
""",
        },
        expect_fail: true,
      },
      {
        name: "hidden_bad_value",
        header: "num",
        table: {
          name: "t9",
          data: """num
1
2
xyz
4
""",
        },
        expect_fail: true,
      },
    ]
    var index = 0
    for case in inputs {
      index += 1
      let result = run_case(index, case, oracle)?
      cases = cases.push(result)
      if ! result.exact {
        all_exact = false
      }
    }
  }

  let source = if artifact_present { artifact.read_text()? } else { "" }
  let restriction_ok = artifact_present and ("fs.read_text" in source or ".read_text" in source) and "parse_int" in source and ! source_has_forbidden_subprocess(
    source,
  )
  let protocol_ok = review_ok()?
  let passed = all_exact and restriction_ok and protocol_ok
  json.write(
    /session/run.json,
    {
      image_id: env.get_or("FACTORY_IMAGE_ID", "unknown")?,
      platform: env.get_or("FACTORY_PLATFORM", "unknown")?,
      eval_id: env.get_or("FACTORY_EVAL_ID", "task-colsum")?,
      trial_id: env.get_or("FACTORY_TRIAL_ID", "1")?,
      result: if passed { "pass" } else { "fail" },
      classification: if ! artifact_present {
        "worker_missing_artifact"
      } else if ! protocol_ok {
        "protocol_failed"
      } else if ! restriction_ok {
        "restriction_failed"
      } else if ! all_exact {
        "candidate_failed"
      } else {
        "pass"
      },
      protocol: {
        artifact_present: artifact_present,
        review_ok: protocol_ok,
      },
      correctness: {
        cases: cases,
        all_exact: all_exact,
        passed: all_exact,
      },
      restrictions: {
        passed: restriction_ok,
      },
      timings: {
        passed: true,
      },
    },
    pretty: true,
  )?
  if ! passed {
    abort(1)
  }
}
