##! Reconcile approved tickets against the current XSH repository.

use factory.runtime as runtime

proc main(...argv: List[Str]) [fs, process, env, error, io] {
  let factory_dir = env.path("FACTORY_DIR", fs.cwd()?)?
  let xsh_repo = env.path("FACTORY_XSH_REPO", fp"${factory_dir}/../xsh")?
  let retired = runtime.close_tickets_for_retired_evals(factory_dir)?
  let archived = runtime.archive_retired_ticket_branches(xsh_repo, factory_dir)?
  let xsh_commit = run.text "git" "-C" $xsh_repo.display() "rev-parse" "HEAD" ?
  let merged = runtime.reconcile_tickets(factory_dir, xsh_repo, xsh_commit.trim())?
  print f"reconciled ${merged.len()} merged ticket(s), closed ${retired.len()} retired-eval ticket(s), archived ${archived} branch(es) at ${xsh_commit.trim()}"
}
