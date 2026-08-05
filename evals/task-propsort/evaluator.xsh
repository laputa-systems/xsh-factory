##! Package-owned evaluator for task-propsort.

proc review_ok() [fs, error] -> Result[Bool] {
  let review = p"/work/review.md"
  if ! fs.exists(review)? or fs.metadata(review)?.size == 0 { return false }
  let text = review.read_text()?
  return text.contains("## XSH language proposals") and text.contains("## xsht friction") and ! text.contains("{{")
}

pure source_has_forbidden(source: Str) -> Bool {
  for line in source.lines() {
    let code = line.split("#").get(0, "")
    if code.contains("process.") or code.contains("spawn ") or code.contains("run ") { return true }
  }
  return false
}

proc main() [fs, process, env, time, error, io] {
  let artifact = p"/work/propsort.xsh"
  let input = p"/tmp/task-propsort-input"
  let candidate_out = p"/session/candidate.stdout"
  let oracle_out = p"/session/oracle.stdout"
  fs.write(input, "  zebra  \n# comment\n\talpha\t\n\n beta\n")?
  let oracle = p"/tmp/task-propsort-oracle.sh"
  fs.write(oracle, "sed 's/^[[:space:]]*//; s/[[:space:]]*$//' \"$1\" | grep -v '^#' | grep -v '^$' | LC_ALL=C sort\n")?
  fs.chmod(oracle, 0o755)?
  let candidate = if fs.exists(artifact)? { process.run(process.command_argv("xsh", ["xsh", artifact.display(), input.display()], stdout: candidate_out, stderr: p"/session/candidate.stderr"))? } else { process.run(process.command_argv("false", ["false"], stdout: candidate_out))? }
  let expected = process.run(process.command_argv("sh", ["sh", oracle.display(), input.display()], stdout: oracle_out, stderr: p"/session/oracle.stderr"))?
  let exact = candidate.ok and expected.ok and candidate_out.read_text()? == oracle_out.read_text()?
  let source = if fs.exists(artifact)? { artifact.read_text()? } else { "" }
  let restriction_ok = source.contains("fs.") and ! source_has_forbidden(source)
  let protocol_ok = review_ok()?
  let passed = exact and restriction_ok and protocol_ok
  json.write(p"/session/run.json", {eval_id: env.get_or("FACTORY_EVAL_ID", "task-propsort")?, trial_id: env.get_or("FACTORY_TRIAL_ID", "1")?, result: if passed {"pass"} else {"fail"}, correctness: {exact: exact}, restrictions: {passed: restriction_ok}, protocol: {artifact_present: fs.exists(artifact)?, review_ok: protocol_ok}}, pretty: true)?
  if ! passed { abort(1) }
}
