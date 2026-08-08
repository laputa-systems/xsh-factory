##! Package-owned evaluator for task-trim.
proc review_ok() [fs, error] -> Result[Bool] {
  let review = /work/review.md
  if ! fs.exists(review)? or fs.metadata(review)?.size == 0 {
    return false
  }

  let text = review.read_text()?
  return text.contains("## XSH language proposals") and text.contains("## xsht friction") and ! ("{{" in text)
}

pure source_uses_file_io(source: Str) -> Bool {
  let reads_file = "fs.read_text" in source or "fs.read_bytes" in source or ".read_text()" in source or ".read_bytes()" in source
  let writes_file = "fs.write" in source or ".write(" in source
  return reads_file and writes_file
}

proc main() [fs, process, env, time, error, io] {
  let artifact = /work/trim.xsh
  let input = /tmp/task-trim-input
  let output = /tmp/task-trim-output
  let expected = /tmp/task-trim-expected
  fs.write(
    input,
    """  alpha  
	 beta	
    
internal  spaces
""",
  )?
  fs.write(
    expected,
    """alpha
beta

internal  spaces
""",
  )?
  let candidate = if fs.exists(artifact)? {
    process.run(process.command_argv("xsh", ["xsh", artifact.display(), input.display(), output.display()]))?
  } else {
    process.run(process.command_argv("false", ["false"]))?
  }
  let source = if fs.exists(artifact)? { artifact.read_text()? } else { "" }
  let restriction_ok = source_uses_file_io(source) and ! ("process." in source) and ! ("spawn " in source)
  let exact = candidate.ok and fs.exists(output)? and output.read_text()? == expected.read_text()?
  let review = review_ok()?
  let passed = exact and restriction_ok and review
  json.write(
    /session/run.json,
    {
      eval_id: env.get_or("FACTORY_EVAL_ID", "task-trim")?,
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
