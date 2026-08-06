##! Package-owned evaluator for task-propsort.
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
  let artifact = /work/propsort.xsh
  let input = /tmp/task-propsort-input
  let candidate_out = /session/candidate.stdout
  let oracle_out = /session/oracle.stdout
  fs.write(
    input,
    """  zebra  
# comment
	alpha	

 beta
""",
  )?
  let oracle = /tmp/task-propsort-oracle.sh
  fs.write(
    oracle,
    """sed 's/^[[:space:]]*//; s/[[:space:]]*$//' "$1" | grep -v '^#' | grep -v '^$' | LC_ALL=C sort
""",
  )?
  fs.chmod(oracle, 0o755)?
  let candidate = if fs.exists(artifact)? {
    process.run(
      process.command_argv(
        "xsh",
        ["xsh", artifact.display(), input.display()],
        stdout: candidate_out,
        stderr: /session/candidate.stderr,
      ),
    )?
  } else {
    process.run(process.command_argv("false", ["false"], stdout: candidate_out))?
  }
  let expected = process.run(
    process.command_argv(
      "sh",
      ["sh", oracle.display(), input.display()],
      stdout: oracle_out,
      stderr: /session/oracle.stderr,
    ),
  )?
  let exact = candidate.ok and expected.ok and candidate_out.read_text()? == oracle_out.read_text()?
  let source = if fs.exists(artifact)? { artifact.read_text()? } else { "" }
  let restriction_ok = "fs." in source and ! source_has_forbidden(source)
  let protocol_ok = review_ok()?
  let passed = exact and restriction_ok and protocol_ok
  json.write(
    /session/run.json,
    {
      eval_id: env.get_or("FACTORY_EVAL_ID", "task-propsort")?,
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
