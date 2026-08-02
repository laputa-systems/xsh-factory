##! Remove factory-generated run/build state without touching product branches.

proc active_marker_exists(runs: Path) [fs, error] -> Result[Bool] {
  if ! fs.exists(runs)? {
    return false
  }
  if fs.exists(fp"${runs}/ACTIVE")? or fs.exists(fp"${runs}/ORGANIZATION-ACTIVE")? {
    return true
  }
  for entry in fs.walk(runs, gitignore: false, hidden: true)? |> where .kind == "file" {
    if entry.name == "ACTIVE" or entry.name == "ORGANIZATION-ACTIVE" {
      return true
    }
  }
  return false
}

proc remove_run_worktrees(runs: Path, xsh_repo: Path) [fs, process, error] -> Result[Bool] {
  if ! fs.exists(runs)? {
    return true
  }
  for entry in fs.walk(runs, gitignore: false, hidden: true)? |> where .kind == "dir" and .name == "worktrees" {
    for child in fs.children(entry.path, stat: false, ordered: true)? {
      if child.kind != "dir" {
        continue
      }
      let status = process.run(process.command_argv(
        "git",
        ["git", "-C", xsh_repo.display(), "worktree", "remove", "--force", child.path.display()],
      ))?
      if ! status.ok and fs.exists(child.path)? {
        eprint f"unable to remove factory worktree: ${child.path.display()}"
        return false
      }
    }
  }
  let prune = process.run(process.command_argv(
    "git", ["git", "-C", xsh_repo.display(), "worktree", "prune"],
  ))?
  return prune.ok
}

proc remove_run_state(runs: Path) [fs, error] -> Result[Unit] {
  if ! fs.exists(runs)? {
    fs.mkdir(runs)?
    return Ok()
  }
  for child in fs.children(runs, stat: false, ordered: true)? {
    if child.name.starts_with("run-") or child.name == ".cache" or
      child.name == "eval-build.lock" or child.name == "factory.lock" or
      child.name == "ACTIVE" or child.name == "ORGANIZATION-ACTIVE" {
      fs.remove(child.path, missing_ok: true)?
    }
  }
  return Ok()
}

proc remove_build_staging(factory_dir: Path) [fs, error] -> Result[Unit] {
  let evals = fp"${factory_dir}/evals"
  if ! fs.exists(evals)? {
    return Ok()
  }
  let root_dist = fp"${evals}/.dist"
  fs.remove(root_dist, missing_ok: true)?
  for eval in fs.children(evals, stat: false, ordered: true)? {
    if eval.kind == "dir" {
      fs.remove(fp"${eval.path}/.dist", missing_ok: true)?
    }
  }
  return Ok()
}

proc main() [fs, process, env, error, io] {
  let factory_dir = env.path("FACTORY_DIR", fs.cwd()?)?
  let runs = fp"${factory_dir}/runs"
  if active_marker_exists(runs)? {
    eprint "cannot clean factory state while a run is active"
    abort(2)
  }
  let xsh_repo = env.path("FACTORY_XSH_REPO", fp"${factory_dir}/../xsh")?
  if ! fs.exists(xsh_repo)? {
    eprint f"XSH repository does not exist: ${xsh_repo.display()}"
    abort(2)
  }
  if ! remove_run_worktrees(runs, xsh_repo)? {
    abort(1)
  }
  remove_run_state(runs)?
  remove_build_staging(factory_dir)?
  print f"factory state cleared under ${factory_dir.display()}; product branches retained"
}
