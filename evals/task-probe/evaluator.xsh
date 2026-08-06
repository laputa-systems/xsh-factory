##! Task-probe package-owned evaluator implementation.
##! Runs the candidate and the external BusyBox/POSIX oracle for the public and
##! hidden cases in the same environment, checks the process-boundary
##! restriction and review.md protocol, and writes a JSON run manifest.
##!
##! The controller mounts the worker workspace at /work and the writable
##! evidence directory at /session.
type Case = {name: Str, args: List[Str]}

type CaseResult = {
  name: Str,
  candidate_exit: Int,
  oracle_exit: Int,
  matched: Bool,
  candidate_duration_ms: Int,
  oracle_duration_ms: Int,
}

proc failed_result(case: Case) [] -> CaseResult {
  return {
    name: case.name,
    candidate_exit: -1,
    oracle_exit: -1,
    matched: false,
    candidate_duration_ms: 0,
    oracle_duration_ms: 0,
  }
}

proc run_case(xsh: Path, artifact: Path, oracle: Path, case: Case) [fs, process, time, error] -> CaseResult {
  let cand_out = /tmp/task-probe-cand.out
  let cand_err = /tmp/task-probe-cand.err
  let orac_out = /tmp/task-probe-orac.out
  let orac_err = /tmp/task-probe-orac.err
  let cand_command = process.command_argv(
    xsh,
    [xsh.display(), artifact.display()].extend(case.args),
    stdout: cand_out,
    stderr: cand_err,
    timeout: 10s,
  )
  let orac_command = process.command_argv(
    /bin/sh,
    [p"/bin/sh".display(), oracle.display()].extend(case.args),
    stdout: orac_out,
    stderr: orac_err,
    timeout: 10s,
  )
  match time.measure(cand_command) {
    Ok(cand) => {
      match time.measure(orac_command) {
        Ok(orac) => {
          let cand_text = cand_out.read_text() ?? ""
          let orac_text = orac_out.read_text() ?? ""
          let matched = cand_text == orac_text and (cand.status.exit_code() ?? -1) == (orac.status.exit_code() ?? -1)
          return {
            name: case.name,
            candidate_exit: cand.status.exit_code() ?? -1,
            oracle_exit: orac.status.exit_code() ?? -1,
            matched: matched,
            candidate_duration_ms: cand.duration_ms,
            oracle_duration_ms: orac.duration_ms,
          }
        }
        Err(_) => return failed_result(case)
      }
    }
    Err(_) => return failed_result(case)
  }
}

proc main(..._: List[Str]) [fs, process, env, time, error, io] {
  let work_dir = /work
  let manifest_path = /session/run.json
  let xsh = process.which("xsh")?
  let artifact = fp"${work_dir}/probe.xsh"
  let review = fp"${work_dir}/review.md"
  let oracle = /tmp/task-probe-oracle.sh

  if ! fs.exists(artifact)? {
    eprint "task-probe evaluation failed: probe.xsh missing"
    abort(1)
  }

  if ! fs.exists(review)? {
    eprint "task-probe evaluation failed: review.md missing"
    abort(1)
  }

  let source = artifact.read_text()?
  let has_process = "process." in source or "run " in source or "spawn" in source
  let review_text = review.read_text()?
  let review_ok = "## XSH language proposals" in review_text and "## xsht friction" in review_text and "{{" not in review_text

  fs.write(
    oracle,
    """#!/bin/sh
if command -v "$1" >/dev/null 2>&1; then
  "$@"
  code=$?
  if [ "$code" -eq 0 ]; then
    echo ok
  else
    echo "fail:$code"
  fi
else
  echo missing
fi
""",
  )?
  fs.chmod(oracle, 0o755)?

  let cases = [
    {
      name: "public_ok",
      args: [
        "true",
      ],
    },
    {
      name: "hidden_fail1",
      args: [
        "false",
      ],
    },
    {
      name: "hidden_fail42",
      args: [
        "sh",
        "-c",
        "exit 42",
      ],
    },
    {
      name: "hidden_missing",
      args: [
        "definitely-not-a-real-command-xyz",
      ],
    },
    {
      name: "hidden_two_words",
      args: [
        "sh",
        "-c",
        "printf '%s\\n' 'two words'",
      ],
    },
    {
      name: "hidden_hello_world",
      args: [
        "printf",
        "%s\\n",
        "hello world",
      ],
    },
    {
      name: "hidden_empty_arg",
      args: [
        "sh",
        "-c",
        "exit 0",
        "",
      ],
    },
    {
      name: "hidden_exact_join",
      args: [
        "printf",
        "ready",
      ],
    },
    {
      name: "hidden_stderr_exit5",
      args: [
        "sh",
        "-c",
        "echo err >&2; exit 5",
      ],
    },
  ]

  let results = cases
    |> map { |case|
      run_case(xsh, artifact, oracle, case)
    }
    |> collect()

  var all_ok = true
  for r in results {
    if ! r.matched {
      all_ok = false
    }
  }

  let classification = if has_process and review_ok and all_ok { "pass" } else { "fail" }
  let report = {
    eval: "task-probe",
    classification: classification,
    cases: results,
    restriction_ok: has_process,
    review_ok: review_ok,
    protocol: "complete",
  }
  json.write(manifest_path, report, pretty: true)?

  if classification == "pass" {
    print "task-probe evaluation passed"
    abort(0)
  } else {
    eprint "task-probe evaluation failed: see "${manifest_path}
    abort(1)
  }
}
