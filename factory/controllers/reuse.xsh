##! Reuses one existing implementation branch without launching Pi.
use factory.runtime as runtime

type ReuseEvidence = {
  ready: Bool,
  worktree: Str,
  patch: Str,
  head: Str,
  merge_base: Str,
  clean: Bool,
}

proc prepare(
  phase_dir: Path,
  xsh_repo: Path,
  ticket_id: Str,
  branch: Str,
  base_commit: Str,
) [fs, process, error] -> Result[ReuseEvidence] {
  let worktree = runtime.ticket_worktree_path(xsh_repo, phase_dir, ticket_id)
  let patch_dir = fp"${phase_dir}/patches"
  let patch_path = fp"${patch_dir}/${ticket_id}.diff"
  let patch_stderr = fp"${patch_dir}/${ticket_id}.stderr"
  fs.mkdir(worktree.parent())?
  fs.mkdir(patch_dir)?
  let add_status = process.run(
    process.command_argv(
      "git",
      [
        "git",
        "-C",
        xsh_repo.display(),
        "worktree",
        "add",
        "--detach",
        worktree.display(),
        branch,
      ],
      stdout: fp"${phase_dir}/worktree.stdout",
      stderr: fp"${phase_dir}/worktree.stderr",
    ),
  )?
  var head = ""
  var merge_base = ""
  var clean = false
  var patch_ok = false
  if add_status.ok {
    head = run.text "git" "-C" $worktree "rev-parse" "HEAD" ?
    merge_base = run.text "git" "-C" $xsh_repo "merge-base" $base_commit $branch ?
    let status = run.text "git" "-C" $worktree "status" "--porcelain" ?
    clean = status.trim() == ""
    patch_ok = merge_base.trim() != "" and head.trim() != base_commit.trim() and runtime.write_engineer_patch(
      worktree,
      merge_base.trim(),
      head.trim(),
      patch_path,
      patch_stderr,
    )?
  }

  return {
    ready: add_status.ok and clean and patch_ok,
    worktree: worktree.display(),
    patch: patch_path.display(),
    head: head.trim(),
    merge_base: merge_base.trim(),
    clean: clean,
  }
}

proc write_report(phase_dir: Path, ticket_id: Str, branch: Str, base_commit: Str, evidence: ReuseEvidence) [fs, error] {
  let result = if evidence.ready { "pass" } else { "fail" }
  json.write(
    fp"${phase_dir}/report.json",
    {
      schema_version: 1,
      kind: "phase",
      identity: {
        run_id: phase_dir.name(),
        mode: "ticket-reuse",
        ticket_id: ticket_id,
      },
      state: "completed",
      result: result,
      data: {
        mode: "ticket-reuse",
        ticket_id: ticket_id,
        branch: branch,
        base_commit: base_commit.trim(),
        merge_base: evidence.merge_base,
        implementation_commit: evidence.head,
        worktree: evidence.worktree,
        patch: evidence.patch,
        clean: evidence.clean,
      },
      findings: [],
      artifacts: [
        {
          kind: "portable-patch",
          path: evidence.patch,
        },
      ],
    },
    pretty: true,
  )?
}

proc main(...argv: List[Str]) [fs, process, env, error, io] {
  if argv.len() != 0 {
    eprint "factory/controllers/reuse.xsh takes its inputs from the controller environment"
    abort(2)
  }

  let phase_dir = env.path("FACTORY_PHASE_DIR")?
  let factory_dir = env.path("FACTORY_DIR")?
  let expected_source_sha = env.get_or("FACTORY_SOURCE_SHA", "")?
  if expected_source_sha != "" and ! runtime.verify_factory_source(factory_dir, expected_source_sha)? {
    eprint "factory source changed before ticket reuse admission"
    abort(1)
  }
  let xsh_repo = env.path("FACTORY_XSH_REPO")?
  let ticket_id = env.get("FACTORY_TICKET_ID")?
  let branch = env.get("FACTORY_TICKET_BRANCH")?
  let base_commit = env.get("FACTORY_XSH_COMMIT")?
  let evidence = prepare(phase_dir, xsh_repo, ticket_id, branch, base_commit)?
  write_report(phase_dir, ticket_id, branch, base_commit, evidence)?
  let result = if evidence.ready { "pass" } else { "fail" }
  print f"ticket reuse: ${ticket_id} (${result})"
  abort(if evidence.ready { 0 } else { 1 })
}
