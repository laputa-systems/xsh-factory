##! Reconcile accepted tickets against the current XSH repository.

use factory_runtime as runtime

proc main(...argv: List[Str]) [fs, process, env, error, io] {
  let factory_dir = env.path("FACTORY_DIR", fs.cwd()?)?
  let xsh_repo = env.path("FACTORY_XSH_REPO", fp"${factory_dir}/../xsh")?
  let xsh_commit = run.text "git" "-C" $xsh_repo.display() "rev-parse" "HEAD" ?
  let merged = runtime.reconcile_tickets(factory_dir, xsh_repo, xsh_commit.trim())?
  print f"reconciled ${merged.len()} merged ticket(s) at ${xsh_commit.trim()}"
}
