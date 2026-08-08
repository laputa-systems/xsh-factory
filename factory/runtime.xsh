##! Shared process-boundary helpers for every factory cycle mode.
use factory.control as control
use factory.schema as schema

error RuntimeError = InvalidTransition(subject: Str, current: Str, next: Str) : InvalidData

type MergeEvidence = {
  merged: Bool,
  ticket_id: Str,
  branch: Str,
  implementation_commit: Str,
  source_run: Str,
  detected_xsh_commit: Str,
}

## One ticket whose implementation commit is already in XSH HEAD.
export type MergedTicket = {
  ticket_id: Str,
  eval_id: Str,
  branch: Str,
  implementation_commit: Str,
  source_run: Str,
  detected_xsh_commit: Str,
}

## The exact product branch and provenance commit eligible for organization
## delivery. A false result is normal controller state: the branch and its
## evidence remain available for CTO inspection and a later reuse cycle.
export type DeliveryEvidence = {
  merged: Bool,
  ticket_id: Str,
  branch: Str,
  implementation_commit: Str,
}

## Terminates all registered children of the active run.
export proc cleanup_active_run() [fs, process, env, error] -> Result[Unit] {
  let configured_factory = env.get_or("FACTORY_DIR", "")?
  let factory_dir = if configured_factory == "" { fs.cwd()? } else { fp"${configured_factory}" }
  let default_active_run = fp"${factory_dir}/runs/ACTIVE"
  let configured_active_run = env.path("FACTORY_ACTIVE_RUN", default_active_run)?
  let organization_run = fp"${factory_dir}/runs/ORGANIZATION-ACTIVE"
  let active_marker = if fs.exists(configured_active_run)? {
    configured_active_run
  } else if fs.exists(organization_run)? {
    organization_run
  } else {
    default_active_run
  }
  if ! fs.exists(active_marker)? {
    return
  }

  let run_text = fs.read_text(active_marker)?.trim()
  if run_text != "" {
    let xsh_path = process.which("xsh")?
    let self_pid = process.current_pid()?
    let cleanup = fp"${factory_dir}/factory/tools/cleanup-run.xsh"
    let _ = process.run(
      process.command_argv(
        xsh_path,
        [xsh_path.display(), cleanup.display(), "--", run_text, "--exclude-pid", f"${self_pid}"],
      ),
    )?
  }
}

## Registers a controller so cleanup covers phase and top-level processes alike.
export proc register_cycle_controller(run_dir: Path) [fs, process, env, error] -> Result[Unit] {
  let processes = fp"${run_dir}/processes"
  fs.mkdir(processes)?
  let pid = process.current_pid()?
  fs.write_atomic(
    fp"${processes}/controller.pids",
    f"""${pid}
""",
  )?
  let source_sha = env.get_or("FACTORY_SOURCE_SHA", "")?
  if source_sha != "" {
    fs.write_atomic(fp"${run_dir}/factory-source.sha256", source_sha + "\n")?
  }
}

## Writes one controller-owned host-agent dispatch record.
export proc write_dispatch_record(
  run_dir: Path,
  role: Str,
  worker_id: Str,
  message_file: Path,
  workdir: Path,
  mode: Str,
  eval_id: Str,
  ticket_id: Str,
  assignment_sha: Str,
) [fs, error] -> Result[Unit] {
  fs.mkdir(fp"${run_dir}/dispatch")?
  let message_sha = hash.sha256(message_file)?.hex()
  json.write(
    fp"${run_dir}/dispatch/${role}-${worker_id}.json",
    {
      schema_version: 1,
      role: role,
      worker_id: worker_id,
      message_file: message_file.display(),
      message_sha256: message_sha,
      workdir: workdir.display(),
      mode: mode,
      eval_id: eval_id,
      ticket_id: ticket_id,
      assignment_sha256: assignment_sha,
    },
    pretty: true,
  )?
}

## Writes the canonical controller-bound dispatch identity used by migrated
## launchers. The legacy writer above remains only for old synthetic fixtures.
export proc write_bound_dispatch_record(
  factory_dir: Path,
  run_dir: Path,
  role: Str,
  worker_id: Str,
  system_prompt: Path,
  message_file: Path,
  workdir: Path,
  mode: Str,
  eval_id: Str,
  ticket_id: Str,
  assignment_sha: Str,
) [fs, error] -> Result[Unit] {
  if ! fs.exists(system_prompt)? or ! fs.exists(message_file)? {
    return Err(
      RuntimeError.InvalidTransition(
        subject: f"${role}/${worker_id}",
        current: "missing-input",
        next: "planned",
      ),
    )
  }

  let canonical_factory = factory_dir.resolve()?
  let canonical_run = run_dir.resolve()?
  let canonical_prompt = system_prompt.resolve()?
  let canonical_message = message_file.resolve()?
  let canonical_workdir = workdir.resolve()?
  fs.mkdir(fp"${canonical_run}/dispatch")?
  let dispatch_id = f"${role}-${worker_id}"
  let prompt_sha = hash.sha256(system_prompt)?.hex()
  let message_sha = hash.sha256(message_file)?.hex()
  let claim_token = if assignment_sha != "" { assignment_sha } else { message_sha }
  let phase_name = run_dir.name()
  let parent_name = run_dir.parent().name()
  let bound_run_id = if parent_name.starts_with("run-") { parent_name } else { phase_name }
  let bound_phase_id = if parent_name.starts_with("run-") { phase_name } else { "root" }
  let dispatch_path = fp"${canonical_run}/dispatch/${dispatch_id}.json"
  if fs.exists(dispatch_path)? {
    return Err(
      RuntimeError.InvalidTransition(
        subject: dispatch_id,
        current: "planned",
        next: "replaced",
      ),
    )
  }

  json.write(
    dispatch_path,
    {
      schema_version: 2,
      state: "planned",
      run_id: bound_run_id,
      phase_id: bound_phase_id,
      node_id: dispatch_id,
      dispatch_id: dispatch_id,
      role: role,
      worker_id: worker_id,
      mode: mode,
      eval_id: eval_id,
      ticket_id: ticket_id,
      assignment_sha256: assignment_sha,
      system_prompt_file: canonical_prompt.display(),
      system_prompt_sha256: prompt_sha,
      message_file: canonical_message.display(),
      message_sha256: message_sha,
      workdir: canonical_workdir.display(),
      factory_root: canonical_factory.display(),
      product_root: canonical_workdir.display(),
      handbook_file: fp"${canonical_factory}/runtime/handbook.md".display(),
      handbook_sha256: if fs.exists(fp"${factory_dir}/runtime/handbook.md")? {
        hash.sha256(fp"${factory_dir}/runtime/handbook.md")?.hex()
      } else {
        "missing"
      },
      north_star_file: fp"${canonical_factory}/NORTH-STAR.md".display(),
      north_star_sha256: if fs.exists(fp"${factory_dir}/NORTH-STAR.md")? {
        hash.sha256(fp"${factory_dir}/NORTH-STAR.md")?.hex()
      } else {
        "missing"
      },
      source_commit: "controller-selected",
      image_id: "not-applicable",
      parent_controller: "controller",
      claim_token: claim_token,
    },
    pretty: true,
  )?
}

## Registers a controller-owned child before waiting on it.
export proc register_process(run_dir: Path, name: Str, pid: Int) [fs, error] -> Result[Unit] {
  let processes = fp"${run_dir}/processes"
  fs.mkdir(processes)?
  fs.write_atomic(
    fp"${processes}/${name}.pids",
    f"""${pid}
""",
  )?
}

## Starts the one aggregate watcher owned by a top-level cycle controller.
export proc start_cycle_budget_watch(
  factory_dir: Path,
  run_dir: Path,
) [fs, process, env, error] -> Result[ProcessHandle] {
  let requested = env.get_or("FACTORY_CYCLE_BUDGET_USD", control.default_cycle_budget())?
  let budget = control.clamp_cycle_budget(requested)?
  let xsh = process.which("xsh")?
  let env_path = process.which("env")?
  let watcher = fp"${factory_dir}/factory/tools/cycle-budget-watch.xsh"
  let marker = fp"${run_dir}/AGGREGATE-BUDGET-BREACH"
  let stop = fp"${run_dir}/AGGREGATE-BUDGET-STOP"
  let postmortem = fp"${run_dir}/POSTMORTEM.md"
  let controller_pid = process.current_pid()?
  let module_path = env.get_or("XSH_MODULE_PATH", factory_dir.display())?
  let assignments = [
    "FACTORY_DIR=" + factory_dir.display(),
    "XSH_MODULE_PATH=" + module_path,
  ]
  let command = assignments.extend(
    [
      xsh.display(),
      watcher.display(),
      "--",
      "--run-dir",
      run_dir.display(),
      "--pid",
      f"${controller_pid}",
      "--budget-usd",
      budget,
      "--marker",
      marker.display(),
      "--stop",
      stop.display(),
      "--postmortem",
      postmortem.display(),
    ],
  )
  return spawn process.command_argv(
    env_path,
    [env_path.display()].extend(command),
    cwd: factory_dir,
    stdout: fp"${run_dir}/cycle-budget-watch.stdout",
    stderr: fp"${run_dir}/cycle-budget-watch.stderr",
  )
}

## Requests a clean watcher exit after a controller completes normally.
export proc stop_cycle_budget_watch(run_dir: Path) [fs, error] -> Result[Unit] {
  fs.write_atomic(
    fp"${run_dir}/AGGREGATE-BUDGET-STOP",
    """normal controller shutdown
""",
  )?
}

## Stages the CTO handoff in every controller-owned run directory.
## The CTO fills this checked-in template after reviewing the evidence; the
## controller must never leave a completed run without the handoff artifact.
export proc stage_cto_improvement(factory_dir: Path, run_dir: Path) [fs, error] -> Result[Unit] {
  let target = fp"${run_dir}/CTO-IMPROVEMENT.md"
  if ! fs.exists(target)? {
    fs.copy(fp"${factory_dir}/templates/CTO-IMPROVEMENT.md", target, overwrite: true)?
  }
}

## Stages the mandatory organization-cycle productivity review.
export proc stage_cto_productivity_report(factory_dir: Path, run_dir: Path) [fs, error] -> Result[Unit] {
  let target = fp"${run_dir}/CTO-PRODUCTIVITY-REPORT.md"
  if ! fs.exists(target)? {
    fs.copy(fp"${factory_dir}/templates/CTO-PRODUCTIVITY-REPORT.md", target, overwrite: true)?
  }
}

## Writes the deterministic first-pass briefing used by the CTO.
export proc write_cto_report(factory_dir: Path, run_dir: Path, result: Str) [fs, process, error] -> Result[Bool] {
  let xsh = process.which("xsh")?
  let tool = fp"${factory_dir}/factory/tools/cto-report.xsh"
  let output = fp"${run_dir}/CTO-REPORT.md"
  let status = process.run(
    process.command_argv(
      xsh,
      [
        xsh.display(),
        tool.display(),
        "--",
        "--run-dir",
        run_dir.display(),
        "--output",
        output.display(),
        "--result",
        result,
      ],
      cwd: factory_dir,
      env: {FACTORY_DIR: factory_dir.display(), XSH_MODULE_PATH: factory_dir.display()},
    ),
  )?
  return status.ok and fs.exists(output)?
}

## Promotes one materialized eval proposal after the CTO review, setting
## Approved. only for an accepted package and never overwriting an existing
## checked-in eval. Older proposals may be incomplete; their missing package
## files are recorded in
## the checked-in contract and keep them out of paid admission.
export proc promote_eval_proposal(
  factory_dir: Path,
  proposal_dir: Path,
  run_dir: Path,
  review_result: Str,
) [fs, error] -> Result[Bool] {
  let contract = fp"${proposal_dir}/EVAL.md"
  if ! fs.exists(contract)? {
    return false
  }

  let eval_text = contract.read_text()?
  if control.ticket_status(eval_text) != "Draft." {
    return false
  }

  let eval_id = control.eval_id_from_contract(eval_text)
  if ! control.valid_eval_id(eval_id) {
    return false
  }

  let target = fp"${factory_dir}/evals/${eval_id}"
  if fs.exists(target)? {
    return false
  }

  let package_files = [
    "EVAL.md",
    "executor.xsh",
    "evaluate.xsh",
    "runtime/task.md",
    "runtime/artifact.md",
  ]
  for relative in package_files {
    if ! fs.exists(fp"${proposal_dir}/${relative}")? {
      return false
    }
  }

  let optional_files = ["evaluator.xsh", "Dockerfile"]
  fs.mkdir(target)?
  fs.mkdir(fp"${target}/runtime")?
  for relative in package_files {
    let source = fp"${proposal_dir}/${relative}"
    let destination = fp"${target}/${relative}"
    fs.copy(source, destination, overwrite: false)?
  }

  for relative in optional_files {
    let source = fp"${proposal_dir}/${relative}"
    if fs.exists(source)? {
      fs.copy(source, fp"${target}/${relative}", overwrite: false)?
    }
  }

  let source_run = control.factory_relative_path(factory_dir.display(), run_dir)
  let package_state = if fs.exists(fp"${proposal_dir}/evaluator.xsh")? { "complete" } else { "incomplete" }
  let missing = if package_state == "complete" { "None." } else { "evaluator.xsh (package-owned evaluator)" }
  let status = if review_result == "accepted" { "Approved." } else { "Draft." }
  let updated_contract = control.replace_eval_status(fs.read_text(fp"${target}/EVAL.md")?, status)
  let review = """
## CTO review

- Result: `""" + review_result + """`
- Promotion: `promoted`
- Package: `""" + package_state + """`
- Missing package files: `""" + missing + """`
- Status: `""" + status + """`
- Source run: `""" + source_run + """`
"""
  fs.write_atomic(fp"${target}/EVAL.md", updated_contract + review)?
  return true
}

## Amends a validated engineer commit with deterministic factory provenance.
## The caller must verify the report, branch, commit, and clean worktree first.
## Updates the controller-owned engineer report after commit amendment.
export proc update_engineer_report_commit(report_path: Path, commit_hash: Str) [fs, error] -> Result[Bool] {
  if ! fs.exists(report_path)? {
    return false
  }

  let report = report_path.read_text()?
  if control.report_field(report, "Commit") == "" {
    return false
  }

  let updated = control.replace_section(
    report,
    "Commit",
    """## Commit

""" + commit_hash.trim(),
  )
  fs.write_atomic(report_path, updated)?
  return control.engineer_report_contract_ok(updated)
}

proc provenance_trailers_ok(worktree: Path, commit: Str, expected: List[Str]) [process, error] -> Result[Bool] {
  let text = run.text "git" "-C" $worktree "show" "-s" "--format=%(trailers)" commit.trim() ?
  for value in expected {
    if value not in text {
      return false
    }
  }

  return true
}

## Amends a validated engineer commit with deterministic factory provenance.
## The caller must verify the report, branch, commit, and clean worktree first.
export proc amend_engineer_commit(
  worktree: Path,
  head_commit: Str,
  factory_dir: Path,
  run_dir: Path,
  report_path: Path,
  session_path: Path,
  ticket_id: Str,
  branch: Str,
  base_commit: Str,
  assignment_sha: Str,
  patch_sha: Str,
) [fs, process, error] -> Result[Str] {
  let current_head = run.text "git" "-C" $worktree "rev-parse" "HEAD" ?
  let worktree_status = run.text "git" "-C" $worktree "status" "--porcelain" ?
  if current_head.trim() != head_commit.trim() or worktree_status.trim() != "" {
    return Ok("")
  }

  let commit_id = head_commit.trim()
  if commit_id == "" {
    return Ok("")
  }
  let existing_output = run.text "git" "-C" $worktree "log" "-1" "--format=%B" $commit_id ?
  let existing_message = existing_output.trim()
  if "Factory-Provenance-Version:" in existing_message {
    return Ok(head_commit.trim())
  }

  if ! fs.exists(report_path)? or ! fs.exists(session_path)? {
    return Ok("")
  }

  let report = json.read(report_path)?
  let usage = json.get(report, ["usage"], null)
  let models = json.get(report, ["models"], [])
  let model_ref = match models {
    values is List[Any] => if values.len() > 0 { report_value(values[0]) } else { "unknown" },
    _ => "unknown",
  }
  let model_parts = model_ref.split("/", maxsplit: 1)
  let provider = if model_parts.len() > 1 { model_parts[0] } else { "unknown" }
  let model = if model_parts.len() > 1 {
    model_ref.byte_slice(provider.byte_len() + 1, model_ref.byte_len() - provider.byte_len() - 1)
  } else {
    model_ref
  }
  let report_sha = hash.sha256(report_path)?.hex()
  let session_sha = hash.sha256(session_path)?.hex()
  let relative_report = control.factory_relative_path(factory_dir.display(), report_path)
  let relative_session = control.factory_relative_path(factory_dir.display(), session_path)
  let relative_run = control.factory_relative_path(factory_dir.display(), run_dir)
  var trailers = [
    f"Factory-Provenance-Version: 1",
    f"Factory-Run: ${relative_run}",
    "Factory-Role: engineer",
    f"Factory-Ticket: ${ticket_id}",
    f"Factory-Branch: ${branch}",
    f"Factory-Base-Commit: ${base_commit.trim()}",
    f"Factory-Source-Commit: ${head_commit.trim()}",
    f"Factory-Provider: ${provider}",
    f"Factory-Assignment-SHA256: ${assignment_sha}",
    f"Factory-Patch-SHA256: ${patch_sha}",
    f"Factory-Model: ${model}",
    f"Factory-Assistant-Turns: ${report_value(json.get(usage, ["assistant_turns"], 0))}",
    f"Factory-Tool-Calls: ${report_value(json.get(usage, ["tool_calls"], 0))}",
    f"Factory-Tool-Errors: ${report_value(json.get(usage, ["tool_errors"], 0))}",
    f"Factory-Thinking-Blocks: ${report_value(json.get(usage, ["thinking_blocks"], 0))}",
    f"Factory-Reasoning-Tokens: ${report_value(json.get(usage, ["reasoning_tokens"], "unknown"))}",
    f"Factory-Token-Buckets: ${report_value(json.get(usage, ["total_bucket_tokens"], 0))}",
    f"Factory-Input-Tokens: ${report_value(json.get(usage, ["input_tokens"], 0))}",
    f"Factory-Output-Tokens: ${report_value(json.get(usage, ["output_tokens"], 0))}",
    f"Factory-Cache-Read-Tokens: ${report_value(json.get(usage, ["cache_read_tokens"], 0))}",
    f"Factory-Cache-Write-Tokens: ${report_value(json.get(usage, ["cache_write_tokens"], 0))}",
    f"Factory-Cost-USD: ${report_value(json.get(usage, ["cost_usd"], "unknown"))}",
    f"Factory-Session-Wall-Ms: ${report_value(json.get(report, ["timing", "session_span_ms"], 0))}",
    f"Factory-Report-SHA256: ${report_sha}",
    f"Factory-Session-SHA256: ${session_sha}",
    f"Factory-Worker-Report: ${relative_report}",
    f"Factory-Session: ${relative_session}",
  ]
  var git_args: List[Str] = [
    "git",
    "-C",
    worktree.display(),
    "commit",
    "--amend",
    "--no-edit",
    "--no-verify",
  ]
  for trailer in trailers {
    git_args = git_args.push("--trailer").push(trailer)
  }

  let status = process.run(process.command_argv("git", git_args))?
  if ! status.ok {
    return Ok("")
  }

  let amended_head = run.text "git" "-C" $worktree "rev-parse" "HEAD" ?
  let amended = amended_head.trim()
  let expected = [
    "Factory-Provenance-Version: 1",
    f"Factory-Source-Commit: ${head_commit.trim()}",
    f"Factory-Report-SHA256: ${report_sha}",
    f"Factory-Assignment-SHA256: ${assignment_sha}",
    f"Factory-Patch-SHA256: ${patch_sha}",
    f"Factory-Session-SHA256: ${session_sha}",
  ]
  if ! provenance_trailers_ok(worktree, amended, expected)? {
    return Ok("")
  }

  amended
}

pure report_value(value: Any) -> Str {
  match value {
    s is Str => return s
    i is Int => return f"${i}"
    f is Float => return f.format(precision: 9)
    b is Bool => return if b { "true" } else { "false" }
    _ => return "unknown"
  }
}

## Captures the committed engineer change as a portable patch before any worktree cleanup.
export proc write_engineer_patch(
  worktree: Path,
  base_commit: Str,
  head_commit: Str,
  patch_path: Path,
  stderr_path: Path,
) [fs, process, error] -> Result[Bool] {
  let status = process.run(
    process.command_argv(
      "git",
      [
        "git",
        "-C",
        worktree.display(),
        "diff",
        "--binary",
        "--no-ext-diff",
        f"${base_commit}..${head_commit}",
      ],
      stdout: patch_path,
      stderr: stderr_path,
    ),
  )?
  if ! status.ok or ! fs.exists(patch_path)? {
    return false
  }

  return fs.metadata(patch_path)?.size > 0
}

## Computes the scratch root for a ticket worktree outside the factory checkout.
export pure ticket_worktree_root(xsh_repo: Path, phase_dir: Path) -> Path {
  let run_root = if phase_dir.name().starts_with("run-") { phase_dir } else { phase_dir.parent().parent() }
  return fp"${xsh_repo.parent()}/.xsh-factory-worktrees/${run_root.name()}"
}

## Computes one controller-owned ticket worktree outside the factory checkout.
export pure ticket_worktree_path(xsh_repo: Path, phase_dir: Path, ticket_id: Str) -> Path {
  return fp"${ticket_worktree_root(xsh_repo, phase_dir)}/${ticket_id}"
}

## Removes a clean temporary worktree while leaving its review branch intact.
export proc remove_clean_worktree(xsh_repo: Path, worktree: Path) [fs, process, error] -> Result[Bool] {
  if ! fs.exists(worktree)? {
    return true
  }

  let status = process.run(
    process.command_argv(
      "git",
      ["git", "-C", xsh_repo.display(), "worktree", "remove", worktree.display()],
    ),
  )?
  return status.ok and ! fs.exists(worktree)?
}

## Force-removes only worktrees owned by one completed or interrupted run.
## Branches, patches, reports, and other run evidence remain intact.
export proc remove_run_worktrees(xsh_repo: Path, run_dir: Path) [fs, process, error] -> Result[Bool] {
  if ! fs.exists(run_dir)? {
    return true
  }

  var removed = true
  for entry in fs.walk(run_dir, gitignore: false, hidden: true)? |> where .kind == "dir" and .name == "worktrees" {
    for child in fs.children(entry.path, stat: false, ordered: true)? {
      continue when child.kind != "dir"
      let status = process.run(
        process.command_argv(
          "git",
          ["git", "-C", xsh_repo.display(), "worktree", "remove", "--force", child.path.display()],
        ),
      )?
      if ! status.ok and fs.exists(child.path)? {
        removed = false
        eprint f"unable to remove run worktree: ${child.path.display()}"
      }
    }
  }

  let scratch_root = if run_dir.name().starts_with("run-") {
    fp"${xsh_repo.parent()}/.xsh-factory-worktrees/${run_dir.name()}"
  } else {
    ticket_worktree_root(xsh_repo, run_dir)
  }
  if fs.exists(scratch_root)? {
    for child in fs.children(scratch_root, stat: false, ordered: true)? {
      continue when child.kind != "dir"
      let status = process.run(
        process.command_argv(
          "git",
          ["git", "-C", xsh_repo.display(), "worktree", "remove", "--force", child.path.display()],
        ),
      )?
      if ! status.ok and fs.exists(child.path)? {
        removed = false
      }
    }
  }

  let prune = process.run(
    process.command_argv(
      "git",
      ["git", "-C", xsh_repo.display(), "worktree", "prune"],
    ),
  )?
  return removed and prune.ok
}

## Deferred-cleanup adapter for controller shutdown paths.
export proc cleanup_run_worktrees(xsh_repo: Path, run_dir: Path) [fs, process, error] -> Result[Unit] {
  let _ = remove_run_worktrees(xsh_repo, run_dir)?
}

## Writes one event and advances its subject state atomically.
export proc emit_structured_event(
  _: Path,
  run_dir: Path,
  name: Str,
  subject: Str,
  payload: Any,
) [fs, error] -> Result[Unit] {
  let events = fp"${run_dir}/events.jsonl"
  let existing = if fs.exists(events)? { fs.read_text(events)? } else { "" }
  let event = {
    schema_version: 1,
    kind: "event",
    event_id: name,
    run_id: run_dir.display(),
    subject: subject,
    payload: payload,
  }
  fs.write_atomic(events, existing + json.encode(event)? + "\n")?
}

## Writes one event and advances its subject state atomically.
export proc emit_event(
  template: Path,
  run_dir: Path,
  name: Str,
  subject: Str,
  state: Str,
  attempt: Int,
  caused_by: Str,
  detail: Str,
) [fs, error] -> Result[Unit] {
  let events = fp"${run_dir}/events.jsonl"
  let states = fp"${run_dir}/states"
  let state_file = fp"${states}/${subject}.state"
  fs.mkdir(run_dir)?
  fs.mkdir(states)?
  let current = if fs.exists(state_file)? { fs.read_text(state_file)?.trim() } else { "created" }
  if ! control.transition_allowed(current, state) {
    return Err(RuntimeError.InvalidTransition(subject: subject, current: current, next: state))
  }

  let _ = template
  let event = {
    schema_version: 1,
    kind: "event",
    event_id: name,
    run_id: run_dir.display(),
    subject: subject,
    state: state,
    attempt: attempt,
    caused_by: caused_by,
    detail: detail,
  }
  let existing = if fs.exists(events)? { fs.read_text(events)? } else { "" }
  fs.write_atomic(events, existing + json.encode(event)? + "\n")?
  fs.write_atomic(state_file, state + "\n")?
}

## Appends one complete process stream to the canonical cycle ledger. The
## source file remains as optional forensic storage; event consumers do not
## need to chase stdout/stderr paths to reconstruct a controller outcome.
export proc emit_process_output(
  run_dir: Path,
  process_id: Str,
  output_stream: Str,
  output: Path,
  exit_code: Int,
) [fs, error] -> Result[Unit] {
  let events = fp"${run_dir}/events.jsonl"
  let content = if fs.exists(output)? { fs.read_text(output)? } else { "" }
  let event = {
    schema_version: 1,
    kind: "process-output",
    event_id: f"${process_id}:${output_stream}",
    run_id: run_dir.display(),
    subject: process_id,
    state: "completed",
    channel: output_stream,
    exit_code: exit_code,
    content: content,
  }
  let existing = if fs.exists(events)? { fs.read_text(events)? } else { "" }
  fs.write_atomic(events, existing + json.encode(event)? + "\n")?
}

## Advances an audited started phase to completed before later validation.
export proc mark_phase_completed(
  template: Path,
  run_dir: Path,
  name: Str,
  subject: Str,
  attempt: Int,
  caused_by: Str,
  detail: Str,
) [fs, error] -> Result[Unit] {
  return emit_event(template, run_dir, name, subject, "completed", attempt, caused_by, detail)
}

## Checks the checked-in ticket approval marker.
export proc accepted_ticket(ticket_path: Path) [fs, error] -> Result[Bool] {
  if ! fs.exists(ticket_path)? {
    return false
  }

  let text = fs.read_text(ticket_path)?
  return control.ticket_is_accepted(text) and control.ticket_api_surface_gate_ok(text)
}

proc budget_breach_section(
  factory_dir: Path,
  worker_dir: Path,
  reason: Str,
  worker_label: Str,
) [fs, error] -> Result[Str] {
  let worker_run = control.factory_relative_path(
    factory_dir.display(),
    fp"${worker_dir}/report.json",
  )
  let template = fp"${factory_dir}/templates/BUDGET-BREACH.md"
  let values = [
    {
      key: "REASON",
      value: reason,
    },
    {
      key: "WORKER_LABEL",
      value: worker_label,
    },
    {
      key: "WORKER_RUN",
      value: worker_run,
    },
  ]
  return control.fill_template(template.read_text()?, values)
}

## Closes an over-budget engineer assignment in its checked-in ticket.
export proc close_ticket_too_difficult(
  factory_dir: Path,
  ticket_id: Str,
  worker_dir: Path,
) [fs, error] -> Result[Bool] {
  if ! control.valid_ticket_id(ticket_id) {
    return false
  }

  let ticket_path = fp"${factory_dir}/tickets/${ticket_id}.md"
  if ! fs.exists(ticket_path)? {
    return false
  }

  let ticket_text = ticket_path.read_text()?
  if control.ticket_is_merged(ticket_text) {
    return false
  }

  let breach = budget_breach_section(
    factory_dir,
    worker_dir,
    "too difficult",
    "engineer run",
  )?
  var updated = control.replace_status(ticket_text, "Closed.")
  updated = control.replace_section(updated, "Budget breach", breach)
  if updated != ticket_text {
    fs.write_atomic(ticket_path, updated)?
  }

  return true
}

## Disables an eval whose isolated eval-worker exceeded its hard budget.
export proc disable_eval(factory_dir: Path, eval_id: Str, worker_dir: Path) [fs, error] -> Result[Bool] {
  if ! control.valid_eval_id(eval_id) {
    return false
  }

  let eval_path = fp"${factory_dir}/evals/${eval_id}/EVAL.md"
  if ! fs.exists(eval_path)? {
    return false
  }

  let eval_text = eval_path.read_text()?
  let breach = budget_breach_section(
    factory_dir,
    worker_dir,
    "eval-worker budget exceeded",
    "eval-worker run",
  )?
  var updated = control.replace_eval_status(eval_text, "Disabled.")
  updated = control.replace_section(updated, "Budget breach", breach)
  if updated != eval_text {
    fs.write_atomic(eval_path, updated)?
  }

  return true
}

pure worker_report_eval_id(report: Any, path_value: Path) -> Str {
  let identity = json.get(report, ["identity"], null)
  let explicit = schema.value_text(json.get(identity, ["eval_id"], ""))
  if explicit != "" {
    return explicit
  }

  let parts = path_value.display().split("/")
  var after_worker = false
  for part in parts {
    if after_worker {
      return part.replace("-1", "").replace("-2", "")
    }

    if part == "eval-worker" {
      after_worker = true
    }
  }

  return ""
}

proc eval_trial_count(factory_dir: Path, eval_id: Str) [fs, error] -> Result[Int] {
  let runs = fp"${factory_dir}/runs"
  if ! fs.exists(runs)? {
    return 0
  }

  var count = 0
  for entry in fs.files(runs, gitignore: false, hidden: true) {
    continue when entry.name != "report.json" or "/workers/eval-worker/" not in entry.path.display()
    let report = json.read(entry.path)?
    if worker_report_eval_id(report, entry.path) == eval_id {
      count += 1
    }
  }

  return count
}

## Returns approved evals with no persisted eval-worker report.
export proc untried_approved_evals(factory_dir: Path) [fs, error] -> Result[List[Str]] {
  let eval_dir = fp"${factory_dir}/evals"
  var untried: List[Str] = []
  if ! fs.exists(eval_dir)? {
    return untried
  }

  let contracts = fs.files(eval_dir, gitignore: false, hidden: true)
    |> where .name == "EVAL.md"
    |> sort-by .path.display()
    |> collect()
  for contract in contracts {
    let eval_id = contract.path.parent().name()
    continue when control.ticket_status(contract.path.read_text()?) != "Approved."
    if eval_trial_count(factory_dir, eval_id)? == 0 {
      untried = untried.push(eval_id)
    }
  }

  return untried
}

## Returns the deterministic next approved eval requiring its first trial.
## Returns up to `limit` deterministic approved evals requiring their first trial.
export proc next_untried_approved_evals(factory_dir: Path, limit: Int) [fs, error] -> Result[List[Str]] {
  let untried = untried_approved_evals(factory_dir)?
  if limit <= 0 {
    return []
  }

  var selected: List[Str] = []
  for eval_id in untried {
    selected = selected.push(eval_id)
    if selected.len() >= limit {
      break
    }
  }
  return selected
}

## Returns the deterministic next approved eval requiring its first trial.
export proc next_untried_approved_eval(factory_dir: Path) [fs, error] -> Result[Str] {
  let next = next_untried_approved_evals(factory_dir, 1)?
  return if next.len() == 0 { "" } else { next[0] }
}

## Selects the first explicitly approved tickets for an organization cycle.
export proc first_approved_tickets(factory_dir: Path, limit: Int) [fs, error] -> Result[List[Str]] {
  let ticket_dir = fp"${factory_dir}/tickets"
  var selected: List[Str] = []
  if limit <= 0 {
    return selected
  }

  if ! fs.exists(ticket_dir)? {
    return selected
  }

  let entries = fs.files(ticket_dir, gitignore: false, hidden: true)?
    |> sort-by .path.display()
    |> collect()
  for entry in entries {
    continue unless entry.name.ends_with(".md")
    if accepted_ticket(entry.path)? {
      selected = selected.push(entry.name.replace(".md", ""))
      if selected.len() >= limit {
        return selected
      }
    }
  }

  return selected
}

## Backward-compatible single-ticket selector for focused controllers.
export proc first_approved_ticket(factory_dir: Path) [fs, error] -> Result[Str] {
  let selected = first_approved_tickets(factory_dir, 1)?
  return if selected.len() == 1 { selected[0] } else { "" }
}

## Builds the complete ticket inventory used by the CTO pre-cycle briefing.
## This is deterministic controller state, not a worker-selected work list.
export proc cto_ticket_inventory(factory_dir: Path, xsh_repo: Path) [fs, process, error] -> Result[List[Any]] {
  let ticket_dir = fp"${factory_dir}/tickets"
  var tickets: List[Any] = []
  if ! fs.exists(ticket_dir)? {
    return tickets
  }

  let entries = fs.files(ticket_dir, gitignore: false, hidden: true)?
    |> sort-by .path.display()
    |> collect()
  for entry in entries {
    continue unless entry.name.ends_with(".md")
    let ticket_text = entry.path.read_text()?
    let status = control.ticket_status(ticket_text)
    let branch = if status == "Open." or status == "Approved." {
      open_ticket_branch(xsh_repo, entry.name.replace(".md", ""))?
    } else {
      ""
    }
    tickets = tickets.push({
      id: entry.name.replace(".md", ""),
      status: status,
      eval_id: control.ticket_eval(ticket_text),
      change_target: control.ticket_change_target(ticket_text),
      cto_review: ticket_text.contains("## CTO review"),
      open_branch: branch,
      path: entry.path.display(),
    })
  }

  return tickets
}

## Counts the Open and approved product-ticket queues for adaptive allocation.
## The returned list is `[open_tickets, approved_tickets]`; approval remains a
## CTO-owned state transition.
export proc organization_ticket_counts(factory_dir: Path, xsh_repo: Path) [fs, process, error] -> Result[List[Int]] {
  let inventory = cto_ticket_inventory(factory_dir, xsh_repo)?
  var open_tickets = 0
  var approved_tickets = 0
  for ticket in inventory {
    if ticket.status == "Open." {
      open_tickets += 1
    }
    if (ticket.status == "Approved." or ticket.status == "Accepted.") and ticket.change_target == "product" {
      approved_tickets += 1
    }
  }

  return [open_tickets, approved_tickets]
}

## Returns Open tickets that have no durable CTO review marker.
export pure cto_unreviewed_open_tickets(tickets: List[Any]) -> List[Str] {
  [ticket.id for ticket in tickets if ticket.status == "Open." and ! ticket.cto_review]
}

## Renders the programmatic ticket inventory for a human CTO handoff.
export pure cto_inventory_markdown(tickets: List[Any]) -> Str {
  var open_count = 0
  var approved_count = 0
  var markdown = """# CTO ticket inventory

"""
  for ticket in tickets {
    if ticket.status == "Open." {
      open_count += 1
    }

    if ticket.status == "Approved." or ticket.status == "Accepted." {
      approved_count += 1
    }
  }

  markdown = markdown + f"""- Open tickets: ${open_count}
"""
  markdown = markdown + f"""- Approved tickets: ${approved_count}
"""
  markdown = markdown + f"""- Ticket rows: ${tickets.len()}

"""
  markdown = markdown + """| Ticket | Status | Change target | Linked eval | CTO review marker | Open branch |
"""
  markdown = markdown + """| --- | --- | --- | --- | --- | --- |
"""
  for ticket in tickets {
    let review = if ticket.cto_review { "present" } else { "missing" }
    let branch = if ticket.open_branch == "" { "none" } else { ticket.open_branch }
    markdown = markdown + f"""| `${ticket.id}` | `${ticket.status}` | `${ticket.change_target}` | `${ticket.eval_id}` | ${review} | `${branch}` |
"""
  }

  return markdown
}

## Persists the CTO inventory into a controller-owned run directory.
export proc write_cto_inventory(factory_dir: Path, run_dir: Path, xsh_repo: Path) [fs, process, error] -> Result[Unit] {
  let tickets = cto_ticket_inventory(factory_dir, xsh_repo)?
  fs.write_atomic(
    fp"${run_dir}/CTO-TICKET-INVENTORY.json",
    json.encode({tickets: tickets})? + "\n",
  )?
  fs.write_atomic(
    fp"${run_dir}/CTO-TICKET-INVENTORY.md",
    cto_inventory_markdown(tickets),
  )?
}

## Returns whether an eval is explicitly retired from the active portfolio.
## A missing package is retired only when the retirement ledger records it;
## an unknown missing package remains a lifecycle error for CTO review.
export proc eval_is_retired(factory_dir: Path, eval_id: Str) [fs, error] -> Result[Bool] {
  if ! control.valid_eval_id(eval_id) {
    return false
  }

  let contract = fp"${factory_dir}/evals/${eval_id}/EVAL.md"
  if fs.exists(contract)? {
    return control.eval_is_disabled(contract.read_text()?)
  }

  let ledger = fp"${factory_dir}/evals/RETIREMENTS.md"
  if ! fs.exists(ledger)? {
    return false
  }

  return ledger.read_text()?.contains(f"""## ${eval_id}
""")
}

## Closes active tickets whose linked eval has an explicit retirement record.
## This is deterministic lifecycle reconciliation; it never changes terminal
## tickets and does not make a product judgment.
export proc close_tickets_for_retired_evals(factory_dir: Path) [fs, error] -> Result[List[Str]] {
  let ticket_dir = fp"${factory_dir}/tickets"
  let disposition_template = fp"${factory_dir}/templates/TICKET-RETIRED-EVAL-DISPOSITION.md"
  if ! fs.exists(ticket_dir)? {
    return []
  }

  if ! fs.exists(disposition_template)? {
    return Err(
      RuntimeError.InvalidTransition(
        subject: "ticket-template",
        current: "missing-retired-eval-disposition",
        next: "reconcile",
      ),
    )
  }

  let template = disposition_template.read_text()?
  var closed: List[Str] = []
  for entry in fs.files(ticket_dir, gitignore: false, hidden: true) |> sort-by .path.display() {
    continue unless entry.name.ends_with(".md")
    let ticket_id = entry.name.replace(".md", "")
    let ticket_text = entry.path.read_text()?
    let status = control.ticket_status(ticket_text)
    continue when status != "Open." and status != "Approved." and status != "Accepted."
    let eval_id = control.ticket_eval(ticket_text)
    continue unless eval_is_retired(factory_dir, eval_id)?
    let evidence = if fs.exists(fp"${factory_dir}/evals/${eval_id}/EVAL.md")? {
      f"evals/${eval_id}/EVAL.md"
    } else {
      "evals/RETIREMENTS.md"
    }
    let disposition = control.fill_template(
      template,
      [
        {
          key: "EVAL_ID",
          value: eval_id,
        },
        {
          key: "EVAL_EVIDENCE",
          value: evidence,
        },
      ],
    )
    var updated = control.replace_ticket_status(ticket_text, "Closed.")
    updated = control.replace_ticket_section(updated, "Lifecycle disposition", disposition)
    if updated != ticket_text {
      fs.write_atomic(entry.path, updated)?
      closed = closed.push(ticket_id)
    }
  }

  return closed
}

## Archives active factory branches for tickets closed because their eval was
## retired. The commit remains reachable, but the branch leaves dispatch.
export proc archive_retired_ticket_branches(xsh_repo: Path, factory_dir: Path) [fs, process, error] -> Result[Int] {
  let candidates = stale_ticket_branches(xsh_repo, factory_dir)?
  var archived = 0
  for candidate in candidates {
    continue when candidate.ticket_status != "Closed."
    let ticket_path = fp"${factory_dir}/tickets/${candidate.ticket_id}.md"
    continue unless fs.exists(ticket_path)?
    continue unless eval_is_retired(factory_dir, control.ticket_eval(ticket_path.read_text()?))?
    let branch_parts = candidate.branch.split("/")
    let suffix = branch_parts.get(2, "branch")
    let target = f"archive/retired/${candidate.ticket_id}/${suffix}"
    let status = process.run(
      process.command_argv(
        "git",
        ["git", "-C", xsh_repo.display(), "branch", "-m", candidate.branch, target],
      ),
    )?
    if status.ok {
      archived += 1
    }
  }

  return archived
}

proc commit_is_ancestor(xsh_repo: Path, commit: Str) [process, error] -> Result[Bool] {
  if commit == "" {
    return false
  }

  let status = process.run(
    process.command_argv(
      "git",
      ["git", "-C", xsh_repo.display(), "merge-base", "--is-ancestor", commit, "HEAD"],
    ),
  )?
  return status.ok
}

proc ref_contains_commit(xsh_repo: Path, ref: Str, commit: Str) [process, error] -> Result[Bool] {
  if ref == "" or commit == "" {
    return false
  }

  let status = process.run(
    process.command_argv(
      "git",
      ["git", "-C", xsh_repo.display(), "merge-base", "--is-ancestor", commit, ref],
    ),
  )?
  return status.ok
}

proc commit_is_patch_applied(xsh_repo: Path, branch: Str, commit: Str) [process, error] -> Result[Bool] {
  if branch == "" or commit == "" {
    return false
  }

  let branch_status = process.run(
    process.command_argv(
      "git",
      ["git", "-C", xsh_repo.display(), "rev-parse", "--verify", f"refs/heads/${branch}"],
    ),
  )?
  if ! branch_status.ok {
    return false
  }

  let cherry = run.text "git" "-C" $xsh_repo "cherry" "-v" "HEAD" $branch ?
  for line in cherry.lines() {
    if line.starts_with(f"- ${commit} ") {
      return true
    }
  }

  return false
}

proc commit_is_merged(xsh_repo: Path, branch: Str, commit: Str) [process, error] -> Result[Bool] {
  return commit_is_ancestor(xsh_repo, commit)? or commit_is_patch_applied(xsh_repo, branch, commit)?
}

## Retires only branches proven merged for Closed/Merged tickets.
## This is explicit maintenance, never automatic cycle admission behavior.
export proc retire_stale_ticket_branches(xsh_repo: Path, factory_dir: Path) [fs, process, error] -> Result[Int] {
  let candidates = stale_ticket_branches(xsh_repo, factory_dir)?
  var retired = 0
  for candidate in candidates {
    continue when candidate.ticket_status != "Merged." and candidate.ticket_status != "Closed."
    continue unless candidate.merged
    let status = process.run(
      process.command_argv(
        "git",
        ["git", "-C", xsh_repo.display(), "branch", "-D", candidate.branch],
      ),
    )?
    if status.ok {
      retired += 1
    }
  }

  return retired
}

## Inventories branches that are merged, closed, or otherwise stale candidates.
export proc stale_ticket_branches(xsh_repo: Path, factory_dir: Path) [fs, process, error] -> Result[List[Any]] {
  var stale: List[Any] = []
  let refs = run.text "git" "-C" $xsh_repo "for-each-ref" "--format=%(refname:short)" "refs/heads/factory/" ?
  for line in refs.lines() {
    let branch = line.trim()
    continue when branch == ""
    let parts = branch.split("/")
    continue when parts.len() < 3
    let ticket_id = parts[1]
    continue unless control.valid_ticket_id(ticket_id)
    let ticket_path = fp"${factory_dir}/tickets/${ticket_id}.md"
    let status = if fs.exists(ticket_path)? { control.ticket_status(ticket_path.read_text()?) } else { "missing" }
    let merged_status = process.run(
      process.command_argv(
        "git",
        ["git", "-C", xsh_repo.display(), "merge-base", "--is-ancestor", branch, "HEAD"],
      ),
    )?
    let merged = merged_status.ok
    if status == "Merged." or status == "Closed." or merged {
      stale = stale.push({branch: branch, ticket_id: ticket_id, ticket_status: status, merged: merged})
    }
  }

  return stale
}

## Finds an implementation branch that is still unmerged for one ticket.
export proc open_ticket_branch(xsh_repo: Path, ticket_id: Str) [process, error] -> Result[Str] {
  if ! control.valid_ticket_id(ticket_id) {
    return ""
  }

  let branch_prefix = f"refs/heads/factory/${ticket_id}/"
  let refs = run.text "git" "-C" $xsh_repo "for-each-ref" "--format=%(refname:short)" $branch_prefix ?
  for branch_line in refs.lines() {
    let branch = branch_line.trim()
    continue when branch == ""
    let commit = run.text "git" "-C" $xsh_repo "rev-parse" $branch ?
    if ! commit_is_merged(xsh_repo, branch, commit.trim())? {
      return branch
    }
  }

  return ""
}

## Delivers one validated organization-cycle implementation into XSH HEAD.
## The controller supplies the phase containing the controller-owned engineer
## or reuse evidence. The exact report commit must still be the branch tip,
## must descend from the cycle baseline, and the product checkout must be
## clean. A single branch fast-forwards; a second independent branch is merged
## with an explicit checked merge so two admitted tickets cannot strand the
## first delivery. Any Git failure returns false and leaves the branch intact.
export proc merge_validated_ticket(
  xsh_repo: Path,
  phase_dir: Path,
  ticket_id: Str,
  base_commit: Str,
) [fs, process, error] -> Result[DeliveryEvidence] {
  let worker_report = fp"${phase_dir}/workers/engineer/${ticket_id}/REPORT.md"
  let phase_report = fp"${phase_dir}/report.json"
  var branch = ""
  var implementation_commit = ""

  if fs.exists(worker_report)? {
    let report_text = fs.read_text(worker_report)?
    branch = control.report_field(report_text, "Branch")
    implementation_commit = control.report_field(report_text, "Commit")
  } else if fs.exists(phase_report)? {
    let report = json.read(phase_report)?
    branch = schema.value_text(json.get(report, ["data", "branch"], ""))
    implementation_commit = schema.value_text(json.get(report, ["data", "implementation_commit"], ""))
  }

  let evidence = {
    merged: false,
    ticket_id: ticket_id,
    branch: branch,
    implementation_commit: implementation_commit,
  }
  if branch == "" or implementation_commit == "" or ! branch.starts_with(f"factory/${ticket_id}/") {
    return evidence
  }

  # Retained organization branches may predate the current cycle baseline.
  # Require a verified common ancestor instead of requiring the branch to
  # contain the latest baseline; this preserves the checked merge path for
  # independent, reviewable work while rejecting unrelated histories.
  var merge_base = base_commit.trim()
  var reported_merge_base = ""
  if fs.exists(phase_report)? {
    let report = json.read(phase_report)?
    reported_merge_base = schema.value_text(json.get(report, ["data", "merge_base"], ""))
    if reported_merge_base != "" {
      merge_base = reported_merge_base
    }
  }

  let product_status = run.text "git" "-C" $xsh_repo "status" "--porcelain" ?
  if product_status.trim() != "" or merge_base == "" or ! ref_contains_commit(xsh_repo, "HEAD", base_commit.trim())? {
    return evidence
  }

  let branch_head_status = process.run(
    process.command_argv(
      "git",
      ["git", "-C", xsh_repo.display(), "rev-parse", "--verify", f"refs/heads/${branch}"],
    ),
  )?
  if ! branch_head_status.ok {
    return evidence
  }
  let branch_head = run.text "git" "-C" $xsh_repo "rev-parse" $branch ?
  let actual_merge_base = run.text "git" "-C" $xsh_repo "merge-base" "HEAD" $branch ?
  let merge_base_matches_contract = if reported_merge_base == "" {
    actual_merge_base.trim() == base_commit.trim()
  } else {
    actual_merge_base.trim() == merge_base
  }
  if branch_head.trim() != implementation_commit.trim() or ! merge_base_matches_contract or ! ref_contains_commit(xsh_repo, "HEAD", merge_base)? or ! ref_contains_commit(xsh_repo, branch, merge_base)? {
    return evidence
  }

  if ref_contains_commit(xsh_repo, "HEAD", implementation_commit.trim())? {
    return {
      merged: true,
      ticket_id: ticket_id,
      branch: branch,
      implementation_commit: implementation_commit.trim(),
    }
  }

  let current_head = run.text "git" "-C" $xsh_repo "rev-parse" "HEAD" ?
  let head_is_branch_ancestor = ref_contains_commit(xsh_repo, branch, current_head.trim())?
  let merge_args = if head_is_branch_ancestor {
    ["git", "-C", xsh_repo.display(), "merge", "--ff-only", branch]
  } else {
    ["git", "-C", xsh_repo.display(), "merge", "--no-ff", "--no-edit", branch]
  }
  let merge_status = process.run(process.command_argv("git", merge_args))?
  if ! merge_status.ok {
    let _ = process.run(
      process.command_argv("git", ["git", "-C", xsh_repo.display(), "merge", "--abort"]),
    )?
    return evidence
  }

  let delivered = ref_contains_commit(xsh_repo, "HEAD", implementation_commit.trim())?
  return {
    merged: delivered,
    ticket_id: ticket_id,
    branch: branch,
    implementation_commit: implementation_commit.trim(),
  }
}

proc find_merged_implementation(
  factory_dir: Path,
  xsh_repo: Path,
  ticket_id: Str,
  detected_xsh_commit: Str,
) [fs, process, error] -> Result[MergeEvidence] {
  let runs = fp"${factory_dir}/runs"
  if fs.exists(runs)? {
    for run_entry in fs.dirs(runs, gitignore: false, hidden: true)? {
      let run_dir = run_entry.path
      let summary = fp"${run_dir}/report.json"
      let report = fp"${run_dir}/workers/engineer/${ticket_id}/REPORT.md"
      continue when ! fs.exists(summary)? or ! fs.exists(report)?
      let report_text = fs.read_text(report)?
      let summary_value = json.read(summary)?
      let summary_result = match json.get(summary_value, ["result"], "") {
        s is Str => s,
        _ => "",
      }
      continue when summary_result != "pass" or ! control.engineer_report_contract_ok(report_text)
      let branch = control.report_field(report_text, "Branch")
      let commit = control.report_field(report_text, "Commit")
      if branch != "" and commit != "" and commit_is_merged(xsh_repo, branch, commit)? {
        return {
          merged: true,
          ticket_id: ticket_id,
          branch: branch,
          implementation_commit: commit,
          source_run: run_dir.display(),
          detected_xsh_commit: detected_xsh_commit,
        }
      }
    }
  }

  # Branch ancestry alone is not implementation evidence: an old ticket branch
  # can point at any historical XSH commit already contained in HEAD. Only a
  # passing engineer report with its exact implementation commit can reconcile
  # a ticket as merged.
  return {
    merged: false,
    ticket_id: ticket_id,
    branch: "",
    implementation_commit: "",
    source_run: "",
    detected_xsh_commit: detected_xsh_commit,
  }
}

## Reconciles approved tickets against the current XSH HEAD.
export proc reconcile_tickets(
  factory_dir: Path,
  xsh_repo: Path,
  detected_xsh_commit: Str,
) [fs, process, error] -> Result[List[MergedTicket]] {
  let ticket_dir = fp"${factory_dir}/tickets"
  var merged: List[MergedTicket] = []
  if ! fs.exists(ticket_dir)? {
    return merged
  }

  let ticket_template = fp"${factory_dir}/templates/TICKET.md"
  let merge_section_template = control.section_text(ticket_template.read_text()?, "Merge record")
  if merge_section_template == "" {
    return Err(
      RuntimeError.InvalidTransition(
        subject: "ticket-template",
        current: "missing-merge-record",
        next: "reconcile",
      ),
    )
  }

  for entry in fs.files(ticket_dir, gitignore: false, hidden: true)? {
    continue unless entry.name.ends_with(".md")
    let ticket_id = entry.name.replace(".md", "")
    let ticket_path = entry.path
    let ticket_text = fs.read_text(ticket_path)?
    let status = control.ticket_status(ticket_text)
    continue when status != "Accepted." and status != "Approved." and status != "Merged."
    continue when status == "Merged." and control.ticket_merge_record_complete(ticket_text)
    let evidence = find_merged_implementation(
      factory_dir,
      xsh_repo,
      ticket_id,
      detected_xsh_commit,
    )?
    continue unless evidence.merged
    let values = [
      {
        key: "IMPLEMENTATION_BRANCH",
        value: evidence.branch,
      },
      {
        key: "IMPLEMENTATION_COMMIT",
        value: evidence.implementation_commit,
      },
      {
        key: "DETECTED_XSH_COMMIT",
        value: detected_xsh_commit,
      },
      {
        key: "IMPLEMENTATION_RUN",
        value: evidence.source_run,
      },
    ]
    let merge_record = control.fill_template(merge_section_template, values)
    let updated_status = control.replace_ticket_status(ticket_text, "Merged.")
    let updated_ticket = control.replace_ticket_section(updated_status, "Merge record", merge_record)
    if updated_ticket != ticket_text {
      fs.write(ticket_path, updated_ticket)?
    }

    merged = merged.push({
      ticket_id: evidence.ticket_id,
      eval_id: control.ticket_eval(ticket_text),
      branch: evidence.branch,
      implementation_commit: evidence.implementation_commit,
      source_run: evidence.source_run,
      detected_xsh_commit: evidence.detected_xsh_commit,
    })
  }

  return merged
}

## Reads an active or compressed persisted Pi session.
## A missing `.jsonl` path falls back to its `.jsonl.bz2` archive.
export proc session_text(session: Path) [fs, process, error] -> Result[Str] {
  let compressed = fp"${session.display()}.bz2"
  let source = if fs.exists(session)? { session } else { compressed }
  if source.display().ends_with(".bz2") {
    return run.text "bzip2" "-dc" $source
  }

  return source.read_text()
}

pure session_reference_file(name: Str) -> Bool {
  return name.ends_with(".json") or name.ends_with(".jsonl") or name.ends_with(".events.jsonl.bz2") or name.ends_with(
    ".md",
  ) or name.ends_with(".txt") or name.ends_with(".stdout") or name.ends_with(".stderr") or name.ends_with(".state") or name.ends_with(
    ".pids",
  ) or name.ends_with(".claimed")
}

## Compresses raw sessions after a run has finished using them.
## Textual evidence keeps references to the new `.jsonl.bz2` path.
export proc compress_run_sessions(run_dir: Path) [fs, process, error] -> Result[Unit] {
  let bzip2 = process.which("bzip2")?
  var sessions: List[Path] = []
  for entry in fs.walk(run_dir, gitignore: false, hidden: true)? |> where .kind == "file" {
    if entry.name == "session.jsonl" {
      sessions = sessions.push(entry.path)
    } else if entry.name.ends_with(".events.jsonl") {
      # JSON mode emits one record per streaming delta. Provider telemetry is
      # normalized into report.json; the raw stream is transient input.
      fs.remove(entry.path, missing_ok: true)?
    }
  }

  for session in sessions {
    let archive_path = fp"${session.display()}.bz2"
    let status = process.run(
      process.command_argv(
        bzip2,
        [bzip2.display(), "-c", session.display()],
        stdout: archive_path,
      ),
    )?
    if ! status.ok {
      return
    }

    fs.remove(session)?
  }

  for entry in fs.walk(run_dir, gitignore: false, hidden: true)? |> where .kind == "file" {
    continue when entry.name.ends_with(".bz2") or ! session_reference_file(entry.name)
    let text = entry.path.read_text()?
    let normalized = text.replace("/session/session.jsonl.events.jsonl.bz2", "/session/__SESSION_EVENTS_ARCHIVE__")
      .replace("/session/session.jsonl.bz2", "/session/__SESSION_ARCHIVE__")
      .replace("/session/session.jsonl.events.jsonl", "/session/__SESSION_EVENTS_JSONL__")
      .replace("/session/session.jsonl", "/session/__SESSION_JSONL__")
      .replace("session.jsonl.events.jsonl.bz2", "__SESSION_EVENTS_ARCHIVE__")
      .replace("session.jsonl.bz2", "__SESSION_ARCHIVE__")
      .replace("session.jsonl.events.jsonl", "__SESSION_EVENTS_RAW__")
      .replace("session.jsonl", "session.jsonl.bz2")
      .replace("__SESSION_JSONL__", "session.jsonl")
      .replace("__SESSION_EVENTS_JSONL__", "session.jsonl.events.jsonl.bz2")
      .replace("__SESSION_EVENTS_RAW__", "session.jsonl.events.jsonl")
      .replace("__SESSION_ARCHIVE__", "session.jsonl.bz2")
      .replace("__SESSION_EVENTS_ARCHIVE__", "session.jsonl.events.jsonl.bz2")
    if normalized != text {
      fs.write_atomic(entry.path, normalized)?
    }
  }
}

## Proves that a Pi session called the read tool for one exact path.
export proc session_read_path(session: Path, expected: Path) [fs, process, error] -> Result[Bool] {
  let text = session_text(session)?
  var found = false
  for line in text.lines() {
    let read_call = "\"role\":\"assistant\"" in line and "\"name\":\"read\"" in line
    let read_result = "\"role\":\"toolResult\"" in line and "\"toolName\":\"read\"" in line
    if (read_call or read_result) and expected.display() in line {
      found = true
    }
  }

  return found
}

## Acquires a run lock at an explicit scope.
export proc acquire_run_lock_at(lock_path: Path) [fs, error] -> Result[Record] {
  return fs.lock(lock_path, nonblocking: true)
}

## Acquires the single-factory run lock and rejects concurrent direct cycles.
export proc acquire_run_lock(factory_dir: Path) [fs, error] -> Result[Record] {
  let runs = fp"${factory_dir}/runs"
  fs.mkdir(runs)?
  return acquire_run_lock_at(fp"${runs}/factory.lock")
}

## Verifies the checked-in handbook has not changed during a run.
export proc verify_factory_handbook(factory_dir: Path, expected_sha: Str) [fs, error] -> Result[Bool] {
  let handbook = fp"${factory_dir}/runtime/handbook.md"
  return fs.exists(handbook)? and hash.sha256(handbook)?.hex() == expected_sha
}

## Returns the fingerprint of immutable factory inputs used by a paid run.
## Run evidence, ticket lifecycle records, and archived outputs are deliberately
## excluded because controllers own those mutable boundaries during a cycle.
export proc factory_source_fingerprint(factory_dir: Path) [fs, error] -> Result[Str] {
  var files: List[Path] = [
    fp"${factory_dir}/run.xsh",
    fp"${factory_dir}/NORTH-STAR.md",
    fp"${factory_dir}/FACTORY.md",
    fp"${factory_dir}/README.md",
    fp"${factory_dir}/CTO.md",
    fp"${factory_dir}/THROUGHPUT.md",
    fp"${factory_dir}/runtime/handbook.md",
    fp"${factory_dir}/runtime/handbook-ledger.md",
  ]
  for root in ["factory", "roles", "templates", "evals"] {
    let root_path = fp"${factory_dir}/${root}"
    if fs.exists(root_path)? {
      for entry in fs.walk(root_path, gitignore: false, hidden: true)? |> where .kind == "file" {
        continue when "/.dist/" in entry.path.display()
        files = files.push(entry.path)
      }
    }
  }

  files = files |> sort-by .display() |> collect()
  var manifest = ""
  for file in files {
    if ! fs.exists(file)? {
      return ""
    }

    manifest = manifest + file.display() + "\n" + hash.sha256(file)?.hex() + "\n"
  }

  return hash.sha256(bytes.from_text(manifest)).hex()
}

## Verifies that the immutable factory inputs still match paid admission.
export proc verify_factory_source(factory_dir: Path, expected_sha: Str) [fs, error] -> Result[Bool] {
  return expected_sha != "" and factory_source_fingerprint(factory_dir)? == expected_sha
}

## Snapshots the approved handbook before a worker starts. The snapshot is
## run-local evidence, not a promotion: a worker may contribute a candidate,
## but the approved live handbook remains controller-owned.
export proc stage_factory_source_snapshot(factory_dir: Path, run_dir: Path) [fs, error] -> Result[Unit] {
  let snapshot_dir = fp"${run_dir}/factory-source"
  let snapshot = fp"${snapshot_dir}/handbook-approved.md"
  fs.mkdir(snapshot_dir)?
  let _ = fs.lock(fp"${snapshot_dir}/snapshot.lock", nonblocking: true)?
  if ! fs.exists(snapshot)? {
    fs.copy(fp"${factory_dir}/runtime/handbook.md", snapshot, overwrite: true)?
  }
}

## Converts an accidental live handbook edit into run evidence and restores the
## approved baseline. Only a handbook-only mutation is recoverable; any other
## source mutation remains fail-closed for the next controller boundary.
export proc quarantine_factory_handbook(
  factory_dir: Path,
  run_dir: Path,
  expected_sha: Str,
) [fs, error] -> Result[Str] {
  if expected_sha == "" or verify_factory_source(factory_dir, expected_sha)? {
    return "unchanged"
  }

  let snapshot = fp"${run_dir}/factory-source/handbook-approved.md"
  let handbook = fp"${factory_dir}/runtime/handbook.md"
  if ! fs.exists(snapshot)? or ! fs.exists(handbook)? {
    return "source-changed"
  }

  let snapshot_sha = hash.sha256(snapshot)?.hex()
  let handbook_sha = hash.sha256(handbook)?.hex()
  if snapshot_sha == handbook_sha {
    return "source-changed"
  }

  let candidate = fp"${run_dir}/factory-source/handbook-candidate.md"
  let _ = fs.lock(fp"${run_dir}/factory-source/quarantine.lock", nonblocking: true)?
  fs.copy(handbook, candidate, overwrite: true)?
  fs.copy(snapshot, handbook, overwrite: true)?
  if verify_factory_source(factory_dir, expected_sha)? {
    return "handbook-quarantined"
  }

  return "source-changed"
}

## Counts historical candidate snapshots with no explicit ledger disposition.
## A nonzero result blocks the next paid cycle until the CTO promotes or
## rejects the candidate; lineage files must never become invisible backlog.
export proc unresolved_handbook_candidates(factory_dir: Path) [fs, error] -> Result[Int] {
  let handbook = fp"${factory_dir}/runtime/handbook.md"
  let runs_dir = fp"${factory_dir}/runs"
  let ledger_path = fp"${factory_dir}/runtime/handbook-ledger.md"
  if ! fs.exists(handbook)? or ! fs.exists(runs_dir)? {
    return 0
  }

  let current_sha = hash.sha256(handbook)?.hex()
  let ledger = if fs.exists(ledger_path)? { ledger_path.read_text()? } else { "" }
  var unresolved = 0
  for entry in fs.walk(runs_dir, gitignore: false, hidden: true)? |> where .kind == "file" {
    continue when entry.name != "handbook-candidate.md"
    let sha = hash.sha256(entry.path)?.hex()
    if sha != current_sha and sha not in ledger {
      unresolved = unresolved + 1
    }
  }

  return unresolved
}
