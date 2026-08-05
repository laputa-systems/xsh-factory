##! Print or persist the deterministic CTO pre-cycle inventory.

use factory.runtime as runtime

proc main(...argv: List[Str]) [fs, process, env, error, io] {
  let factory_dir = env.path("FACTORY_DIR", fs.cwd()?)?
  let xsh_repo = env.path("FACTORY_XSH_REPO", fp"${factory_dir}/../xsh")?
  if argv.len() > 2 or (argv.len() == 1 and argv[0] != "--run-dir") or
    (argv.len() == 2 and argv[0] != "--run-dir") {
    eprint "usage: xsh factory/tools/cto.xsh [--run-dir RUN_DIR]"
    abort(2)
  }
  let tickets = runtime.cto_ticket_inventory(factory_dir, xsh_repo)?
  var markdown = runtime.cto_inventory_markdown(tickets)
  let stale = runtime.stale_ticket_branches(xsh_repo, factory_dir)?
  markdown = markdown + f"\n- Stale branch candidates: ${stale.len()}\n"
  for branch in stale {
    markdown = markdown + f"- `${branch.branch}` (${branch.ticket_status}; merged=${branch.merged})\n"
  }
  if argv.len() == 2 {
    let run_dir = Path(argv[1])
    let retired = runtime.retire_stale_ticket_branches(xsh_repo, factory_dir)?
    fs.mkdir(run_dir)?
    runtime.write_cto_inventory(factory_dir, run_dir, xsh_repo)?
    print f"CTO inventory written to ${run_dir.display()} (retired ${retired} stale branch(es))"
  } else {
    print $markdown
  }
}
