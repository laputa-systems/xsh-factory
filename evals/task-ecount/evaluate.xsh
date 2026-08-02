##! Thin task-ecount selector for the shared evaluator.

proc main() [fs, process, env, time, error, io] {
  let xsh = process.which("xsh")?
  let common = p"/usr/local/lib/xsh-factory/evaluate_common.xsh"
  let status = process.run(process.command_argv(
    xsh,
    [xsh.display(), common.display(), "--", "task-ecount"],
  ))?
  abort(if status.ok { 0 } else { status.exit_code() ?? 1 })
}
