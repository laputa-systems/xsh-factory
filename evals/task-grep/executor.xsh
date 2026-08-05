##! Thin task-grep selector for the shared eval executor.

proc main() [fs, process, env, time, error, io] {
  let factory_dir = env.path("FACTORY_DIR")?
  let xsh = process.which("xsh")?
  let common = fp"${factory_dir}/factory/entrypoints/eval-executor.xsh"
  let status = process.run(process.command_argv(
    xsh,
    [xsh.display(), common.display(), "--", "task-grep"],
  ))?
  abort(if status.ok { 0 } else { status.exit_code() ?? 1 })
}
