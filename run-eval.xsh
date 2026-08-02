##! Eval-cycle controller. The parent run.xsh owns signals.

use factory_control as control
use factory_runtime as runtime

proc main(...argv: List[Str]) [fs, process, env, time, error, io] {
  if argv.len() < 1 {
    eprint "usage: run-eval.xsh CYCLE_REQUEST.md [EVAL_ID]"
    abort(2)
  }
  let factory_dir = env.path("FACTORY_DIR", fs.cwd()?)?
  let request = Path(argv[0])
  let request_text = request.read_text()?
  let requested_eval = if argv.len() >= 2 { argv[1] } else { control.request_eval(request_text) }
  let eval_path = fp"${factory_dir}/evals/${requested_eval}/EVAL.md"
  let eval_exists = fs.exists(eval_path)?
  let eval_disabled = eval_exists and control.eval_is_disabled(eval_path.read_text()?)
  if ! control.valid_eval_id(requested_eval) or ! eval_exists or eval_disabled {
    eprint f"cycle request selected unsupported or missing eval: ${requested_eval}"
    abort(2)
  }
  let trial_count = control.request_trial_count(request_text)?
  if trial_count < 1 or trial_count > 2 {
    eprint f"unsupported trial count: ${trial_count} (expected 1 or 2)"
    abort(2)
  }
  let new_eval_count = control.request_new_eval_count(request_text)?
  if new_eval_count < 0 or new_eval_count > 1 {
    eprint f"unsupported new eval proposal count: ${new_eval_count} (expected 0 or 1)"
    abort(2)
  }
  let eval_id = requested_eval
  let eval_dir = fp"${factory_dir}/evals/${eval_id}"
  let task_file = "task.md"
  let artifact_file = fs.read_text(fp"${eval_dir}/runtime/artifact.md")?.trim()
  if artifact_file == "" or artifact_file.contains("/") or artifact_file.contains("\\") {
    eprint f"eval ${eval_id} has invalid runtime/artifact.md"
    abort(2)
  }
  let home = env.get("HOME")?
  let auth_file = env.path("PI_AUTH_FILE", fp"${home}/.pi/agent/auth.json")?
  let docker = env.get_or("DOCKER", "docker")?
  let platform = env.get_or("FACTORY_PLATFORM", "linux/arm64")?
  let target = env.get_or("XSH_TARGET", "aarch64-unknown-linux-musl")?
  let xsh_repo = env.path("FACTORY_XSH_REPO", fp"${factory_dir}/../xsh")?
  let candidate_ticket = env.get_or("FACTORY_REEVAL_TICKET", "not-reevaluation")?
  let candidate_worktree = env.get_or("FACTORY_REEVAL_WORKTREE", "not-reevaluation")?
  let stamp = time.now()
  let configured_phase_dir = env.get_or("FACTORY_PHASE_DIR", "")?
  let run_dir = if configured_phase_dir == "" {
    fp"${factory_dir}/runs/run-${stamp}"
  } else {
    Path(configured_phase_dir)
  }
  let worker_root = fp"${run_dir}/workers"
  let active_run = env.path("FACTORY_ACTIVE_RUN", fp"${factory_dir}/runs/ACTIVE")?
  let lock_path = env.path("FACTORY_LOCK_PATH", fp"${factory_dir}/runs/factory.lock")?
  let _run_lock = runtime.acquire_run_lock_at(lock_path)?
  let event_template = fp"${factory_dir}/templates/EVENT.md"
  let provenance_template = fp"${factory_dir}/templates/PROVENANCE.md"
  let lineage_dir = fp"${run_dir}/lineage"
  let baseline_handbook = fp"${lineage_dir}/handbook-approved.md"
  let candidate_handbook = fp"${lineage_dir}/handbook-candidate.md"
  fs.mkdir(fp"${factory_dir}/runs")?
  if fs.exists(active_run)? and fs.read_text(active_run)?.trim() != "" {
    eprint "another factory run is already active"
    abort(1)
  }

  fs.mkdir(run_dir)?
  fs.mkdir(worker_root)?
  fs.mkdir(lineage_dir)?
  runtime.register_cycle_controller(run_dir)?
  let skip_cycle_budget = env.get_or("FACTORY_SKIP_CYCLE_BUDGET", "false")? == "true"
  if ! skip_cycle_budget {
    let _cycle_budget_watch = runtime.start_cycle_budget_watch(factory_dir, run_dir)?
  }
  fs.write(active_run, run_dir.display() + "\n")?
  defer fs.remove(active_run, missing_ok: true)?
  runtime.emit_event(event_template, run_dir, "00-cycle-started", eval_id, "started", 1, "controller", "eval-manager cycle")?
  fs.copy(request, fp"${run_dir}/CYCLE-REQUEST.md", overwrite: true)?
  fs.copy(fp"${factory_dir}/runtime/handbook.md", baseline_handbook, overwrite: true)?

  let xsh_commit = run.text "git" "-C" $xsh_repo.display() "rev-parse" "HEAD" ?
  let skip_reconcile = env.get_or("FACTORY_SKIP_TICKET_RECONCILE", "false")? == "true"
  let merged_tickets = if skip_reconcile {
    []
  } else {
    runtime.reconcile_tickets(factory_dir, xsh_repo, xsh_commit.trim())?
  }
  let xsh_commit_short = xsh_commit.trim().byte_slice(0, 12)
  let factory_control_sha = hash.sha256(fp"${factory_dir}/factory_control.xsh")?.hex()
  let factory_runtime_sha = hash.sha256(fp"${factory_dir}/factory_runtime.xsh")?.hex()
  let evaluate_common_sha = hash.sha256(fp"${factory_dir}/evaluate_common.xsh")?.hex()
  let eval_worker_sha = hash.sha256(fp"${factory_dir}/evals/eval-worker.xsh")?.hex()
  let base_dockerfile_sha = hash.sha256(fp"${factory_dir}/evals/Dockerfile.base")?.hex()
  let eval_dockerfile = fp"${eval_dir}/Dockerfile"
  let has_eval_dockerfile = fs.exists(eval_dockerfile)?
  let eval_dockerignore = fp"${eval_dir}/.dockerignore"
  let eval_dockerignore_sha = if fs.exists(eval_dockerignore)? {
    hash.sha256(eval_dockerignore)?.hex()
  } else {
    "none"
  }
  let base_dockerignore = fp"${factory_dir}/evals/.dockerignore"
  let base_dockerignore_sha = if fs.exists(base_dockerignore)? {
    hash.sha256(base_dockerignore)?.hex()
  } else {
    "none"
  }
  let xsh_git_status = run.text "git" "-C" $xsh_repo.display() "status" "--porcelain" ?
  if xsh_git_status.trim() != "" {
    eprint "eval cycle requires a clean XSH worktree at admission"
    abort(2)
  }
  let cache_dir = fp"${factory_dir}/runs/.cache"
  fs.mkdir(cache_dir)?
  let toolchain_cache = fp"${cache_dir}/xsh-test-${target}.stamp"
  let toolchain_dockerfile_sha = hash.sha256(fp"${xsh_repo}/Dockerfile.test")?.hex()
  let toolchain_makefile_sha = hash.sha256(fp"${xsh_repo}/Makefile")?.hex()
  let host_arch = run.text "uname" "-m" ?
  let toolchain_key = f"${toolchain_dockerfile_sha}:${toolchain_makefile_sha}:${target}:${host_arch.trim()}"
  let toolchain_image = env.get_or("XSH_TEST_IMAGE", "xsh-test")?
  let force_toolchain_rebuild = env.get_or("FACTORY_FORCE_XSH_TOOLCHAIN_REBUILD", "false")? == "true"
  let force_image_rebuild = env.get_or("FACTORY_FORCE_IMAGE_REBUILD", "false")? == "true"
  let base_tag = control.factory_image_tag(
    xsh_commit.trim(), factory_control_sha, factory_runtime_sha, evaluate_common_sha,
    eval_worker_sha, base_dockerfile_sha, toolchain_dockerfile_sha, toolchain_makefile_sha,
    target, platform, "", base_dockerignore_sha,
  )
  let eval_tag = control.factory_image_tag(
    xsh_commit.trim(), factory_control_sha, factory_runtime_sha, evaluate_common_sha,
    eval_worker_sha, base_dockerfile_sha, toolchain_dockerfile_sha, toolchain_makefile_sha,
    target, platform,
    if has_eval_dockerfile { hash.sha256(eval_dockerfile)?.hex() } else { "none" },
    eval_dockerignore_sha,
  )
  let build_id = f"${xsh_commit.trim()}-${base_tag}"
  let configured_base_image = env.get_or("FACTORY_BASE_IMAGE", "")?
  let base_image = if configured_base_image == "" {
    f"xsh-factory-base:${base_tag}"
  } else {
    configured_base_image
  }
  let default_image = f"xsh-factory-${eval_id}:${eval_tag}"
  let image = env.get_or("FACTORY_EVAL_IMAGE", if has_eval_dockerfile { default_image } else { base_image })?
  let eval_build_lock = fs.lock(fp"${factory_dir}/runs/eval-build.lock")?
  let toolchain_present = if force_toolchain_rebuild {
    false
  } else {
    process.run(process.command_argv(
      docker, [docker, "image", "inspect", toolchain_image],
    ))?.ok
  }
  let toolchain_cache_exists = fs.exists(toolchain_cache)?
  let cached_toolchain_key = if toolchain_cache_exists {
    toolchain_cache.read_text()?.trim()
  } else {
    ""
  }
  let toolchain_cache_hit = control.toolchain_cache_valid(
    force_toolchain_rebuild,
    toolchain_cache_exists,
    cached_toolchain_key,
    toolchain_key,
    toolchain_present,
  )
  let toolchain_build_flag = if toolchain_cache_hit { "0" } else { "1" }
  let build_started = time.now()
  let dist_dir = fp"${xsh_repo}/target/docker-${target}-release/${target}/dist"
  let dist_xsh = fp"${dist_dir}/xsh"
  let dist_xsht = fp"${dist_dir}/xsht"
  let build = process.run(
    process.command_argv(
      "make",
      ["make", "-C", xsh_repo.display(), "dist-Linux-docker", f"TARGET=${target}",
        f"XSH_TEST_IMAGE=${toolchain_image}", f"XSH_TEST_IMAGE_BUILD=${toolchain_build_flag}"],
      stdout: fp"${run_dir}/xsh-build.stdout",
      stderr: fp"${run_dir}/xsh-build.stderr",
    ),
  )?
  if ! build.ok {
    eprint "unable to build the local XSH distribution"
    abort(build.exit_code() ?? 1)
  }
  if ! toolchain_cache_hit {
    fs.write_atomic(toolchain_cache, toolchain_key + "\n")?
  }
  let staged_dir = fp"${factory_dir}/evals/.dist"
  fs.mkdir(staged_dir)?
  let stage_xsh = process.run(process.command_argv(
    "cp", ["cp", "-fL", dist_xsh.display(), fp"${staged_dir}/xsh".display()],
  ))?
  let stage_xsht = process.run(process.command_argv(
    "cp", ["cp", "-fL", dist_xsht.display(), fp"${staged_dir}/xsht".display()],
  ))?
  let stage_control = process.run(process.command_argv(
    "cp", ["cp", "-fL", fp"${factory_dir}/factory_control.xsh".display(), fp"${staged_dir}/factory_control.xsh".display()],
  ))?
  let stage_runtime = process.run(process.command_argv(
    "cp", ["cp", "-fL", fp"${factory_dir}/factory_runtime.xsh".display(), fp"${staged_dir}/factory_runtime.xsh".display()],
  ))?
  let stage_common = process.run(process.command_argv(
    "cp", ["cp", "-fL", fp"${factory_dir}/evaluate_common.xsh".display(), fp"${staged_dir}/evaluate_common.xsh".display()],
  ))?
  if ! stage_xsh.ok or ! stage_xsht.ok or ! stage_control.ok or ! stage_runtime.ok or ! stage_common.ok {
    eprint f"unable to stage local XSH binaries for the ${eval_id} image"
    abort(1)
  }
  var base_args: List[Str] = [docker, "build"]
  if force_image_rebuild {
    base_args = base_args.extend(["--pull", "--no-cache"])
  }
  base_args = base_args.extend([
    "--platform", platform,
    "--build-arg", f"FACTORY_BUILD_ID=${build_id}", "-t", base_image,
    "-f", fp"${factory_dir}/evals/Dockerfile.base".display(), fp"${factory_dir}/evals".display(),
  ])
  let base_status = process.run(process.command_argv(
    docker,
    base_args,
    stdout: fp"${run_dir}/base-image-build.stdout",
    stderr: fp"${run_dir}/base-image-build.stderr",
  ))?
  if ! base_status.ok {
    eprint "unable to build the shared factory eval base image"
    abort(base_status.exit_code() ?? 1)
  }
  let image_status = if image == base_image or ! has_eval_dockerfile {
    process.run(process.command_argv("true", ["true"]))?
  } else {
    process.run(process.command_argv(
      docker,
      [docker].extend(control.eval_overlay_build_args(
        base_image, build_id, image, platform, eval_dockerfile, eval_dir, force_image_rebuild
      )),
      stdout: fp"${run_dir}/image-build.stdout",
      stderr: fp"${run_dir}/image-build.stderr",
    ))?
  }
  if ! image_status.ok {
    eprint f"unable to build the ${eval_id} eval image"
    abort(image_status.exit_code() ?? 1)
  }
  let image_id = run.text docker image inspect "--format" "{{.Id}}" $image ?
  let build_elapsed = time.now() - build_started
  let toolchain_state = if toolchain_cache_hit { "cache-hit" } else { "rebuilt" }
  let image_state = if force_image_rebuild { "forced-rebuild" } else { "cached-build" }
  fs.write(fp"${run_dir}/xsh-build.state",
    f"toolchain=${toolchain_state}\nimage=${image_state}\nbase-image=${base_image}\neval-image=${image}\nbase-tag=${base_tag}\neval-tag=${eval_tag}\nbuild-id=${build_id}\nwall-ms=${build_elapsed}\n")?
  fs.unlock(eval_build_lock)?
  let approved_handbook_sha = hash.sha256(baseline_handbook)?.hex()
  let provenance_values: List[control.TemplateValue] = [
    {key: "RUN_ID", value: run_dir.display()},
    {key: "MODE", value: "eval"},
    {key: "REQUEST", value: "CYCLE-REQUEST.md"},
    {key: "BUILD_ID", value: build_id},
    {key: "XSH_COMMIT", value: xsh_commit.trim()},
    {key: "CANDIDATE_TICKET", value: candidate_ticket},
    {key: "CANDIDATE_WORKTREE", value: candidate_worktree},
    {key: "IMAGE", value: image},
    {key: "IMAGE_ID", value: image_id.trim()},
    {key: "PLATFORM", value: platform},
    {key: "APPROVED_HANDBOOK_SHA", value: approved_handbook_sha},
    {key: "CANDIDATE_HANDBOOK_SHA", value: "pending-manager"},
    {key: "TICKET_SNAPSHOT_SHA", value: "not-ticket-cycle"},
  ]
  fs.write(fp"${run_dir}/PROVENANCE.md", control.fill_template(provenance_template.read_text()?, provenance_values))?

  let xsh_path = process.which("xsh")?
  let run_agent = fp"${factory_dir}/run-agent.xsh"
  let messages_dir = fp"${run_dir}/messages"
  fs.mkdir(messages_dir)?
  var merged_ticket_paths = "none"
  for ticket in merged_tickets {
    if ticket.eval_id != eval_id {
      continue
    }
    let ticket_path = fp"${factory_dir}/tickets/${ticket.ticket_id}.md"
    merged_ticket_paths = if merged_ticket_paths == "none" {
      ticket_path.display()
    } else {
      merged_ticket_paths + ", " + ticket_path.display()
    }
  }
  if new_eval_count > 0 {
    fs.mkdir(fp"${run_dir}/proposals")?
  }

  let trial_template = fp"${factory_dir}/templates/EVAL-TRIAL.md"
  let trial_values: List[control.TemplateValue] = [
    {key: "EVAL_ID", value: eval_id},
    {key: "EVAL_DIR", value: eval_dir.display()},
    {key: "TRIAL_COUNT", value: trial_count.float().format(precision: 0)},
  ]
  let trial_instructions = control.fill_template(trial_template.read_text()?, trial_values)

  let manager_message = fp"${messages_dir}/${eval_id}-manager.md"
  let manager_template = fp"${factory_dir}/templates/EVAL-MANAGER-ASSIGNMENT.md"
  let manager_values: List[control.TemplateValue] = [
    {key: "EVAL_ID", value: eval_id},
    {key: "FACTORY_DIR", value: factory_dir.display()},
    {key: "EVAL_DIR", value: eval_dir.display()},
    {key: "RUN_DIR", value: run_dir.display()},
    {key: "TRIAL_COUNT", value: trial_count.float().format(precision: 0)},
    {key: "TRIAL_INSTRUCTIONS", value: trial_instructions},
    {key: "MERGED_TICKET_PATHS", value: merged_ticket_paths},
    {key: "CANDIDATE_TICKET", value: candidate_ticket},
    {key: "CANDIDATE_WORKTREE", value: candidate_worktree},
    {key: "XSH_COMMIT", value: xsh_commit.trim()},
  ]
  fs.write(manager_message, control.fill_template(manager_template.read_text()?, manager_values))?

  var designer_message = p""
  let designer_worker = "proposal-1"
  let designer_status = if new_eval_count == 1 { "dispatched" } else { "not-requested" }
  if new_eval_count == 1 {
    designer_message = fp"${messages_dir}/eval-designer-${designer_worker}.md"
    let designer_template = fp"${factory_dir}/templates/EVAL-DESIGNER-ASSIGNMENT.md"
    let designer_values: List[control.TemplateValue] = [
      {key: "FACTORY_DIR", value: factory_dir.display()},
      {key: "RUN_DIR", value: run_dir.display()},
      {key: "WORKER_ID", value: designer_worker},
    ]
    fs.write(designer_message, control.fill_template(designer_template.read_text()?, designer_values))?
  }
  let dispatch_values: List[control.TemplateValue] = [
    {key: "EVAL_ID", value: eval_id},
    {key: "TRIAL_COUNT", value: trial_count.float().format(precision: 0)},
    {key: "NEW_EVAL_COUNT", value: new_eval_count.float().format(precision: 0)},
    {key: "XSH_COMMIT", value: xsh_commit.trim()},
    {key: "HANDBOOK_SNAPSHOT", value: baseline_handbook.display()},
    {key: "FACTORY_DIR", value: factory_dir.display()},
    {key: "MANAGER_MESSAGE", value: fp"${messages_dir}/${eval_id}-manager.md".display()},
    {key: "RUN_AGENT", value: run_agent.display()},
    {key: "DESIGNER_STATUS", value: designer_status},
    {key: "DESIGNER_WORKER", value: designer_worker},
    {key: "DESIGNER_MESSAGE", value: if new_eval_count == 1 { designer_message.display() } else { "not-requested" }},
  ]
  let dispatch_template = fp"${factory_dir}/templates/EVAL-DISPATCH.md"
  fs.write(fp"${run_dir}/DISPATCH.md", control.fill_template(dispatch_template.read_text()?, dispatch_values))?
  let director_message = fp"${run_dir}/DIRECTOR-REQUEST.md"
  let director_template = fp"${factory_dir}/templates/DIRECTOR-REQUEST.md"
  let director_values: List[control.TemplateValue] = [
    {key: "FACTORY_DIR", value: factory_dir.display()},
    {key: "RUN_DIR", value: run_dir.display()},
    {key: "RUN_AGENT", value: run_agent.display()},
    {key: "MODE", value: "eval"},
    {key: "DISPATCH_FILE", value: "DISPATCH.md"},
  ]
  fs.write(director_message, control.fill_template(director_template.read_text()?, director_values))?

  let director_env = {
    PATH: env.get("PATH")?,
    HOME: env.get("HOME")?,
    XSH_MODULE_PATH: env.get_or("XSH_MODULE_PATH", factory_dir.display())?,
    FACTORY_DIR: factory_dir.display(),
    FACTORY_RUN_DIR: run_dir.display(),
    FACTORY_RUN_AGENT: run_agent.display(),
    FACTORY_XSH_REPO: xsh_repo.display(),
    FACTORY_XSH_COMMIT: xsh_commit.trim(),
    FACTORY_IMAGE_ID: image_id.trim(),
    FACTORY_MODE: "eval",
    FACTORY_EVAL_ID: eval_id,
    FACTORY_EVAL_DIR: eval_dir.display(),
    FACTORY_EVAL_IMAGE: image,
    FACTORY_BASE_IMAGE: base_image,
    FACTORY_EVAL_TASK_FILE: task_file,
    FACTORY_EVAL_ARTIFACT: artifact_file,
    FACTORY_LINEAGE_DIR: lineage_dir.display(),
    FACTORY_DISPATCH_FILE: fp"${run_dir}/DISPATCH.md".display(),
    FACTORY_TRIAL_COUNT: trial_count.float().format(precision: 0),
    FACTORY_NEW_EVAL_COUNT: new_eval_count.float().format(precision: 0),
    FACTORY_PLATFORM: platform,
    PI_AUTH_FILE: auth_file.display(),
    PI_COMMAND: env.get_or("PI_COMMAND", "pi")?,
    FACTORY_DIRECTOR_PROVIDER: control.configured_role_setting("director", "PROVIDER")?,
    FACTORY_DIRECTOR_MODEL: control.configured_role_setting("director", "MODEL")?,
    FACTORY_DIRECTOR_THINKING: control.configured_role_setting("director", "THINKING")?,
    FACTORY_DIRECTOR_BUDGET_USD: control.configured_role_setting("director", "BUDGET_USD")?,
    FACTORY_DIRECTOR_TOOLS: control.configured_role_setting("director", "TOOLS")?,
    FACTORY_EVAL_DESIGNER_PROVIDER: control.configured_role_setting("eval-designer", "PROVIDER")?,
    FACTORY_EVAL_DESIGNER_MODEL: control.configured_role_setting("eval-designer", "MODEL")?,
    FACTORY_EVAL_DESIGNER_THINKING: control.configured_role_setting("eval-designer", "THINKING")?,
    FACTORY_EVAL_DESIGNER_BUDGET_USD: control.configured_role_setting("eval-designer", "BUDGET_USD")?,
    FACTORY_EVAL_DESIGNER_TOOLS: control.configured_role_setting("eval-designer", "TOOLS")?,
    FACTORY_EVAL_MANAGER_PROVIDER: control.configured_role_setting("eval-manager", "PROVIDER")?,
    FACTORY_EVAL_MANAGER_MODEL: control.configured_role_setting("eval-manager", "MODEL")?,
    FACTORY_EVAL_MANAGER_THINKING: control.configured_role_setting("eval-manager", "THINKING")?,
    FACTORY_EVAL_MANAGER_BUDGET_USD: control.configured_role_setting("eval-manager", "BUDGET_USD")?,
    FACTORY_EVAL_MANAGER_TOOLS: control.configured_role_setting("eval-manager", "TOOLS")?,
    FACTORY_EVAL_WORKER_PROVIDER: control.configured_role_setting("eval-worker", "PROVIDER")?,
    FACTORY_EVAL_WORKER_MODEL: control.configured_role_setting("eval-worker", "MODEL")?,
    FACTORY_EVAL_WORKER_THINKING: control.configured_role_setting("eval-worker", "THINKING")?,
    FACTORY_EVAL_WORKER_BUDGET_USD: control.configured_role_setting("eval-worker", "BUDGET_USD")?,
    FACTORY_EVAL_WORKER_TOOLS: control.configured_role_setting("eval-worker", "TOOLS")?,
    FACTORY_ENGINEER_PROVIDER: control.configured_role_setting("engineer", "PROVIDER")?,
    FACTORY_ENGINEER_MODEL: control.configured_role_setting("engineer", "MODEL")?,
    FACTORY_ENGINEER_THINKING: control.configured_role_setting("engineer", "THINKING")?,
    FACTORY_ENGINEER_BUDGET_USD: control.configured_role_setting("engineer", "BUDGET_USD")?,
    FACTORY_ENGINEER_TOOLS: control.configured_role_setting("engineer", "TOOLS")?,
  }
  runtime.emit_event(event_template, run_dir, "20-manager-started", "eval-manager", "started", 1, "controller", "dispatch row admitted")?
  if new_eval_count == 1 {
    runtime.emit_event(event_template, run_dir, "21-designer-started", "eval-designer", "started", 1, "controller", "dispatch row admitted")?
  }
  runtime.emit_event(event_template, run_dir, "20-director-started", "director", "started", 1, "controller", "dispatching controller-owned eval dispatch")?
  let director_status = process.run(process.command_argv(
    xsh_path,
    [xsh_path.display(), run_agent, "--", "director", "director",
      fp"${factory_dir}/roles/director.md".display(), director_message.display()],
    cwd: factory_dir,
    env: director_env,
  ))?
  runtime.emit_event(event_template, run_dir, "80-director-completed", "director", if director_status.ok { "completed" } else { "failed" }, 1, "director", "director process returned")?

  let cost_status = process.run(process.command_argv(
    xsh_path,
    [xsh_path.display(), fp"${factory_dir}/tools/session-report.xsh", "--", "run", "--run-dir", run_dir.display(),
      "--output", fp"${run_dir}/COST.md".display()],
  ))?
  let manager_session = fp"${run_dir}/workers/eval-manager/${eval_id}/session.jsonl"
  let trial1_report = fp"${run_dir}/workers/eval-worker/${eval_id}-1/EXECUTOR-REPORT.md"
  let trial2_report = fp"${run_dir}/workers/eval-worker/${eval_id}-2/EXECUTOR-REPORT.md"
  let trial1_handbook = fp"${run_dir}/workers/eval-worker/${eval_id}-1/work/handbook.md"
  let trial2_handbook = fp"${run_dir}/workers/eval-worker/${eval_id}-2/work/handbook.md"
  let candidate_exists = fs.exists(candidate_handbook)?
  let trial1_report_ok = fs.exists(trial1_report)? and control.executor_report_contract_ok(fs.read_text(trial1_report)?)
  let trial2_report_ok = if trial_count == 1 {
    true
  } else {
    fs.exists(trial2_report)? and control.executor_report_contract_ok(fs.read_text(trial2_report)?)
  }
  let baseline_sha = approved_handbook_sha
  let candidate_sha = if candidate_exists { hash.sha256(candidate_handbook)?.hex() } else { "" }
  let trial1_sha = if fs.exists(trial1_handbook)? { hash.sha256(trial1_handbook)?.hex() } else { "" }
  let trial2_sha = if fs.exists(trial2_handbook)? { hash.sha256(trial2_handbook)?.hex() } else { "" }
  let approved_snapshot_unchanged = fs.exists(baseline_handbook)? and hash.sha256(baseline_handbook)?.hex() == baseline_sha
  let checked_in_handbook_unchanged = runtime.verify_factory_handbook(factory_dir, baseline_sha)?
  let trial_lineage_ok = if trial_count == 1 {
    candidate_sha == baseline_sha
  } else {
    trial2_sha == candidate_sha
  }
  let lineage_ok = candidate_exists and approved_snapshot_unchanged and checked_in_handbook_unchanged and
    trial1_sha == baseline_sha and trial_lineage_ok
  let director_report = fp"${run_dir}/DIRECTOR-REPORT.md"
  let director_report_marker = fp"${run_dir}/workers/director/director/REPORT-MISSING"
  let director_report_ok = fs.exists(director_report)? and ! fs.exists(director_report_marker)? and
    control.director_report_contract_ok(fs.read_text(director_report)?)
  let manager_report = fp"${run_dir}/workers/eval-manager/${eval_id}/MANAGER-REPORT.md"
  let manager_report_marker = fp"${run_dir}/workers/eval-manager/${eval_id}/REPORT-MISSING"
  let manager_report_ok = fs.exists(manager_report)? and ! fs.exists(manager_report_marker)? and
    control.manager_report_contract_ok(fs.read_text(manager_report)?)
  let designer_session = fp"${run_dir}/workers/eval-designer/${designer_worker}/session.jsonl"
  let designer_worker_report = fp"${run_dir}/workers/eval-designer/${designer_worker}/WORKER-REPORT.md"
  let designer_report = fp"${run_dir}/workers/eval-designer/proposal-1/DESIGNER-REPORT.md"
  let designer_output_ok = if new_eval_count == 0 {
    true
  } else {
    fs.exists(designer_session)? and fs.exists(designer_worker_report)? and
      ! fs.exists(fp"${run_dir}/workers/eval-designer/${designer_worker}/REPORT-MISSING")? and
      fs.exists(designer_report)? and control.designer_report_contract_ok(fs.read_text(designer_report)?)
  }
  if fs.exists(manager_session)? {
    runtime.emit_event(event_template, run_dir, "80-manager-completed", "eval-manager", "completed", 1, "eval-manager", "manager session returned")?
  } else {
    runtime.emit_event(event_template, run_dir, "80-manager-failed", "eval-manager", "failed", 1, "controller", "manager session is missing")?
  }
  if new_eval_count == 1 {
    if designer_output_ok {
      runtime.emit_event(event_template, run_dir, "80-designer-completed", "eval-designer", "completed", 1, "eval-designer", "designer report returned")?
    } else {
      runtime.emit_event(event_template, run_dir, "80-designer-failed", "eval-designer", "failed", 1, "controller", "designer report is missing")?
    }
  }
  let director_state = if fs.exists(fp"${run_dir}/workers/director/director/session.jsonl")? { "present" } else { "missing" }
  let manager_state = if fs.exists(manager_session)? { "present" } else { "missing" }
  let trial1_state = if trial1_report_ok { "pass" } else { "fail" }
  let trial2_state = if trial_count == 1 { "not-requested" } else if trial2_report_ok { "pass" } else { "fail" }
  let lineage_state = if lineage_ok { "pass" } else { "fail" }
  let cost_state = if cost_status.ok { "present" } else { "failed" }
  let designer_state = if new_eval_count == 0 { "not-requested" } else if designer_output_ok { "present" } else { "failed" }
  if manager_report_ok and lineage_ok {
    runtime.emit_event(event_template, run_dir, "85-manager-validated", "eval-manager", "validated", 1, "controller", "manager report and handbook lineage passed")?
  }
  if new_eval_count == 1 and designer_output_ok {
    runtime.emit_event(event_template, run_dir, "85-designer-validated", "eval-designer", "validated", 1, "controller", "designer report contract passed")?
  }
  let lineage_values: List[control.TemplateValue] = [
    {key: "BASELINE_SHA", value: baseline_sha},
    {key: "CANDIDATE_SHA", value: candidate_sha},
    {key: "TRIAL1_SHA", value: trial1_sha},
    {key: "TRIAL2_SHA", value: trial2_sha},
    {key: "APPROVED_SNAPSHOT_UNCHANGED", value: if approved_snapshot_unchanged { "true" } else { "false" }},
    {key: "CHECKED_IN_HANDBOOK_UNCHANGED", value: if checked_in_handbook_unchanged { "true" } else { "false" }},
    {key: "LINEAGE_STATE", value: lineage_state},
  ]
  let lineage_template = fp"${factory_dir}/templates/LINEAGE.md"
  fs.write(fp"${run_dir}/LINEAGE.md", control.fill_template(lineage_template.read_text()?, lineage_values))?
  let audit_status = process.run(process.command_argv(
    xsh_path,
    [xsh_path.display(), fp"${factory_dir}/audit-run.xsh", "--", run_dir.display(), "eval"],
    cwd: factory_dir,
  ))?
  let audit_file = fp"${run_dir}/AUDIT.md"
  let audit_report_ok = audit_status.ok and fs.exists(audit_file)? and
    control.audit_report_contract_ok(fs.read_text(audit_file)?)
  let audit_result = if audit_report_ok { control.audit_result(fs.read_text(audit_file)?) } else { "missing" }
  let audit_pass = audit_report_ok and audit_result == "pass"
  let required = fs.exists(manager_session)? and fs.exists(trial1_report)? and
    (trial_count == 1 or fs.exists(trial2_report)?) and
    cost_status.ok and candidate_exists and lineage_ok and trial1_report_ok and trial2_report_ok and
    director_report_ok and manager_report_ok and designer_output_ok and audit_pass
  let initial_result = if director_status.ok and required { "pass" } else { "fail" }
  let cto_status = runtime.write_cto_report(factory_dir, run_dir, initial_result)?
  let result = if initial_result == "pass" and cto_status { "pass" } else { "fail" }
  if audit_pass {
    runtime.mark_phase_completed(event_template, run_dir, "85-cycle-audited", eval_id,
      1, "controller", "deterministic audit artifact written")?
  } else {
    runtime.emit_event(event_template, run_dir, "85-cycle-audited", eval_id,
      "failed", 1, "controller", "deterministic audit artifact written")?
  }
  let run_template = fp"${factory_dir}/templates/RUN-EVAL.md"
  let run_values: List[control.TemplateValue] = [
    {key: "RUN_ID", value: stamp.float().format(precision: 0)},
    {key: "RESULT", value: result},
    {key: "EVAL_ID", value: eval_id},
    {key: "TRIAL_COUNT", value: trial_count.float().format(precision: 0)},
    {key: "NEW_EVAL_COUNT", value: new_eval_count.float().format(precision: 0)},
    {key: "XSH_COMMIT", value: xsh_commit.trim()},
    {key: "IMAGE", value: image},
    {key: "IMAGE_ID", value: image_id.trim()},
    {key: "BUILD_STATE", value: fp"${run_dir}/xsh-build.state".display()},
    {key: "DIRECTOR_STATE", value: director_state},
    {key: "MANAGER_STATE", value: manager_state},
    {key: "DESIGNER_STATE", value: designer_state},
    {key: "TRIAL1_STATE", value: trial1_state},
    {key: "TRIAL2_STATE", value: trial2_state},
    {key: "LINEAGE_STATE", value: lineage_state},
    {key: "COST_STATE", value: cost_state},
    {key: "AUDIT_STATE", value: if audit_report_ok { "present" } else { "failed" }},
    {key: "AUDIT_RESULT", value: audit_result},
    {key: "CTO_STATE", value: if cto_status { "present" } else { "failed" }},
    {key: "APPROVED_SNAPSHOT_UNCHANGED", value: if approved_snapshot_unchanged { "true" } else { "false" }},
    {key: "CHECKED_IN_HANDBOOK_UNCHANGED", value: if checked_in_handbook_unchanged { "true" } else { "false" }},
    {key: "CANDIDATE_SHA", value: candidate_sha},
    {key: "TRIAL1_SHA", value: trial1_sha},
    {key: "TRIAL2_SHA", value: trial2_sha},
  ]
  let run_report = control.fill_template(run_template.read_text()?, run_values)
  fs.write(fp"${run_dir}/RUN.md", run_report)?
  if result == "pass" {
    runtime.emit_event(event_template, run_dir, "90-cycle-completed", eval_id, "completed", 1, "controller", "run report and cost report written")?
    runtime.emit_event(event_template, run_dir, "95-cycle-validated", eval_id, "validated", 1, "controller", "all required outputs passed")?
  } else {
    runtime.emit_event(event_template, run_dir, "90-cycle-failed", eval_id, "failed", 1, "controller", "one or more required outputs failed")?
  }
  if ! skip_cycle_budget {
    runtime.stop_cycle_budget_watch(run_dir)?
  }
  print f"factory run: ${run_dir} (${result})"
  abort(if result == "pass" { 0 } else { 1 })
}
