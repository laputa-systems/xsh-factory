##! Package-owned evaluator for task-setdiff.
proc review_ok() [fs, error] -> Result[Bool] {
  let review = /work/review.md
  if ! fs.exists(review)? or fs.metadata(review)?.size == 0 {
    return false
  }
  let text = review.read_text()?
  return text.contains("## XSH language proposals") and text.contains("## xsht friction") and ! ("{{" in text)
}

proc main() [fs, process, env, time, error, io] {
  let artifact = /work/setdiff.xsh
  let first = /tmp/task-setdiff-a
  let second = /tmp/task-setdiff-b
  let output = /session/candidate.stdout
  fs.write(
    first,
    """b
a
c
a
""",
  )?
  fs.write(
    second,
    """a
c
""",
  )?
  let candidate = if fs.exists(artifact)? {
    process.run(
      process.command_argv(
        "xsh",
        ["xsh", artifact.display(), first.display(), second.display()],
        stdout: output,
        stderr: /session/candidate.stderr,
      ),
    )?
  } else {
    process.run(process.command_argv("false", ["false"], stdout: output))?
  }
  let expected = /session/expected.stdout
  fs.write(
    expected,
    """b
""",
  )?
  let source = if fs.exists(artifact)? { artifact.read_text()? } else { "" }
  let restriction_ok = "fs." in source and ("set." in source or "set.from" in source) and ! ("process." in source) and ! ("spawn " in source)
  let exact = candidate.ok and output.read_text()? == expected.read_text()?
  let review = review_ok()?
  let passed = exact and restriction_ok and review
  json.write(
    /session/run.json,
    {
      eval_id: env.get_or("FACTORY_EVAL_ID", "task-setdiff")?,
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
        review_ok: review,
      },
    },
    pretty: true,
  )?
  if ! passed {
    abort(1)
  }
}
