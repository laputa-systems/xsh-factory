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

type StreamStageDiagnostic = {
  required: Bool,
  passed: Bool,
  filter_exit: Int,
  where_check_exit: Int,
  where_lint_exit: Int,
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

## Ticket task-histogram-006 changes a product diagnostic, so its linked replay
## must exercise that diagnostic instead of inferring success from the ordinary
## histogram artifact. The probe also protects the documented where spelling.
proc run_filter_stage_diagnostic() [fs, process, error] -> Result[StreamStageDiagnostic] {
  let filter_probe = /tmp/task-histogram-filter-stage.xsh
  let where_probe = /tmp/task-histogram-where-stage.xsh
  let filter_stdout = /session/task-histogram-filter-stage.stdout
  let filter_stderr = /session/task-histogram-filter-stage.stderr
  let where_check_stdout = /session/task-histogram-where-check.stdout
  let where_check_stderr = /session/task-histogram-where-check.stderr
  let where_lint_stdout = /session/task-histogram-where-lint.stdout
  let where_lint_stderr = /session/task-histogram-where-lint.stderr
  fs.write(
    filter_probe,
    """let values = ["alpha", ""]
let filtered = values |> filter { |value| value != "" } |> collect()
print filtered.len()
""",
  )?
  fs.write(
    where_probe,
    """let values = ["alpha", ""]
let filtered = values |> where { |value| value != "" } |> collect()
print filtered.len()
""",
  )?
  let filter = process.run(
    process.command_argv(
      "xsht",
      ["xsht", "check", filter_probe.display()],
      stdout: filter_stdout,
      stderr: filter_stderr,
    ),
  )?
  let where_check = process.run(
    process.command_argv(
      "xsht",
      ["xsht", "check", where_probe.display()],
      stdout: where_check_stdout,
      stderr: where_check_stderr,
    ),
  )?
  let where_lint = process.run(
    process.command_argv(
      "xsht",
      ["xsht", "lint", where_probe.display()],
      stdout: where_lint_stdout,
      stderr: where_lint_stderr,
    ),
  )?
  let filter_output = if fs.exists(filter_stdout)? { filter_stdout.read_text()? } else { "" }
  let filter_errors = if fs.exists(filter_stderr)? { filter_stderr.read_text()? } else { "" }
  let filter_text = filter_output + filter_errors
  let names_stage = "filter" in filter_text and "where" in filter_text
  let avoids_literal_cascade = "expected record field" not in filter_text and "expected } after record" not in filter_text
  let filter_exit = if filter.ok { 0 } else { filter.exit_code() ?? 1 }
  let where_check_exit = if where_check.ok { 0 } else { where_check.exit_code() ?? 1 }
  let where_lint_exit = if where_lint.ok { 0 } else { where_lint.exit_code() ?? 1 }
  return {
    required: true,
    passed: ! filter.ok and names_stage and avoids_literal_cascade and where_check.ok and where_lint.ok,
    filter_exit: filter_exit,
    where_check_exit: where_check_exit,
    where_lint_exit: where_lint_exit,
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
file="$1"; width=$(printf '%s' "$2" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
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
        name: "hidden_padded_width",
        width: " 5 ",
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
  let typed_file_read = "fs.read_text" in source or ".read_text" in source
  let typed_integer_parse = "parse_int" in source or "parse_uint" in source
  let sorted_stream = "sort-by" in source
  let forbidden_subprocess = source_has_forbidden_subprocess(source)
  let restriction_ok = artifact_present and typed_file_read and typed_integer_parse and sorted_stream and ! forbidden_subprocess
  let protocol_ok = review_ok()?
  let diagnostic = if env.get_or("FACTORY_REEVAL_TICKET", "")? == "task-histogram-006" {
    run_filter_stage_diagnostic()?
  } else {
    {
      required: false,
      passed: true,
      filter_exit: -1,
      where_check_exit: -1,
      where_lint_exit: -1,
    }
  }
  let passed = all_exact and restriction_ok and protocol_ok and diagnostic.passed
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
      } else if ! diagnostic.passed {
        "diagnostic_failed"
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
        typed_file_read: typed_file_read,
        typed_integer_parse: typed_integer_parse,
        sorted_stream: sorted_stream,
        forbidden_subprocess: forbidden_subprocess,
      },
      diagnostic: {
        required: diagnostic.required,
        passed: diagnostic.passed,
        filter_exit: diagnostic.filter_exit,
        where_check_exit: diagnostic.where_check_exit,
        where_lint_exit: diagnostic.where_lint_exit,
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
