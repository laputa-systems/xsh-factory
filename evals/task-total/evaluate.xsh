##! Package evaluator entrypoint. Task logic lives in this eval package.
proc main(...argv: List[Str]) [fs, process, env, time, error, io] {
  let xsh = process.which("xsh")?
  let status = process.run(
    process.command_argv(
      xsh,
      [xsh.display(), "/run/evaluator.xsh"].extend(argv),
    ),
  )?
  abort(if status.ok { 0 } else { status.exit_code() ?? 1 })
}
