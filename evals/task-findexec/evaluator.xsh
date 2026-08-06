##! Package-owned evaluator for task-findexec.
proc review_ok() [fs, error] -> Result[Bool] {
  let review = /work/review.md
  if ! fs.exists(review)? or fs.metadata(review)?.size == 0 {
    return false
  }

  let text = review.read_text()?
  return text.contains("## XSH language proposals") and text.contains("## xsht friction") and ! ("{{" in text)
}

pure source_has_forbidden(source: Str) -> Bool {
  for line in source.lines() {
    let code = line.split("#").get(0, "")
    if "process." in code or "spawn " in code or "run " in code {
      return true
    }
  }

  return false
}

proc main() [fs, process, env, time, error, io] {
  let artifact = /work/findexec.xsh
  let root = /tmp/task-findexec-root
  let candidate_out = /session/candidate.stdout
  let oracle_out = /session/oracle.stdout
  fs.mkdir(/tmp/task-findexec-root/nested)?
  fs.write(
    /tmp/task-findexec-root/owner,
    """owner
""",
  )?
  fs.write(
    /tmp/task-findexec-root/nested/owner-hidden,
    """hidden
""",
  )?
  fs.write(
    /tmp/task-findexec-root/group-only,
    """group
""",
  )?
  let setup = process.run(
    process.command_argv(
      "chmod",
      ["chmod", "755", p"/tmp/task-findexec-root/owner".display(), p"/tmp/task-findexec-root/nested/owner-hidden".display()],
    ),
  )?
  let oracle = /tmp/task-findexec-oracle.sh
  fs.write(
    oracle,
    """find "$1" -type f -perm -u+x | sort
""",
  )?
  fs.chmod(oracle, 0o755)?
  let candidate = if fs.exists(artifact)? {
    process.run(
      process.command_argv(
        "xsh",
        ["xsh", artifact.display(), root.display()],
        stdout: candidate_out,
        stderr: /session/candidate.stderr,
      ),
    )?
  } else {
    process.run(process.command_argv("false", ["false"], stdout: candidate_out))?
  }
  let expected = process.run(
    process.command_argv("sh", ["sh", oracle.display(), root.display()], stdout: oracle_out, stderr: /session/oracle.stderr),
  )?
  let exact = setup.ok and candidate.ok and expected.ok and candidate_out.read_text()? == oracle_out.read_text()?
  let source = if fs.exists(artifact)? { artifact.read_text()? } else { "" }
  let restriction_ok = "fs." in source and ! source_has_forbidden(source)
  let protocol_ok = review_ok()?
  let passed = exact and restriction_ok and protocol_ok
  json.write(
    /session/run.json,
    {
      eval_id: env.get_or("FACTORY_EVAL_ID", "task-findexec")?,
      trial_id: env.get_or("FACTORY_TRIAL_ID", "1")?,
      result: if passed { "pass" } else { "fail" },
      correctness: {
        exact: exact,
      },
      restrictions: {
        passed: restriction_ok,
      },
      protocol: {
        artifact_present: fs.exists(artifact)?,
        review_ok: protocol_ok,
      },
    },
    pretty: true,
  )?
  if ! passed {
    abort(1)
  }
}
