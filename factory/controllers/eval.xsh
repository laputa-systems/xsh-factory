##! Eval-cycle controller. The parent run.xsh owns signals.
use factory.control as control
use factory.request as typed_request
use factory.runtime as runtime
use factory.schema as schema

proc role_assignments() [env, error] -> Result[List[Str]] {
  var assignments: List[Str] = []
  for role in ["director", "eval-designer", "eval-manager", "eval-worker", "engineer"] {
    let prefix = control.role_prefix(role)
    assignments = assignments.push(f"FACTORY_${prefix}_PROVIDER=${control.configured_role_setting(role, "PROVIDER")?}")
    assignments = assignments.push(f"FACTORY_${prefix}_MODEL=${control.configured_role_setting(role, "MODEL")?}")
    assignments = assignments.push(f"FACTORY_${prefix}_THINKING=${control.configured_role_setting(role, "THINKING")?}")
    assignments = assignments.push(
      f"FACTORY_${prefix}_BUDGET_USD=${control.configured_role_setting(role, "BUDGET_USD")?}",
    )
    assignments = assignments.push(
      f"FACTORY_${prefix}_MAX_TURNS=${control.configured_role_setting(role, "MAX_TURNS")?}",
    )
    assignments = assignments.push(
      f"FACTORY_${prefix}_MAX_WALL_SECONDS=${control.configured_role_setting(role, "MAX_WALL_SECONDS")?}",
    )
    assignments = assignments.push(f"FACTORY_${prefix}_TOOLS=${control.configured_role_setting(role, "TOOLS")?}")
  }

  assignments
}

proc spawn_agent(
  factory_dir: Path,
  run_dir: Path,
  xsh_path: Path,
  run_agent: Path,
  assignments: List[Str],
  role: Str,
  worker_id: Str,
  eval_id: Str,
  system_prompt: Path,
  message: Path,
  stdout: Path,
  stderr: Path,
) [fs, process, error] -> Result[ProcessHandle] {
  let env_path = process.which("env")?
  runtime.write_bound_dispatch_record(
    factory_dir,
    run_dir,
    role,
    worker_id,
    system_prompt,
    message,
    factory_dir,
    "eval",
    eval_id,
    "",
    "",
  )?
  let child_args = assignments.extend(
    [
      xsh_path.display(),
      run_agent.display(),
      "--",
      role,
      worker_id,
      system_prompt.display(),
      message.display(),
    ],
  )
  let handle = spawn process.command_argv(
    env_path,
    [env_path.display()].extend(child_args),
    cwd: factory_dir,
    stdout: stdout,
    stderr: stderr,
  )?
  runtime.register_process(run_dir, f"controller-${role}-${worker_id}", handle.pid)?
  return handle
}

proc report_has_tool_errors(report: Path) [fs, error] -> Result[Bool] {
  if ! fs.exists(report)? {
    return false
  }

  let usage = json.get(json.read(report)?, ["usage"], null)
  return match json.get(usage, ["tool_errors"], 0) {
    i is Int => i > 0,
    _ => false,
  }
}

proc valid_staged_binary(binary_path: Path) [fs, error] -> Result[Bool] {
  if ! fs.exists(binary_path)? {
    return false
  }

  control.eval_binary_size_ok(fs.metadata(binary_path)?.size)
}

proc write_preflight_failure_report(run_dir: Path, eval_id: Str, stage: Str, message: Str) [fs, error] {
  json.write(
    fp"${run_dir}/report.json",
    {
      schema_version: schema.SCHEMA_VERSION,
      kind: "phase",
      identity: {
        run_id: run_dir.name(),
        mode: "eval",
        eval_id: eval_id,
      },
      state: "completed",
      result: "fail",
      data: {
        mode: "eval",
        eval_id: eval_id,
        xsh_commit: "unknown",
        sessions: [],
        workers: [],
        trials: [],
        narratives: [],
        cost: {
          workers: 0,
          assistant_turns: 0,
          total_bucket_tokens: 0,
          cost_usd: 0.0,
          tool_errors: 0,
        },
        tool_errors: [],
      },
      findings: [
        {
          kind: "preflight-failure",
          stage: stage,
          message: message,
        },
      ],
      artifacts: [
        {
          kind: "raw-events",
          path: "events.jsonl",
        },
        {
          kind: "build-log",
          path: f"${stage}-build.stderr",
        },
      ],
    },
    pretty: true,
  )?
}

proc run_executor_trial(
  factory_dir: Path,
  run_dir: Path,
  xsh_path: Path,
  assignments: List[Str],
  eval_id: Str,
  trial_id: Int,
  worker_dir: Path,
  handbook: Path,
  eval_dir: Path,
  image: Str,
  base_image: Str,
  image_id: Str,
  artifact_file: Str,
  lineage_dir: Path,
  stdout: Path,
  stderr: Path,
) [fs, process, error] -> Result[Bool] {
  let env_path = process.which("env")?
  let trial_text = trial_id.float().format(precision: 0)
  let trial_assignments = assignments.extend(
    [
      f"FACTORY_RUN_DIR=${run_dir.display()}",
      f"FACTORY_MODE=eval",
      f"FACTORY_EVAL_ID=${eval_id}",
      f"FACTORY_TRIAL_ID=${trial_text}",
      f"FACTORY_EVAL_WORKER_DIR=${worker_dir.display()}",
      f"FACTORY_HANDBOOK_FILE=${handbook.display()}",
      f"FACTORY_EVAL_DIR=${eval_dir.display()}",
      f"FACTORY_EVAL_IMAGE=${image}",
      f"FACTORY_BASE_IMAGE=${base_image}",
      f"FACTORY_IMAGE_ID=${image_id}",
      f"FACTORY_EVAL_ARTIFACT=${artifact_file}",
      f"FACTORY_LINEAGE_DIR=${lineage_dir.display()}",
    ],
  )
  let trial_args = trial_assignments.extend(
    [
      xsh_path.display(),
      f"${factory_dir}/factory/entrypoints/eval-executor.xsh",
      "--",
      eval_id,
    ],
  )
  let handle = spawn process.command_argv(
    env_path,
    [env_path.display()].extend(trial_args),
    cwd: factory_dir,
    stdout: stdout,
    stderr: stderr,
  )?
  runtime.register_process(run_dir, f"executor-${eval_id}-${trial_id}", handle.pid)?
  let status = wait handle?
  status.ok
}

proc main(...argv: List[Str]) [fs, process, env, time, error, io] {
  if argv.len() < 1 {
    eprint "usage: xsh factory/controllers/eval.xsh CYCLE_REQUEST.md [EVAL_ID]"
    abort(2)
  }

  let factory_dir = env.path("FACTORY_DIR", fs.cwd()?)?
  let expected_source_sha = env.get_or("FACTORY_SOURCE_SHA", "")?
  if expected_source_sha != "" and ! runtime.verify_factory_source(factory_dir, expected_source_sha)? {
    eprint "factory source changed before eval admission"
    abort(1)
  }
  let request = fp"${argv[0]}"
  let request_text = request.read_text()?
  let request_evals = typed_request.eval_values(request_text)?
  let requested_eval = if argv.len() >= 2 { argv[1] } else if request_evals.len() > 0 { request_evals[0] } else { "" }
  let eval_path = fp"${factory_dir}/evals/${requested_eval}/EVAL.md"
  let eval_exists = fs.exists(eval_path)?
  let eval_disabled = eval_exists and control.eval_is_disabled(eval_path.read_text()?)
  if ! control.valid_eval_id(requested_eval) or ! eval_exists or eval_disabled {
    eprint f"cycle request selected unsupported or missing eval: ${requested_eval}"
    abort(2)
  }

  let trial_count = typed_request.trial_value(request_text)?
  if trial_count < 1 or trial_count > 2 {
    eprint f"unsupported trial count: ${trial_count} (expected 1 or 2)"
    abort(2)
  }

  let new_eval_count = typed_request.design_value(request_text)?
  if new_eval_count < 0 or new_eval_count > 1 {
    eprint f"unsupported new eval proposal count: ${new_eval_count} (expected 0 or 1)"
    abort(2)
  }

  let eval_id = requested_eval
  let eval_dir = fp"${factory_dir}/evals/${eval_id}"
  let task_file = "task.md"
  let artifact_file = fs.read_text(fp"${eval_dir}/runtime/artifact.md")?.trim()
  if artifact_file == "" or "/" in artifact_file or "\\" in artifact_file {
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
    fp"${configured_phase_dir}"
  }
  let worker_root = fp"${run_dir}/workers"
  let active_run = env.path("FACTORY_ACTIVE_RUN", fp"${factory_dir}/runs/ACTIVE")?
  let lock_path = env.path("FACTORY_LOCK_PATH", fp"${factory_dir}/runs/factory.lock")?
  let _ = runtime.acquire_run_lock_at(lock_path)?
  let event_template = run_dir
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
  runtime.stage_cto_improvement(factory_dir, run_dir)?
  runtime.register_cycle_controller(run_dir)?
  let skip_cycle_budget = env.get_or("FACTORY_SKIP_CYCLE_BUDGET", "false")? == "true"
  if ! skip_cycle_budget {
    let _ = runtime.start_cycle_budget_watch(factory_dir, run_dir)?
  }

  fs.write(active_run, run_dir.display() + "\n")?
  defer fs.remove(active_run, missing_ok: true)?
  runtime.emit_event(
    event_template,
    run_dir,
    "00-cycle-started",
    eval_id,
    "started",
    1,
    "controller",
    "eval-manager cycle",
  )?
  fs.copy(request, fp"${run_dir}/CYCLE-REQUEST.md", overwrite: true)?
  fs.copy(fp"${factory_dir}/runtime/handbook.md", baseline_handbook, overwrite: true)?

  let xsh_commit = run.text "git" "-C" $xsh_repo "rev-parse" "HEAD" ?
  let skip_reconcile = env.get_or("FACTORY_SKIP_TICKET_RECONCILE", "false")? == "true"
  let merged_tickets = if skip_reconcile {
    []
  } else {
    runtime.reconcile_tickets(factory_dir, xsh_repo, xsh_commit.trim())?
  }
  let factory_control_sha = hash.sha256(fp"${factory_dir}/factory/control.xsh")?.hex()
  let factory_runtime_sha = hash.sha256(fp"${factory_dir}/factory/runtime.xsh")?.hex()
  let factory_schema_sha = hash.sha256(fp"${factory_dir}/factory/schema.xsh")?.hex()
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
  let xsh_git_status = run.text "git" "-C" $xsh_repo "status" "--porcelain" ?
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
  let force_shared_image_rebuild = force_toolchain_rebuild or force_image_rebuild
  let base_tag = control.factory_image_tag(
    xsh_commit.trim(),
    factory_control_sha,
    factory_runtime_sha,
    factory_schema_sha,
    eval_worker_sha,
    base_dockerfile_sha,
    toolchain_dockerfile_sha,
    toolchain_makefile_sha,
    target,
    platform,
    "",
    base_dockerignore_sha,
  )
  let eval_tag = control.factory_image_tag(
    xsh_commit.trim(),
    factory_control_sha,
    factory_runtime_sha,
    factory_schema_sha,
    eval_worker_sha,
    base_dockerfile_sha,
    toolchain_dockerfile_sha,
    toolchain_makefile_sha,
    target,
    platform,
    if has_eval_dockerfile {
      hash.sha256(eval_dockerfile)?.hex()
    } else {
      "none"
    },
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
  let shared_base_image_present = match run.text docker image inspect "--format" "{{.Id}}" $base_image {
    Ok(_) => true,
    Err(_) => false,
  }
  let shared_base_image_cache_hit = control.shared_image_cache_valid(
    force_shared_image_rebuild,
    shared_base_image_present,
  )
  let toolchain_present = if force_toolchain_rebuild {
    false
  } else {
    match run.text docker image inspect "--format" "{{.Os}}/{{.Architecture}}" $toolchain_image {
      Ok(actual_platform) => control.toolchain_image_platform_matches(actual_platform, platform),
      Err(_) => false,
    }
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
  # `dist-Linux-docker` sets CARGO_TARGET_DIR to `<repo>/target`, so Cargo
  # writes the cross-built binaries under `target/<target>/dist`.
  let dist_dir = fp"${xsh_repo}/target/${target}/dist"
  let dist_xsh = fp"${dist_dir}/xsh"
  let dist_xsht = fp"${dist_dir}/xsht"
  let build = if shared_base_image_cache_hit {
    process.run(
      process.command_argv(
        "true",
        ["true"],
        stdout: fp"${run_dir}/xsh-build.stdout",
        stderr: fp"${run_dir}/xsh-build.stderr",
      ),
    )?
  } else {
    process.run(
      process.command_argv(
        "make",
        [
          "make",
          "-C",
          xsh_repo.display(),
          "dist-Linux-docker",
          f"TARGET=${target}",
          f"XSH_TEST_IMAGE=${toolchain_image}",
          f"XSH_TEST_IMAGE_BUILD=${toolchain_build_flag}",
        ],
        stdout: fp"${run_dir}/xsh-build.stdout",
        stderr: fp"${run_dir}/xsh-build.stderr",
      ),
    )?
  }
  if ! build.ok {
    write_preflight_failure_report(run_dir, eval_id, "xsh", "local XSH distribution build failed; see xsh-build.stderr")?
    eprint "unable to build the local XSH distribution"
    abort(build.exit_code() ?? 1)
  }

  if ! toolchain_cache_hit {
    fs.write_atomic(toolchain_cache, toolchain_key + "\n")?
  }

  let base_context = fp"${run_dir}/base-context"
  let staged_dir = fp"${base_context}/.dist"
  var staging_ok = shared_base_image_cache_hit
  if ! shared_base_image_cache_hit {
    fs.mkdir(base_context)?
    fs.mkdir(staged_dir)?
    fs.mkdir(fp"${staged_dir}/factory")?
    fs.copy(
      fp"${factory_dir}/evals/Dockerfile.base",
      fp"${base_context}/Dockerfile.base",
      overwrite: true,
    )?
    fs.copy(
      fp"${factory_dir}/evals/eval-worker.xsh",
      fp"${base_context}/eval-worker.xsh",
      overwrite: true,
    )?
    let stage_xsh = process.run(
      process.command_argv(
        "cp",
        ["cp", "-fL", dist_xsh.display(), fp"${staged_dir}/xsh".display()],
      ),
    )?
    let stage_xsht = process.run(
      process.command_argv(
        "cp",
        ["cp", "-fL", dist_xsht.display(), fp"${staged_dir}/xsht".display()],
      ),
    )?
    let stage_control = process.run(
      process.command_argv(
        "cp",
        ["cp", "-fL", fp"${factory_dir}/factory/control.xsh".display(), fp"${staged_dir}/factory/control.xsh".display()],
      ),
    )?
    let stage_runtime = process.run(
      process.command_argv(
        "cp",
        ["cp", "-fL", fp"${factory_dir}/factory/runtime.xsh".display(), fp"${staged_dir}/factory/runtime.xsh".display()],
      ),
    )?
    let stage_schema = process.run(
      process.command_argv(
        "cp",
        ["cp", "-fL", fp"${factory_dir}/factory/schema.xsh".display(), fp"${staged_dir}/factory/schema.xsh".display()],
      ),
    )?
    staging_ok = stage_xsh.ok and stage_xsht.ok and stage_control.ok and stage_runtime.ok and stage_schema.ok
  }
  if ! staging_ok {
    write_preflight_failure_report(
      run_dir,
      eval_id,
      "staging",
      "staging local XSH binaries or factory modules failed; see xsh-build.stderr",
    )?
    eprint f"unable to stage local XSH binaries for the ${eval_id} image"
    abort(1)
  }

  let staged_binaries_ok = if shared_base_image_cache_hit {
    true
  } else {
    valid_staged_binary(fp"${staged_dir}/xsh")? and valid_staged_binary(fp"${staged_dir}/xsht")?
  }
  if ! staged_binaries_ok {
    write_preflight_failure_report(
      run_dir,
      eval_id,
      "staging",
      "staged xsh/xsht binaries are missing or implausibly small; inspect xsh-build output",
    )?
    eprint "staged XSH binaries failed size validation"
    abort(1)
  }

  var base_args: List[Str] = [docker, "build"]
  if force_image_rebuild {
    base_args = base_args.extend(["--pull", "--no-cache"])
  }

  base_args = base_args.extend(
    [
      "--platform",
      platform,
      "--build-arg",
      f"FACTORY_BUILD_ID=${build_id}",
      "-t",
      base_image,
      "-f",
      fp"${base_context}/Dockerfile.base".display(),
      base_context.display(),
    ],
  )
  let base_status = if shared_base_image_cache_hit {
    process.run(
      process.command_argv(
        "true",
        ["true"],
        stdout: fp"${run_dir}/base-image-build.stdout",
        stderr: fp"${run_dir}/base-image-build.stderr",
      ),
    )?
  } else {
    process.run(
      process.command_argv(
        docker,
        base_args,
        stdout: fp"${run_dir}/base-image-build.stdout",
        stderr: fp"${run_dir}/base-image-build.stderr",
      ),
    )?
  }
  if ! base_status.ok {
    write_preflight_failure_report(
      run_dir,
      eval_id,
      "base-image",
      "shared factory eval base image build failed; see base-image-build.stderr",
    )?
    eprint "unable to build the shared factory eval base image"
    abort(base_status.exit_code() ?? 1)
  }

  let eval_image_present = if image == base_image or ! has_eval_dockerfile {
    true
  } else {
    match run.text docker image inspect "--format" "{{.Id}}" $image {
      Ok(_) => true,
      Err(_) => false,
    }
  }
  let eval_image_cache_hit = control.shared_image_cache_valid(force_image_rebuild, eval_image_present)
  let image_status = if image == base_image or ! has_eval_dockerfile or eval_image_cache_hit {
    process.run(process.command_argv("true", ["true"]))?
  } else {
    process.run(
      process.command_argv(
        docker,
        [docker].extend(
          control.eval_overlay_build_args(
            base_image,
            build_id,
            image,
            platform,
            eval_dockerfile,
            eval_dir,
            force_image_rebuild,
          ),
        ),
        stdout: fp"${run_dir}/image-build.stdout",
        stderr: fp"${run_dir}/image-build.stderr",
      ),
    )?
  }
  if ! image_status.ok {
    write_preflight_failure_report(
      run_dir,
      eval_id,
      "eval-image",
      f"${eval_id} eval image build failed; see image-build.stderr",
    )?
    eprint f"unable to build the ${eval_id} eval image"
    abort(image_status.exit_code() ?? 1)
  }

  let image_id = run.text docker image inspect "--format" "{{.Id}}" $image ?
  let build_elapsed = time.now() - build_started
  let toolchain_state = if shared_base_image_cache_hit {
    "shared-image-cache-hit"
  } else if toolchain_cache_hit {
    "cache-hit"
  } else {
    "rebuilt"
  }
  let image_state = if force_image_rebuild {
    "forced-rebuild"
  } else if shared_base_image_cache_hit or eval_image_cache_hit {
    "shared-image-cache-hit"
  } else {
    "cached-build"
  }
  fs.write(
    fp"${run_dir}/xsh-build.state",
    f"""toolchain=${toolchain_state}
image=${image_state}
base-image=${base_image}
eval-image=${image}
base-tag=${base_tag}
eval-tag=${eval_tag}
build-id=${build_id}
wall-ms=${build_elapsed}
""",
  )?
  fs.unlock(eval_build_lock)?
  let approved_handbook_sha = hash.sha256(baseline_handbook)?.hex()

  let xsh_path = process.which("xsh")?
  let run_agent = fp"${factory_dir}/factory/entrypoints/run-agent.xsh"
  let messages_dir = fp"${run_dir}/messages"
  fs.mkdir(messages_dir)?
  var merged_ticket_paths = "none"
  for ticket in merged_tickets {
    continue when ticket.eval_id != eval_id
    let ticket_path = fp"${factory_dir}/tickets/${ticket.ticket_id}.md"
    merged_ticket_paths = if merged_ticket_paths == "none" { ticket_path.display() } else { merged_ticket_paths + ", " + ticket_path.display() }
  }

  if new_eval_count > 0 {
    fs.mkdir(fp"${run_dir}/proposals")?
  }

  let trial_template = fp"${factory_dir}/templates/EVAL-TRIAL.md"
  let trial_values = [
    {
      key: "EVAL_ID",
      value: eval_id,
    },
    {
      key: "EVAL_DIR",
      value: eval_dir.display(),
    },
    {
      key: "TRIAL_COUNT",
      value: trial_count.float().format(precision: 0),
    },
  ]
  let trial_instructions = control.fill_template(trial_template.read_text()?, trial_values)

  let common_assignments = [
    f"FACTORY_DIR=${factory_dir.display()}",
    f"FACTORY_RUN_DIR=${run_dir.display()}",
    f"FACTORY_RUN_AGENT=${run_agent.display()}",
    f"FACTORY_XSH_REPO=${xsh_repo.display()}",
    f"FACTORY_XSH_COMMIT=${xsh_commit.trim()}",
    f"FACTORY_SOURCE_SHA=${env.get_or("FACTORY_SOURCE_SHA", "")?}",
    f"FACTORY_HANDBOOK_FILE=${baseline_handbook.display()}",
    f"FACTORY_NORTH_STAR_FILE=${factory_dir}/NORTH-STAR.md",
    f"XSH_MODULE_PATH=${factory_dir.display()}",
    f"FACTORY_MODE=eval",
    f"FACTORY_EVAL_ID=${eval_id}",
    "FACTORY_TICKET_ID=",
    f"FACTORY_EVAL_DIR=${eval_dir.display()}",
    f"FACTORY_EVAL_IMAGE=${image}",
    f"FACTORY_BASE_IMAGE=${base_image}",
    f"FACTORY_IMAGE_ID=${image_id.trim()}",
    f"FACTORY_EVAL_TASK_FILE=${task_file}",
    f"FACTORY_EVAL_ARTIFACT=${artifact_file}",
    f"FACTORY_LINEAGE_DIR=${lineage_dir.display()}",
    f"FACTORY_PLATFORM=${platform}",
    f"XSH_TARGET=${target}",
    f"PI_AUTH_FILE=${auth_file.display()}",
    f"PI_COMMAND=${env.get_or("PI_COMMAND", "pi")?}",
    f"DOCKER=${docker}",
  ].extend(role_assignments()?)

  var designer_message = p""
  let designer_worker = "proposal-1"
  if new_eval_count == 1 {
    designer_message = fp"${messages_dir}/eval-designer-${designer_worker}.md"
    let designer_template = fp"${factory_dir}/templates/EVAL-DESIGNER-ASSIGNMENT.md"
    let designer_values = [
      {
        key: "FACTORY_DIR",
        value: factory_dir.display(),
      },
      {
        key: "RUN_DIR",
        value: run_dir.display(),
      },
      {
        key: "WORKER_ID",
        value: designer_worker,
      },
    ]
    fs.write(designer_message, control.fill_template(designer_template.read_text()?, designer_values))?
  }

  let eval_worker_root = fp"${run_dir}/workers/eval-worker"
  fs.mkdir(eval_worker_root)?
  var designer_handle: ProcessHandle? = null
  runtime.emit_event(
    event_template,
    run_dir,
    "10-manager-admitted",
    "eval-manager",
    "admitted",
    1,
    "controller",
    "manager review waits for controller-owned executor evidence",
  )?
  if new_eval_count == 1 {
    runtime.emit_event(
      event_template,
      run_dir,
      "21-designer-started",
      "eval-designer",
      "started",
      1,
      "controller",
      "dispatch row admitted",
    )?
    designer_handle = spawn_agent(
      factory_dir,
      run_dir,
      xsh_path,
      run_agent,
      common_assignments,
      "eval-designer",
      designer_worker,
      eval_id,
      fp"${factory_dir}/roles/eval-designer.md",
      designer_message,
      fp"${run_dir}/designer.stdout",
      fp"${run_dir}/designer.stderr",
    )?
  }

  var trial_statuses: List[Bool] = []
  for trial_id in range(1, trial_count + 1) {
    let trial_worker = fp"${eval_worker_root}/${eval_id}-${trial_id}"
    runtime.emit_event(
      event_template,
      run_dir,
      f"20-trial-${trial_id}-started",
      f"${eval_id}-trial-${trial_id}",
      "started",
      1,
      "controller",
      "controller-owned executor dispatch",
    )?
    let trial_ok = run_executor_trial(
      factory_dir,
      run_dir,
      xsh_path,
      common_assignments,
      eval_id,
      trial_id,
      trial_worker,
      baseline_handbook,
      eval_dir,
      image,
      base_image,
      image_id.trim(),
      artifact_file,
      lineage_dir,
      fp"${run_dir}/trial-${trial_id}.stdout",
      fp"${run_dir}/trial-${trial_id}.stderr",
    )?
    trial_statuses = trial_statuses.push(trial_ok)
    runtime.emit_event(
      event_template,
      run_dir,
      f"80-trial-${trial_id}-completed",
      f"${eval_id}-trial-${trial_id}",
      if trial_ok {
        "completed"
      } else {
        "failed"
      },
      1,
      "controller",
      "executor process returned",
    )?
    let trial_exit = if trial_ok { 0 } else { 1 }
    runtime.emit_process_output(
      run_dir,
      f"${eval_id}-trial-${trial_id}",
      "stdout",
      fp"${run_dir}/trial-${trial_id}.stdout",
      trial_exit,
    )?
    runtime.emit_process_output(
      run_dir,
      f"${eval_id}-trial-${trial_id}",
      "stderr",
      fp"${run_dir}/trial-${trial_id}.stderr",
      trial_exit,
    )?
    runtime.emit_process_output(
      run_dir,
      f"${eval_id}-worker-${trial_id}",
      "stdout",
      fp"${trial_worker}/container.stdout",
      trial_exit,
    )?
    runtime.emit_process_output(
      run_dir,
      f"${eval_id}-worker-${trial_id}",
      "stderr",
      fp"${trial_worker}/container.stderr",
      trial_exit,
    )?
  }

  let _ = process.run(
    process.command_argv(
      xsh_path,
      [xsh_path.display(), fp"${factory_dir}/factory/tools/audit.xsh", "--", run_dir.display(), "eval"],
      cwd: factory_dir,
    ),
  )?
  let manager_message = fp"${messages_dir}/${eval_id}-manager.md"
  let manager_template = fp"${factory_dir}/templates/EVAL-MANAGER-ASSIGNMENT.md"
  let manager_values = [
    {
      key: "EVAL_ID",
      value: eval_id,
    },
    {
      key: "FACTORY_DIR",
      value: factory_dir.display(),
    },
    {
      key: "EVAL_DIR",
      value: eval_dir.display(),
    },
    {
      key: "RUN_DIR",
      value: run_dir.display(),
    },
    {
      key: "TRIAL_COUNT",
      value: trial_count.float().format(precision: 0),
    },
    {
      key: "TRIAL_INSTRUCTIONS",
      value: trial_instructions,
    },
    {
      key: "MERGED_TICKET_PATHS",
      value: merged_ticket_paths,
    },
    {
      key: "CANDIDATE_TICKET",
      value: candidate_ticket,
    },
    {
      key: "CANDIDATE_WORKTREE",
      value: candidate_worktree,
    },
    {
      key: "XSH_COMMIT",
      value: xsh_commit.trim(),
    },
  ]
  fs.write(manager_message, control.fill_template(manager_template.read_text()?, manager_values))?
  runtime.emit_event(
    event_template,
    run_dir,
    "20-manager-started",
    "eval-manager",
    "started",
    1,
    "controller",
    "executor evidence packet is ready for manager review",
  )?
  let manager_handle = spawn_agent(
    factory_dir,
    run_dir,
    xsh_path,
    run_agent,
    common_assignments,
    "eval-manager",
    eval_id,
    eval_id,
    fp"${factory_dir}/roles/eval-manager.md",
    manager_message,
    fp"${run_dir}/manager.stdout",
    fp"${run_dir}/manager.stderr",
  )?
  let manager_status = wait manager_handle?
  let manager_ok = manager_status.ok

  var designer_ok = true
  if designer_handle != null {
    let designer_status = wait designer_handle?
    designer_ok = designer_status.ok
  }

  runtime.emit_event(
    event_template,
    run_dir,
    "80-manager-completed",
    "eval-manager",
    if manager_ok {
      "completed"
    } else {
      "failed"
    },
    1,
    "controller",
    "manager process returned",
  )?
  let manager_exit = if manager_ok { 0 } else { manager_status.exit_code() ?? 1 }
  runtime.emit_process_output(
    run_dir,
    f"eval-manager-${eval_id}",
    "stdout",
    fp"${run_dir}/manager.stdout",
    manager_exit,
  )?
  runtime.emit_process_output(
    run_dir,
    f"eval-manager-${eval_id}",
    "stderr",
    fp"${run_dir}/manager.stderr",
    manager_exit,
  )?
  if new_eval_count == 1 {
    runtime.emit_event(
      event_template,
      run_dir,
      "80-designer-completed",
      "eval-designer",
      if designer_ok {
        "completed"
      } else {
        "failed"
      },
      1,
      "controller",
      "designer process returned",
    )?
    let designer_exit = if designer_ok { 0 } else { 1 }
    runtime.emit_process_output(
      run_dir,
      "eval-designer-proposal-1",
      "stdout",
      fp"${run_dir}/designer.stdout",
      designer_exit,
    )?
    runtime.emit_process_output(
      run_dir,
      "eval-designer-proposal-1",
      "stderr",
      fp"${run_dir}/designer.stderr",
      designer_exit,
    )?
  }

  let _ = process.run(
    process.command_argv(
      xsh_path,
      [xsh_path.display(), fp"${factory_dir}/factory/tools/audit.xsh", "--", run_dir.display(), "eval"],
      cwd: factory_dir,
    ),
  )?
  let manager_session = fp"${run_dir}/workers/eval-manager/${eval_id}/session.jsonl"
  let trial1_report = fp"${run_dir}/workers/eval-worker/${eval_id}-1/report.json"
  let trial2_report = fp"${run_dir}/workers/eval-worker/${eval_id}-2/report.json"
  let trial1_handbook = fp"${run_dir}/workers/eval-worker/${eval_id}-1/work/handbook.md"
  let trial2_handbook = fp"${run_dir}/workers/eval-worker/${eval_id}-2/work/handbook.md"
  let trial1_process_ok = trial_statuses.get(0, false)
  let trial2_process_ok = if trial_count == 1 { true } else { trial_statuses.get(1, false) }
  let candidate_exists = fs.exists(candidate_handbook)?
  let trial1_report_ok = fs.exists(trial1_report)? and schema.valid(json.read(trial1_report)?, "worker")
  let trial2_report_ok = if trial_count == 1 {
    true
  } else {
    fs.exists(trial2_report)? and schema.valid(json.read(trial2_report)?, "worker")
  }
  let baseline_sha = approved_handbook_sha
  let candidate_sha = if candidate_exists { hash.sha256(candidate_handbook)?.hex() } else { "" }
  let trial1_sha = if fs.exists(trial1_handbook)? { hash.sha256(trial1_handbook)?.hex() } else { "" }
  let trial2_sha = if fs.exists(trial2_handbook)? { hash.sha256(trial2_handbook)?.hex() } else { "" }
  let approved_snapshot_unchanged = fs.exists(baseline_handbook)? and hash.sha256(baseline_handbook)?.hex() == baseline_sha
  let checked_in_handbook_unchanged = runtime.verify_factory_handbook(factory_dir, baseline_sha)?
  let trial_lineage_ok = if trial_count == 1 {
    candidate_sha != ""
  } else {
    trial2_sha == baseline_sha
  }
  let lineage_ok = candidate_exists and approved_snapshot_unchanged and checked_in_handbook_unchanged and trial1_sha == baseline_sha and trial_lineage_ok
  let manager_report = fp"${run_dir}/workers/eval-manager/${eval_id}/REPORT.md"
  let manager_report_marker = fp"${run_dir}/workers/eval-manager/${eval_id}/REPORT-MISSING"
  let manager_worker_report = fp"${run_dir}/workers/eval-manager/${eval_id}/report.json"
  var worker_tool_errors = false
  for trial_id in range(1, trial_count + 1) {
    let worker_report = fp"${eval_worker_root}/${eval_id}-${trial_id}/report.json"
    if report_has_tool_errors(worker_report)? {
      worker_tool_errors = true
    }
  }

  let manager_tool_errors = report_has_tool_errors(manager_worker_report)?
  let manager_report_ok = fs.exists(manager_report)? and ! fs.exists(manager_report_marker)? and control.manager_report_gate_ok(
    fs.read_text(manager_report)?,
    worker_tool_errors,
    manager_tool_errors,
  )
  let designer_session = fp"${run_dir}/workers/eval-designer/${designer_worker}/session.jsonl"
  let designer_worker_report = fp"${run_dir}/workers/eval-designer/${designer_worker}/report.json"
  let designer_report = fp"${run_dir}/workers/eval-designer/proposal-1/REPORT.md"
  let worker_handbook_read = fs.exists(fp"${run_dir}/workers/eval-worker/${eval_id}-1/session.jsonl")? and runtime.session_read_path(
    fp"${run_dir}/workers/eval-worker/${eval_id}-1/session.jsonl",
    /work/handbook.md,
  )?
  let manager_evidence_read = runtime.session_read_path(manager_session, fp"${run_dir}/report.json")?
  let manager_handbook_read = runtime.session_read_path(manager_session, baseline_handbook)?
  let designer_handbook_read = if new_eval_count == 0 {
    true
  } else {
    runtime.session_read_path(designer_session, fp"${factory_dir}/runtime/handbook.md")?
  }
  let designer_output_ok = if new_eval_count == 0 {
    true
  } else {
    fs.exists(designer_session)? and fs.exists(designer_worker_report)? and ! fs.exists(
      fp"${run_dir}/workers/eval-designer/${designer_worker}/REPORT-MISSING",
    )? and schema.valid(json.read(designer_worker_report)?, "worker") and fs.exists(designer_report)? and control.designer_report_contract_ok(
      fs.read_text(designer_report)?,
    )
  }
  if manager_report_ok and lineage_ok {
    runtime.emit_event(
      event_template,
      run_dir,
      "85-manager-validated",
      "eval-manager",
      "validated",
      1,
      "controller",
      "manager report and handbook lineage passed",
    )?
  }

  if new_eval_count == 1 and designer_output_ok {
    runtime.emit_event(
      event_template,
      run_dir,
      "85-designer-validated",
      "eval-designer",
      "validated",
      1,
      "controller",
      "designer report contract passed",
    )?
  }

  let audit_status = process.run(
    process.command_argv(
      xsh_path,
      [xsh_path.display(), fp"${factory_dir}/factory/tools/audit.xsh", "--", run_dir.display(), "eval"],
      cwd: factory_dir,
    ),
  )?
  let audit_file = fp"${run_dir}/report.json"
  let audit_report_ok = audit_status.ok and fs.exists(audit_file)? and schema.valid(json.read(audit_file)?, "phase")
  let audit_result = if audit_report_ok {
    schema.value_text(json.get(json.read(audit_file)?, ["result"], "missing"))
  } else {
    "missing"
  }
  let audit_pass = audit_report_ok and audit_result == "pass"
  let required = fs.exists(manager_session)? and trial1_process_ok and trial2_process_ok and fs.exists(trial1_report)? and (trial_count == 1 or fs.exists(
    trial2_report,
  )?) and candidate_exists and lineage_ok and trial1_report_ok and trial2_report_ok and manager_report_ok and designer_output_ok and audit_pass and worker_handbook_read and manager_evidence_read and manager_handbook_read and designer_handbook_read
  json.write(
    fp"${run_dir}/required-outputs.json",
    {
      manager_session: fs.exists(manager_session)?,
      trial1_process: trial1_process_ok,
      trial2_process: trial2_process_ok,
      trial1_report: trial1_report_ok,
      trial2_report: trial2_report_ok,
      candidate_handbook: candidate_exists,
      handbook_lineage: lineage_ok,
      manager_report: manager_report_ok,
      designer_output: designer_output_ok,
      audit: audit_pass,
      worker_handbook_read: worker_handbook_read,
      manager_evidence_read: manager_evidence_read,
      manager_handbook_read: manager_handbook_read,
      designer_handbook_read: designer_handbook_read,
      required: required,
    },
    pretty: true,
  )?
  let _post_required_outputs_audit = process.run(
    process.command_argv(
      xsh_path,
      [xsh_path.display(), fp"${factory_dir}/factory/tools/audit.xsh", "--", run_dir.display(), "eval"],
      cwd: factory_dir,
    ),
  )?
  let _ = _post_required_outputs_audit
  let product_result = if trial1_report_ok and trial2_report_ok { "pass" } else { "fail" }
  let evaluator_result = if trial1_process_ok and trial2_process_ok and manager_report_ok { "pass" } else { "fail" }
  let infrastructure_result = if required { "pass" } else { "fail" }
  let initial_result = if product_result == "pass" and evaluator_result == "pass" and infrastructure_result == "pass" {
    "pass"
  } else {
    "fail"
  }
  let cto_status = runtime.write_cto_report(factory_dir, run_dir, initial_result)?
  let outcome_note = f"product=${product_result}; evaluator=${evaluator_result}; infrastructure=${infrastructure_result}"
  let result = if initial_result == "pass" and cto_status { "pass" } else { "fail" }
  if audit_pass {
    runtime.mark_phase_completed(
      event_template,
      run_dir,
      "85-cycle-audited",
      eval_id,
      1,
      "controller",
      "deterministic audit artifact written",
    )?
  } else {
    runtime.emit_event(
      event_template,
      run_dir,
      "85-cycle-audited",
      eval_id,
      "failed",
      1,
      "controller",
      "deterministic audit artifact written",
    )?
  }

  if result == "pass" {
    runtime.emit_event(
      event_template,
      run_dir,
      "90-cycle-completed",
      eval_id,
      "completed",
      1,
      "controller",
      outcome_note,
    )?
    runtime.emit_event(
      event_template,
      run_dir,
      "95-cycle-validated",
      eval_id,
      "validated",
      1,
      "controller",
      "all required outputs passed",
    )?
  } else {
    runtime.emit_event(
      event_template,
      run_dir,
      "90-cycle-failed",
      eval_id,
      "failed",
      1,
      "controller",
      "one or more required outputs failed",
    )?
  }

  if ! skip_cycle_budget {
    runtime.stop_cycle_budget_watch(run_dir)?
  }

  runtime.compress_run_sessions(run_dir)?
  print f"factory run: ${run_dir} (${result})"
  abort(if result == "pass" { 0 } else { 1 })
}
