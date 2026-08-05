##! Package-owned evaluator for task-trim.

proc review_ok() [fs, error] -> Result[Bool] {
  let review = p"/work/review.md"
  if ! fs.exists(review)? or fs.metadata(review)?.size == 0 { return false }
  let text = review.read_text()?
  return text.contains("## XSH language proposals") and text.contains("## xsht friction") and ! text.contains("{{")
}

proc main() [fs, process, env, time, error, io] {
  let artifact = p"/work/trim.xsh"
  let input = p"/tmp/task-trim-input"
  let output = p"/tmp/task-trim-output"
  let expected = p"/tmp/task-trim-expected"
  fs.write(input, "  alpha  \n\t beta\t\n    \ninternal  spaces\n")?
  fs.write(expected, "alpha\nbeta\n\ninternal  spaces\n")?
  let candidate = if fs.exists(artifact)? { process.run(process.command_argv("xsh", ["xsh", artifact.display(), input.display(), output.display()]))? } else { process.run(process.command_argv("false", ["false"]))? }
  let source = if fs.exists(artifact)? { artifact.read_text()? } else { "" }
  let restriction_ok = source.contains("fs.") and ! source.contains("process.") and ! source.contains("spawn ")
  let exact = candidate.status.ok and fs.exists(output)? and output.read_text()? == expected.read_text()?
  let review = review_ok()?
  let passed = exact and restriction_ok and review
  json.write(p"/session/run.json", {eval_id: env.get_or("FACTORY_EVAL_ID", "task-trim")?, trial_id: env.get_or("FACTORY_TRIAL_ID", "1")?, result: if passed {"pass"} else {"fail"}, correctness: {exact: exact}, restrictions: {passed: restriction_ok}, protocol: {artifact_present: fs.exists(artifact)?, review_ok: review}}, pretty: true)?
  if ! passed { abort(1) }
}
