##! Package-owned evaluator for task-histogram.
##! This script owns the fixture, oracle, correctness, restriction, and
##! protocol checks; it must not delegate task logic to a legacy dispatcher.
type Case = {name: Str, width: Str, data: Str, expect_fail: Bool}

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
  for name in ["histogram.xsh", "review.md"] {
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

proc run_case(index: Int, case: Case, oracle: Path) [fs, process, time, error] -> Result[CaseResult] {
  let fixture = fp"/tmp/task-histogram-${index}.txt"
  let candidate_out = fp"/session/task-histogram-candidate-${index}.stdout"
  let candidate_err = fp"/session/task-histogram-candidate-${index}.stderr"
  let oracle_out = fp"/session/task-histogram-oracle-${index}.stdout"
  let oracle_err = fp"/session/task-histogram-oracle-${index}.stderr"
  for cleanup in [candidate_out, candidate_err, oracle_out, oracle_err] {
    fs.remove(cleanup, missing_ok: true)?
  }

  fs.write(fixture, case.data)?
  let candidate_args = ["xsh", "/work/histogram.xsh", fixture.display(), case.width]
  let oracle_args = ["sh", oracle.display(), fixture.display(), case.width]
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
  let artifact = /work/histogram.xsh
  let artifact_present = fs.exists(artifact)?
  let oracle = /tmp/task-histogram-oracle.sh
  fs.write(
    oracle,
    r"""#!/bin/sh
set -o pipefail
file="$1"; width="$2"
case "$width" in ''|*[!0-9]*) exit 1;; esac
[ "$width" -gt 0 ] 2>/dev/null || exit 1
awk -v w="$width" '
  NF==0 { next }
  { if ($1 !~ /^[0-9]+$/) { bad=1; exit 2 }
    b=int($1/w); c[b]++ }
  END { if (bad) exit 2; for (b in c) print b, c[b] }
' "$file" | sort -n -k1,1 | awk '{cum += $2; print $1 " " $2 " " cum}'
""",
  )?
  fs.chmod(oracle, 0o755)?

  var all_exact = artifact_present
  var cases: List[CaseResult] = []
  if artifact_present {
    let inputs: List[Case] = [
      {
        name: "public",
        width: "2",
        data: """0
1
2
3
4
""",
        expect_fail: false,
      },
      {
        name: "hidden_width",
        width: "3",
        data: """0
1
2
3
4
""",
        expect_fail: false,
      },
      {
        name: "hidden_many",
        width: "10",
        data: """5
9
10
15
19
20
25
29
30
""",
        expect_fail: false,
      },
      {
        name: "hidden_sparse",
        width: "10",
        data: """0
1000
100000
""",
        expect_fail: false,
      },
      {
        name: "hidden_single",
        width: "3",
        data: """7
""",
        expect_fail: false,
      },
      {
        name: "hidden_ties",
        width: "2",
        data: """0
1
2
3
""",
        expect_fail: false,
      },
      {
        name: "hidden_empty",
        width: "5",
        data: "",
        expect_fail: false,
      },
      {
        name: "hidden_bad_width",
        width: "0",
        data: """0
1
2
""",
        expect_fail: true,
      },
      {
        name: "hidden_bad_value",
        width: "5",
        data: """0
1
12x
3
""",
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
  let restriction_ok = artifact_present and ("fs.read_text" in source or ".read_text" in source) and "parse_int" in source and "sort-by" in source and ! source_has_forbidden_subprocess(
    source,
  )
  let protocol_ok = review_ok()?
  let passed = all_exact and restriction_ok and protocol_ok
  json.write(
    /session/run.json,
    {
      image_id: env.get_or("FACTORY_IMAGE_ID", "unknown")?,
      platform: env.get_or("FACTORY_PLATFORM", "unknown")?,
      eval_id: env.get_or("FACTORY_EVAL_ID", "task-histogram")?,
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
