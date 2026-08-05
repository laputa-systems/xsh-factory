##! Package-owned evaluator for task-render.

proc review_ok() [fs, error] -> Result[Bool] {
  let review = p"/work/review.md"
  if ! fs.exists(review)? or fs.metadata(review)?.size == 0 { return false }
  let text = review.read_text()?
  return text.contains("## XSH language proposals") and text.contains("## xsht friction") and ! text.contains("{{")
}

proc main() [fs, process, env, time, error, io] {
  let artifact = p"/work/render.xsh"
  let template = p"/tmp/task-render-template"
  let values = p"/tmp/task-render-values"
  let output = p"/tmp/task-render-output"
  let expected = p"/tmp/task-render-expected"
  fs.write(template, "hello @NAME@\nunknown @MISSING@\n")?
  fs.write(values, "NAME=world\n")?
  fs.write(expected, "hello world\nunknown @MISSING@\n")?
  let candidate = if fs.exists(artifact)? { process.run(process.command_argv("xsh", ["xsh", artifact.display(), template.display(), values.display(), output.display()]))? } else { process.run(process.command_argv("false", ["false"]))? }
  let source = if fs.exists(artifact)? { artifact.read_text()? } else { "" }
  let restriction_ok = source.contains("fs.") and ! source.contains("process.") and ! source.contains("spawn ")
  let exact = candidate.ok and fs.exists(output)? and output.read_text()? == expected.read_text()?
  let review = p"/work/review.md"
  let protocol_ok = fs.exists(review)? and review.read_text()?.contains("## XSH language proposals") and review.read_text()?.contains("## xsht friction")
  let passed = exact and restriction_ok and protocol_ok
  json.write(p"/session/run.json", {eval_id: env.get_or("FACTORY_EVAL_ID", "task-render")?, trial_id: env.get_or("FACTORY_TRIAL_ID", "1")?, result: if passed {"pass"} else {"fail"}, correctness: {exact: exact}, restrictions: {passed: restriction_ok}, protocol: {artifact_present: fs.exists(artifact)?, review_ok: protocol_ok}}, pretty: true)?
  if ! passed { abort(1) }
}
