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
      continue when child.kind != "dir"
      let status = process.run(
        process.command_argv(
          "git",
          ["git", "-C", xsh_repo.display(), "worktree", "remove", "--force", child.path.display()],
        ),
      )?
      if ! status.ok and fs.exists(child.path)? {
        eprint f"unable to remove factory worktree: ${child.path.display()}"
        return false
      }
    }
  }

  let prune = process.run(
    process.command_argv(
      "git",
      ["git", "-C", xsh_repo.display(), "worktree", "prune"],
    ),
  )?
  return prune.ok
}

proc remove_run_state(runs: Path, cutoff_ms: Int) [fs, error] -> Result[Int] {
  if ! fs.exists(runs)? {
    fs.mkdir(runs)?
    return 0
  }

  var removed = 0
  for child in fs.children(runs, stat: false, ordered: true)? {
    if child.name.starts_with("run-") {
      let modified = fs.metadata(child.path)?.modified
      if modified < cutoff_ms {
        fs.remove(child.path, missing_ok: true)?
        removed += 1
      }
    } else if child.name == ".cache" or child.name == "eval-build.lock" or child.name == "factory.lock" or child.name == "organization.lock" or child.name == "ACTIVE" or child.name == "ORGANIZATION-ACTIVE" {
      fs.remove(child.path, missing_ok: true)?
    }
  }

  return removed
}

proc remove_build_staging(factory_dir: Path) [fs, error] {
  let evals = fp"${factory_dir}/evals"
  if ! fs.exists(evals)? {
    return
  }

  let root_dist = fp"${evals}/.dist"
  fs.remove(root_dist, missing_ok: true)?
  for eval in fs.children(evals, stat: false, ordered: true)? {
    if eval.kind == "dir" {
      fs.remove(fp"${eval.path}/.dist", missing_ok: true)?
    }
  }
}

proc main(...argv: List[Str]) [fs, process, env, time, error, io] {
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

  let age_days = if argv.len() > 0 { argv[0].parse_int()? } else { 3 }
  if age_days < 1 {
    eprint "run age must be at least one day"
    abort(2)
  }

  let cutoff = time.now() - age_days * 86400
  let removed = remove_run_state(runs, cutoff)?
  remove_build_staging(factory_dir)?
  print f"factory state cleared under ${factory_dir.display()}; removed ${removed} run(s) older than ${age_days} day(s); product branches retained"
}
