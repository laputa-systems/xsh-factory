##! Runs one complete Markdown-directed factory cycle.

proc cleanup_active_run() [fs, process, env, error] -> Result[Unit] {
  let configured_factory = env.get_or("FACTORY_DIR", "")?
  let factory_dir = if configured_factory == "" { fs.cwd()? } else { Path(configured_factory) }
  let active_run = fp"${factory_dir}/runs/ACTIVE"
  if fs.exists(active_run)? {
    let run_text = fs.read_text(active_run)?.trim()
    if run_text != "" {
      let xsh_path = process.which("xsh")?
      let cleanup = fp"${factory_dir}/tools/cleanup-run.xsh"
      let _ = process.run(process.command_argv(
        xsh_path,
        [xsh_path.display(), cleanup.display(), "--", run_text],
      ))?
    }
  }
  return Ok()
}

# A run owns every child process group started by its XSH process. The active
# run registry is also drained here because a Pi worker can launch a nested
# run-agent or Docker client in a new process group that the XSH runtime cannot
# discover through its direct child handle alone.
on SIGINT --pre-cancel=0ms [fs, process, env, error] {
  cleanup_active_run()?
  abort(130)
}

on SIGTERM --pre-cancel=0ms [fs, process, env, error] {
  cleanup_active_run()?
  abort(143)
}

pure supported_eval(eval_id: Str) -> Bool {
  return eval_id == "task-tags" or eval_id == "task-ecount"
}

proc request_eval(request: Path) [fs, error] -> Result[Str] {
  var in_active_evals = false
  for line in request.read_text()?.lines() {
    let trimmed = line.trim()
    if trimmed == "## Active evals" {
      in_active_evals = true
      continue
    }
    if in_active_evals and trimmed.starts_with("## ") {
      return ""
    }
    if in_active_evals and trimmed.starts_with("- `") {
      let parts = trimmed.split("`")
      if parts.len() >= 2 {
        return parts[1]
      }
    }
  }
  return ""
}

proc main(...argv: List[Str]) [fs, process, env, time, error, io] {
  if argv.len() < 1 {
    eprint "usage: xsh run.xsh CYCLE_REQUEST.md [EVAL_ID]"
    abort(2)
  }
  let factory_dir = env.path("FACTORY_DIR", fs.cwd()?)?
  let request = Path(argv[0])
  let requested_eval = if argv.len() >= 2 { argv[1] } else { request_eval(request)? }
  if ! supported_eval(requested_eval) {
    eprint f"cycle request selected unsupported or missing eval: `${requested_eval}`"
    abort(2)
  }
  let eval_id = requested_eval
  let eval_dir = fp"${factory_dir}/evals/${eval_id}"
  let task_file = if eval_id == "task-tags" { "task-tags.md" } else { "task-ecount.md" }
  let artifact_file = if eval_id == "task-tags" { "tag.xsh" } else { "ecount.xsh" }
  let default_image = if eval_id == "task-tags" {
    "xsh-factory-task-tags:latest"
  } else {
    "xsh-factory-task-ecount:latest"
  }
  let image = if eval_id == "task-tags" {
    env.get_or("FACTORY_TASK_TAGS_IMAGE", default_image)?
  } else {
    env.get_or("FACTORY_TASK_ECOUNT_IMAGE", default_image)?
  }
  let home = env.get("HOME")?
  let auth_file = env.path("PI_AUTH_FILE", fp"${home}/.pi/agent/auth.json")?
  let docker = env.get_or("DOCKER", "docker")?
  let platform = env.get_or("FACTORY_PLATFORM", "linux/arm64")?
  let target = env.get_or("XSH_TARGET", "aarch64-unknown-linux-musl")?
  let xsh_repo = env.path("FACTORY_XSH_REPO", fp"${factory_dir}/../xsh")?
  let stamp = time.now()
  let run_dir = fp"${factory_dir}/runs/run-${stamp}"
  let worker_root = fp"${run_dir}/workers"
  let active_run = fp"${factory_dir}/runs/ACTIVE"
  let lineage_dir = fp"${run_dir}/lineage/${eval_id}"
  let baseline_handbook = fp"${lineage_dir}/approved-handbook.md"
  let candidate_handbook = fp"${lineage_dir}/provisional-handbook.md"
  fs.mkdir(fp"${factory_dir}/runs")?
  fs.mkdir(worker_root)?
  fs.mkdir(lineage_dir)?
  fs.write(active_run, run_dir.display() + "\n")?
  defer fs.remove(active_run, missing_ok: true)?
  fs.copy(request, fp"${run_dir}/CYCLE-REQUEST.md", overwrite: true)?
  fs.copy(fp"${eval_dir}/runtime/handbook.md", baseline_handbook, overwrite: true)?

  let xsh_commit = run.text "git" "-C" $xsh_repo.display() "rev-parse" "HEAD" ?
  let xsh_git_status = run.text "git" "-C" $xsh_repo.display() "status" "--porcelain" ?
  let xsh_state = if xsh_git_status.trim() == "" { "clean" } else { "dirty" }
  let dist_dir = fp"${xsh_repo}/target/docker-${target}-release/${target}/dist"
  let dist_xsh = fp"${dist_dir}/xsh"
  let dist_xsht = fp"${dist_dir}/xsht"
  if ! fs.exists(dist_xsh)? or ! fs.exists(dist_xsht)? {
    let build = process.run(
      process.command_argv(
        "make",
        ["make", "-C", xsh_repo.display(), "dist-Linux-docker", f"TARGET=${target}"],
        stdout: fp"${run_dir}/xsh-build.stdout",
        stderr: fp"${run_dir}/xsh-build.stderr",
      ),
    )?
    if ! build.ok {
      eprint "unable to build the local XSH distribution"
      abort(build.exit_code() ?? 1)
    }
  }
  let xsh_sha = hash.sha256(dist_xsh)?.hex()
  let xsht_sha = hash.sha256(dist_xsht)?.hex()
  let staged_dir = fp"${eval_dir}/.dist"
  fs.mkdir(staged_dir)?
  let stage_xsh = process.run(process.command_argv(
    "cp", ["cp", "-fL", dist_xsh.display(), fp"${staged_dir}/xsh".display()],
  ))?
  let stage_xsht = process.run(process.command_argv(
    "cp", ["cp", "-fL", dist_xsht.display(), fp"${staged_dir}/xsht".display()],
  ))?
  if ! stage_xsh.ok or ! stage_xsht.ok {
    eprint f"unable to stage local XSH binaries for the ${eval_id} image"
    abort(1)
  }
  let image_status = process.run(process.command_argv(
    docker,
    [docker, "build", "--platform", platform, "-t", image,
      "-f", fp"${eval_dir}/Dockerfile".display(), eval_dir.display()],
    stdout: fp"${run_dir}/image-build.stdout",
    stderr: fp"${run_dir}/image-build.stderr",
  ))?
  if ! image_status.ok {
    eprint f"unable to build the ${eval_id} eval image"
    abort(image_status.exit_code() ?? 1)
  }
  let image_id = run.text docker image inspect "--format" "{{.Id}}" $image ?
  let provenance = f"# Factory provenance\n\n## Eval\n\n- Eval: `${eval_id}`\n- Cycle request: `CYCLE-REQUEST.md`\n- Image: `${image}`\n- Image ID: `${image_id.trim()}`\n- Platform: `${platform}`\n\n## XSH input\n\n- Repository: `${xsh_repo.display()}`\n- Commit: `${xsh_commit.trim()}`\n- Working tree: `${xsh_state}`\n- Git status: `${xsh_git_status.trim()}`\n- xsh distribution SHA-256: `${xsh_sha}`\n- xsht distribution SHA-256: `${xsht_sha}`\n\n## Handbook lineage\n\n- Approved input: `lineage/${eval_id}/approved-handbook.md`\n- Provisional candidate: `lineage/${eval_id}/provisional-handbook.md`\n"
  fs.write(fp"${run_dir}/PROVENANCE.md", provenance)?

  let xsh_path = process.which("xsh")?
  let run_agent = fp"${factory_dir}/run-agent.xsh"
  let director_message = fp"${run_dir}/DIRECTOR-REQUEST.md"
  fs.write(director_message, f"# Director assignment\n\nRead `NORTH-STAR.md`, the cycle request at `${run_dir}/CYCLE-REQUEST.md`, `PROVENANCE.md`, and the shared Pi-session briefing before running the bounded cycle. The selected eval is `${eval_id}`. The durable objective is to improve XSH and agents' ability to use it.\n\nLaunch its eval-manager with:\n\n```sh\nFACTORY_ROLE=eval-manager FACTORY_WORKER_ID=${eval_id} FACTORY_PARENT_ID=director FACTORY_EVAL_ID=${eval_id} xsh \"${run_agent}\" -- eval-manager ${eval_id} \"${factory_dir}/roles/eval-manager.md\" \"${run_dir}/messages/${eval_id}-manager.md\"\n```\n\nThe manager must run two fresh trials through `${eval_dir}/executor.xsh`: trial 1 with the approved handbook and trial 2 with a provisional handbook candidate, even when the candidate is an unchanged copy. It must write its manager report in `$FACTORY_WORKER_DIR`. If the request asks for a designer, launch it through the same runner after the manager. Do not launch xsh-swe unless an open ticket existed at cycle start. Finish by writing `$FACTORY_RUN_DIR/DIRECTOR-REPORT.md` with the child results, `## North-star impact`, and required-output status.\n")?
  fs.mkdir(fp"${run_dir}/messages")?
  fs.write(fp"${run_dir}/messages/${eval_id}-manager.md", f"# ${eval_id} manager assignment\n\nRead `NORTH-STAR.md`, `roles/pi-session-briefing.md`, `${eval_dir}/EVAL.md`, and `PROVENANCE.md`. The executor is a black box. Run exactly two fresh trials and preserve separate evidence:\n\n## Trial 1\n\nUse the approved handbook snapshot:\n\n```sh\nFACTORY_EVAL_ID=${eval_id} FACTORY_TRIAL_ID=1 FACTORY_EVAL_WORKER_DIR=\"$FACTORY_RUN_DIR/workers/eval-worker/${eval_id}-1\" FACTORY_HANDBOOK_FILE=\"$FACTORY_RUN_DIR/lineage/${eval_id}/approved-handbook.md\" xsh \"${eval_dir}/executor.xsh\"\n```\n\nInspect the executor report, worker report, thinking transcript, evaluator manifest, artifact, and quantitative session results. If a handbook change is justified, write it to `$FACTORY_RUN_DIR/lineage/${eval_id}/provisional-handbook.md`; otherwise copy the approved snapshot there unchanged. Do not edit the approved snapshot or the checked-in eval handbook.\n\n## Trial 2\n\nRun a fresh worker with the provisional snapshot:\n\n```sh\nFACTORY_EVAL_ID=${eval_id} FACTORY_TRIAL_ID=2 FACTORY_EVAL_WORKER_DIR=\"$FACTORY_RUN_DIR/workers/eval-worker/${eval_id}-2\" FACTORY_HANDBOOK_FILE=\"$FACTORY_RUN_DIR/lineage/${eval_id}/provisional-handbook.md\" xsh \"${eval_dir}/executor.xsh\"\n```\n\nCompare the two trials. Classify correctness, restriction, timing, worker friction, handbook guidance, product/tooling defect, harness mismatch, evaluator failure, or noise. Write `$FACTORY_WORKER_DIR/MANAGER-REPORT.md` with both trial results, handbook hashes, effort and thinking metrics, candidate/oracle timing, a `## North-star impact` section, the handbook decision, tickets, and the next replay.\n")?

  let director_env = {
    PATH: env.get("PATH")?,
    HOME: env.get("HOME")?,
    FACTORY_DIR: factory_dir.display(),
    FACTORY_RUN_DIR: run_dir.display(),
    FACTORY_RUN_AGENT: run_agent.display(),
    FACTORY_XSH_REPO: xsh_repo.display(),
    FACTORY_XSH_COMMIT: xsh_commit.trim(),
    FACTORY_XSH_GIT_STATUS: xsh_git_status.trim(),
    FACTORY_XSH_BIN_SHA256: xsh_sha,
    FACTORY_XSHT_BIN_SHA256: xsht_sha,
    FACTORY_IMAGE_ID: image_id.trim(),
    FACTORY_EVAL_ID: eval_id,
    FACTORY_EVAL_DIR: eval_dir.display(),
    FACTORY_EVAL_IMAGE: image,
    FACTORY_EVAL_TASK_FILE: task_file,
    FACTORY_EVAL_ARTIFACT: artifact_file,
    FACTORY_LINEAGE_DIR: lineage_dir.display(),
    FACTORY_TASK_TAGS_IMAGE: env.get_or("FACTORY_TASK_TAGS_IMAGE", "xsh-factory-task-tags:latest")?,
    FACTORY_TASK_ECOUNT_IMAGE: env.get_or("FACTORY_TASK_ECOUNT_IMAGE", "xsh-factory-task-ecount:latest")?,
    FACTORY_PLATFORM: platform,
    PI_AUTH_FILE: auth_file.display(),
    PI_COMMAND: env.get_or("PI_COMMAND", "pi")?,
    FACTORY_DIRECTOR_PROVIDER: env.get_or("FACTORY_DIRECTOR_PROVIDER", "openrouter")?,
    FACTORY_DIRECTOR_MODEL: env.get_or("FACTORY_DIRECTOR_MODEL", "deepseek/deepseek-v4-flash-0731")?,
    FACTORY_DIRECTOR_THINKING: env.get_or("FACTORY_DIRECTOR_THINKING", "high")?,
    FACTORY_DIRECTOR_BUDGET_USD: env.get_or("FACTORY_DIRECTOR_BUDGET_USD", "2")?,
    FACTORY_DIRECTOR_TOOLS: env.get_or("FACTORY_DIRECTOR_TOOLS", "read,write,edit,bash,grep,find,ls")?,
    FACTORY_EVAL_DESIGNER_PROVIDER: env.get_or("FACTORY_EVAL_DESIGNER_PROVIDER", "openrouter")?,
    FACTORY_EVAL_DESIGNER_MODEL: env.get_or("FACTORY_EVAL_DESIGNER_MODEL", "deepseek/deepseek-v4-flash-0731")?,
    FACTORY_EVAL_DESIGNER_THINKING: env.get_or("FACTORY_EVAL_DESIGNER_THINKING", "high")?,
    FACTORY_EVAL_DESIGNER_BUDGET_USD: env.get_or("FACTORY_EVAL_DESIGNER_BUDGET_USD", "2")?,
    FACTORY_EVAL_DESIGNER_TOOLS: env.get_or("FACTORY_EVAL_DESIGNER_TOOLS", "read,write,edit,bash,grep,find,ls")?,
    FACTORY_EVAL_MANAGER_PROVIDER: env.get_or("FACTORY_EVAL_MANAGER_PROVIDER", "openrouter")?,
    FACTORY_EVAL_MANAGER_MODEL: env.get_or("FACTORY_EVAL_MANAGER_MODEL", "deepseek/deepseek-v4-flash-0731")?,
    FACTORY_EVAL_MANAGER_THINKING: env.get_or("FACTORY_EVAL_MANAGER_THINKING", "high")?,
    FACTORY_EVAL_MANAGER_BUDGET_USD: env.get_or("FACTORY_EVAL_MANAGER_BUDGET_USD", "2")?,
    FACTORY_EVAL_MANAGER_TOOLS: env.get_or("FACTORY_EVAL_MANAGER_TOOLS", "read,write,edit,bash,grep,find,ls")?,
    FACTORY_EVAL_WORKER_PROVIDER: env.get_or("FACTORY_EVAL_WORKER_PROVIDER", "openrouter")?,
    FACTORY_EVAL_WORKER_MODEL: env.get_or("FACTORY_EVAL_WORKER_MODEL", "deepseek/deepseek-v4-flash-0731")?,
    FACTORY_EVAL_WORKER_THINKING: env.get_or("FACTORY_EVAL_WORKER_THINKING", "high")?,
    FACTORY_EVAL_WORKER_BUDGET_USD: env.get_or("FACTORY_EVAL_WORKER_BUDGET_USD", "2")?,
    FACTORY_EVAL_WORKER_TOOLS: env.get_or("FACTORY_EVAL_WORKER_TOOLS", "read,write,edit,bash")?,
    FACTORY_XSH_SWE_PROVIDER: env.get_or("FACTORY_XSH_SWE_PROVIDER", "openrouter")?,
    FACTORY_XSH_SWE_MODEL: env.get_or("FACTORY_XSH_SWE_MODEL", "deepseek/deepseek-v4-flash-0731")?,
    FACTORY_XSH_SWE_THINKING: env.get_or("FACTORY_XSH_SWE_THINKING", "high")?,
    FACTORY_XSH_SWE_BUDGET_USD: env.get_or("FACTORY_XSH_SWE_BUDGET_USD", "2")?,
    FACTORY_XSH_SWE_TOOLS: env.get_or("FACTORY_XSH_SWE_TOOLS", "read,write,edit,bash,grep,find,ls")?,
  }
  let director_status = process.run(process.command_argv(
    xsh_path,
    [xsh_path.display(), run_agent, "--", "director", "director",
      fp"${factory_dir}/roles/director.md".display(), director_message.display()],
    env: director_env,
  ))?

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
  let trial1_report_ok = fs.exists(trial1_report)? and fs.read_text(trial1_report)?.contains("## Result\n\npass")
  let trial2_report_ok = fs.exists(trial2_report)? and fs.read_text(trial2_report)?.contains("## Result\n\npass")
  let baseline_sha = hash.sha256(baseline_handbook)?.hex()
  let candidate_sha = if candidate_exists { hash.sha256(candidate_handbook)?.hex() } else { "" }
  let trial1_sha = if fs.exists(trial1_handbook)? { hash.sha256(trial1_handbook)?.hex() } else { "" }
  let trial2_sha = if fs.exists(trial2_handbook)? { hash.sha256(trial2_handbook)?.hex() } else { "" }
  let lineage_ok = candidate_exists and trial1_sha == baseline_sha and trial2_sha == candidate_sha
  let director_report = fp"${run_dir}/DIRECTOR-REPORT.md"
  let director_report_ok = fs.exists(director_report)? and fs.read_text(director_report)?.contains("## North-star impact")
  let manager_report = fp"${run_dir}/workers/eval-manager/${eval_id}/MANAGER-REPORT.md"
  let manager_report_ok = fs.exists(manager_report)? and fs.read_text(manager_report)?.contains("## North-star impact")
  let required = fs.exists(manager_session)? and fs.exists(trial1_report)? and fs.exists(trial2_report)? and
    cost_status.ok and candidate_exists and lineage_ok and trial1_report_ok and trial2_report_ok and
    director_report_ok and manager_report_ok
  let result = if director_status.ok and required { "pass" } else { "fail" }
  let director_state = if fs.exists(fp"${run_dir}/workers/director/director/session.jsonl")? { "present" } else { "missing" }
  let manager_state = if fs.exists(manager_session)? { "present" } else { "missing" }
  let trial1_state = if trial1_report_ok { "pass" } else { "fail" }
  let trial2_state = if trial2_report_ok { "pass" } else { "fail" }
  let lineage_state = if lineage_ok { "pass" } else { "fail" }
  let cost_state = if cost_status.ok { "present" } else { "failed" }
  let run_report = f"# Factory run ${stamp}\n\n## Result\n\n${result}\n\n## North-star status\n\nThis `${eval_id}` cycle measures a practical XSH capability and preserves the evidence needed for durable handbook or product decisions. See `DIRECTOR-REPORT.md` and the manager report for the explicit mission impact.\n\n## Cycle\n\n- Request: `CYCLE-REQUEST.md`\n- Eval: `${eval_id}`\n- XSH repository: `${xsh_repo.display()}`\n- XSH commit: `${xsh_commit.trim()}`\n- Working tree: `${xsh_state}`\n- Image: `${image}`\n- Image ID: `${image_id.trim()}`\n\n## Required outputs\n\n- Director session: `${director_state}`\n- Eval-manager session: `${manager_state}`\n- Trial 1 executor: `${trial1_state}`\n- Trial 2 executor: `${trial2_state}`\n- Handbook lineage: `${lineage_state}`\n- Cost report: `${cost_state}`\n\n## Handbook hashes\n\n- Approved snapshot: `${baseline_sha}`\n- Provisional snapshot: `${candidate_sha}`\n- Trial 1 staged handbook: `${trial1_sha}`\n- Trial 2 staged handbook: `${trial2_sha}`\n\n## Evidence\n\nAll Pi sessions, extracted thinking transcripts, worker reports, evaluator\nmanifests, container logs, and artifacts are under `workers/`. See\n`PROVENANCE.md`, `LINEAGE.md`, and `COST.md` for the run inputs and accounting.\n"
  fs.write(fp"${run_dir}/LINEAGE.md", f"# Handbook lineage\n\n## Eval\n\n`${eval_id}`\n\n## Snapshots\n\n- Approved: `${baseline_sha}`\n- Provisional: `${candidate_sha}`\n- Trial 1 used: `${trial1_sha}`\n- Trial 2 used: `${trial2_sha}`\n\n## Result\n\n`${lineage_state}`\n\nTrial 1 must use the approved snapshot and trial 2 must use the provisional snapshot.\n")?
  fs.write(fp"${run_dir}/RUN.md", run_report)?
  print f"factory run: ${run_dir} (${result})"
  abort(if result == "pass" { 0 } else { 1 })
}
