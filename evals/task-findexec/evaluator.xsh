##! Task-findexec evaluator package implementation.

proc main(...argv: List[Str]) [fs, process, env, time, error, io] {
  let xsh = process.which("xsh")?
  let legacy = p"/usr/local/lib/xsh-factory/evaluate_legacy.xsh"
  let status = process.run(process.command_argv(
    xsh, [xsh.display(), legacy.display(), "--", "task-findexec"].extend(argv)
  ))?
  abort(if status.ok { 0 } else { status.exit_code() ?? 1 })
}
