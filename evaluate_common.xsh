##! Generic evaluator entrypoint. Eval packages provide evaluator.xsh; this
##! file owns only the dispatch boundary and never names an eval.

proc main(...argv: List[Str]) [fs, process, env, error, io] {
  let evaluator = env.path("FACTORY_EVAL_EVALUATOR", p"/run/evaluator.xsh")?
  if ! fs.exists(evaluator)? {
    eprint f"eval package is missing evaluator script: ${evaluator.display()}"
    abort(2)
  }
  let xsh = process.which("xsh")?
  let status = process.run(process.command_argv(
    xsh,
    [xsh.display(), evaluator.display()].extend(argv),
  ))?
  abort(if status.ok { 0 } else { status.exit_code() ?? 1 })
}
