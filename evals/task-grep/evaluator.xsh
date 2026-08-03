##! Package-owned evaluator for task-grep.
##! Runs the candidate and an external BusyBox `grep -nF` oracle against a set
##! of public and hidden cases, checks the no-subprocess restriction and the
##! review.md protocol, and writes a JSON run manifest to the session run.json.
##! The workspace and session roots default to /work and /session (the eval
##! container contract, which must exist) but may be overridden via environment
##! variables for a host-side dry run.
type Fixture = {name: Str, pattern: Str, data: Str, missing: Bool}

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
proc source_has_forbidden_subprocess(source: Str) [] -> Bool {
  for line in source.lines() {
    let code = line.split("#").get(0, "")
    if code.contains("process.") or code.contains("spawn ") or code.contains("run ") {
      return true
    }
  }

  return false
}

proc copy_results(work_root: Path, session_root: Path) [fs, error] -> Result[Unit] {
  for name in ["grep.xsh", "review.md"] {
    let source = fp"${work_root}/${name}"
    if fs.exists(source)? {
      fs.copy(source, fp"${session_root}/export/${name}", overwrite: true)?
    }
  }

  return Ok()
}

proc review_ok(work_root: Path) [fs, error] -> Result[Bool] {
  let review = fp"${work_root}/review.md"
  if ! fs.exists(review)? or fs.metadata(review)?.size == 0 {
    return false
  }

  let text = review.read_text()?
  return text.contains("## XSH language proposals") and text.contains("## xsht friction") and ! text.contains("{{")
}

proc run_case(
  index: Int,
  work_root: Path,
  session_root: Path,
  case: Fixture,
) [fs, process, time, error] -> Result[CaseResult] {
  let input = fp"${session_root}/data-${index}.txt"
  let candidate_out = fp"${session_root}/candidate-${index}.stdout"
  let candidate_err = fp"${session_root}/candidate-${index}.stderr"
  let oracle_out = fp"${session_root}/oracle-${index}.stdout"
  let oracle_err = fp"${session_root}/oracle-${index}.stderr"
  for cleanup in [input, candidate_out, candidate_err, oracle_out, oracle_err] {
    if fs.exists(cleanup)? {
      fs.remove(cleanup)?
    }
  }

  if ! case.missing {
    fs.write(input, case.data)?
  }

  let artifact = fp"${work_root}/grep.xsh"
  let candidate = time.measure(
    process.command_argv(
      "xsh",
      ["xsh", artifact.display(), case.pattern, input.display()],
      stdout: candidate_out,
      stderr: candidate_err,
    ),
  )?
  let oracle = time.measure(
    process.command_argv(
      "sh",
      ["sh", "-c", "LC_ALL=C grep -nF \"$1\" \"$2\"", "grep-oracle", case.pattern, input.display()],
      stdout: oracle_out,
      stderr: oracle_err,
    ),
  )?
  let candidate_text = if fs.exists(candidate_out)? { candidate_out.read_text()? } else { "" }
  let oracle_text = if fs.exists(oracle_out)? { oracle_out.read_text()? } else { "" }
  let candidate_ok = candidate.status.ok
  let oracle_ok = oracle.status.ok
  let stdout_match = candidate_text == oracle_text
  let exact = if case.missing {
    stdout_match and ! candidate_ok and ! oracle_ok
  } else {
    stdout_match and candidate_ok
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
  let work_root = Path(env.get_or("FACTORY_WORK", "/work")?)
  let session_root = Path(env.get_or("FACTORY_SESSION", "/session")?)
  let artifact = fp"${work_root}/grep.xsh"
  let artifact_present = fs.exists(artifact)?
  var all_exact = artifact_present
  var cases: List[CaseResult] = []
  if artifact_present {
    let inputs: List[Fixture] = [
      {
        name: "public",
        pattern: "quick",
        data: """the quick brown
quick fox
QUICK
""",
        missing: false,
      },
      {
        name: "hidden_empty_pattern",
        pattern: "",
        data: """aa
bb
cc
""",
        missing: false,
      },
      {
        name: "hidden_no_match",
        pattern: "zzz",
        data: """aa
bb
cc
""",
        missing: false,
      },
      {
        name: "hidden_case",
        pattern: "Fox",
        data: """fox
Fox
FOX
""",
        missing: false,
      },
      {
        name: "hidden_regex_literal",
        pattern: "a.c",
        data: """a.c
aXc
abc
""",
        missing: false,
      },
      {
        name: "hidden_spaces",
        pattern: "foo",
        data: "  foo  \nfoo\n foo\n",
        missing: false,
      },
      {
        name: "hidden_blank_lines",
        pattern: "",
        data: """a

b

""",
        missing: false,
      },
      {
        name: "hidden_unicode",
        pattern: "\u{e9}",
        data: """café
élan
elan
""",
        missing: false,
      },
      {
        name: "hidden_missing",
        pattern: "x",
        data: "",
        missing: true,
      },
    ]
    var index = 0
    for case in inputs {
      index += 1
      let result = run_case(index, work_root, session_root, case)?
      cases = cases.push(result)
      if ! result.exact {
        all_exact = false
      }
    }
  }

  let source = if artifact_present { artifact.read_text()? } else { "" }
  let restriction_ok = artifact_present and source.contains("read_text") and ! source_has_forbidden_subprocess(source)
  let protocol_ok = review_ok(work_root)?
  let passed = all_exact and restriction_ok and protocol_ok
  json.write(
    fp"${session_root}/run.json",
    {
      image_id: env.get_or("FACTORY_IMAGE_ID", "unknown")?,
      platform: env.get_or("FACTORY_PLATFORM", "unknown")?,
      eval_id: env.get_or("FACTORY_EVAL_ID", "task-grep")?,
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
  let _ = copy_results(work_root, session_root)?
  if ! passed {
    abort(1)
  }
}
