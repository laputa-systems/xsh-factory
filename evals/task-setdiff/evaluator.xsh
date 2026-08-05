##! Package-owned evaluator for task-setdiff.

proc review_ok() [fs, error] -> Result[Bool] {
  let review = p"/work/review.md"
  if ! fs.exists(review)? or fs.metadata(review)?.size == 0 { return false }
  let text = review.read_text()?
  return text.contains("## XSH language proposals") and text.contains("## xsht friction") and ! text.contains("{{")
}

proc main() [fs, process, env, time, error, io] {
  let artifact = p"/work/setdiff.xsh"
  let first = p"/tmp/task-setdiff-a"
  let second = p"/tmp/task-setdiff-b"
  let output = p"/session/candidate.stdout"
  fs.write(first, "b\na\nc\na\n")?
  fs.write(second, "a\nc\n")?
  let candidate = if fs.exists(artifact)? { process.run(process.command_argv("xsh", ["xsh", artifact.display(), first.display(), second.display()], stdout: output, stderr: p"/session/candidate.stderr"))? } else { process.run(process.command_argv("false", ["false"], stdout: output))? }
  let expected = p"/session/expected.stdout"
  fs.write(expected, "b\n")?
  let source = if fs.exists(artifact)? { artifact.read_text()? } else { "" }
  let restriction_ok = source.contains("fs.") and (source.contains("set.") or source.contains("set.from")) and ! source.contains("process.") and ! source.contains("spawn ")
  let exact = candidate.status.ok and output.read_text()? == expected.read_text()?
  let review = review_ok()?
  let passed = exact and restriction_ok and review
  json.write(p"/session/run.json", {eval_id: env.get_or("FACTORY_EVAL_ID", "task-setdiff")?, trial_id: env.get_or("FACTORY_TRIAL_ID", "1")?, result: if passed {"pass"} else {"fail"}, correctness: {exact: exact}, restrictions: {passed: restriction_ok}, protocol: {artifact_present: fs.exists(artifact)?, review_ok: review}}, pretty: true)?
  if ! passed { abort(1) }
}
