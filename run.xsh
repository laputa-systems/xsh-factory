##! Dispatches one complete Markdown-directed factory cycle.

use factory_control as control
use factory_runtime as runtime

on SIGINT --pre-cancel=0ms [fs, process, env, error] {
  runtime.cleanup_active_run()?
  abort(130)
}

on SIGTERM --pre-cancel=0ms [fs, process, env, error] {
  runtime.cleanup_active_run()?
  abort(143)
}

proc main(...argv: List[Str]) [fs, process, env, time, error, io] {
  if argv.len() < 1 {
    eprint "usage: xsh run.xsh CYCLE_REQUEST.md [EVAL_ID]"
    abort(2)
  }
  let factory_dir = env.path("FACTORY_DIR", fs.cwd()?)?
  let request = Path(argv[0])
  let mode = control.request_mode(request.read_text()?)
  let organization_marker = fp"${factory_dir}/runs/ORGANIZATION-ACTIVE"
  if fs.exists(organization_marker)? {
    eprint "an organization cycle is active; wait for it to finish or interrupt it"
    abort(1)
  }
  if mode != "ticket-implementation" and mode != "eval" and
    mode != "organization" and mode != "eval-design" {
    eprint f"unsupported cycle mode: ${mode}"
    abort(2)
  }
  let child = if mode == "ticket-implementation" {
    fp"${factory_dir}/run-ticket.xsh"
  } else if mode == "eval" {
    fp"${factory_dir}/run-eval.xsh"
  } else if mode == "organization" {
    fp"${factory_dir}/run-organization.xsh"
  } else {
    fp"${factory_dir}/run-design.xsh"
  }
  let xsh_path = process.which("xsh")?
  let status = process.run(process.command_argv(
    xsh_path,
    [xsh_path.display(), child.display(), "--"].extend(argv),
    cwd: factory_dir,
  ))?
  abort(if status.ok { 0 } else { status.exit_code() ?? 1 })
}
