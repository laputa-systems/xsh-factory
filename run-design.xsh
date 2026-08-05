##! Standalone eval-design controller.

use factory_control as control
use factory_runtime as runtime
use report_schema as schema

on SIGINT --pre-cancel=0ms [fs, process, env, error] {
  runtime.cleanup_active_run()?
  abort(130)
}

on SIGTERM --pre-cancel=0ms [fs, process, env, error] {
  runtime.cleanup_active_run()?
  abort(143)
}

proc main(...argv: List[Str]) [fs, process, env, time, error, io] {
  if argv.len() < 1 {
    eprint "usage: run-design.xsh CYCLE_REQUEST.md"
    abort(2)
  }
  let factory_dir = env.path("FACTORY_DIR", fs.cwd()?)?
  let request = Path(argv[0])
  let request_text = request.read_text()?
  if control.request_mode(request_text) != "eval-design" {
    eprint "eval-design controller requires a request with mode eval-design"
    abort(2)
  }
  let stamp = time.now()
  let configured_phase_dir = env.get_or("FACTORY_PHASE_DIR", "")?
  let run_dir = if configured_phase_dir == "" {
    fp"${factory_dir}/runs/run-${stamp}"
  } else {
    Path(configured_phase_dir)
  }
  let active_run = env.path("FACTORY_ACTIVE_RUN", fp"${factory_dir}/runs/ACTIVE")?
  let lock_path = env.path("FACTORY_LOCK_PATH", fp"${factory_dir}/runs/factory.lock")?
  let _run_lock = runtime.acquire_run_lock_at(lock_path)?
  let event_template = run_dir
  let assignment_template = fp"${factory_dir}/templates/EVAL-DESIGNER-ASSIGNMENT.md"
  let worker_id = "proposal-1"
  let design_eval_id = control.request_eval(request_text)
  let worker_root = fp"${run_dir}/workers"
  let messages_dir = fp"${run_dir}/messages"
  let proposal_dir = fp"${run_dir}/proposals/${worker_id}"
  let worker_dir = fp"${worker_root}/eval-designer/${worker_id}"
  let session = fp"${worker_dir}/session.jsonl"
  let worker_report = fp"${worker_dir}/report.json"
  let designer_report = fp"${worker_dir}/REPORT.md"
  let xsh_repo = env.path("FACTORY_XSH_REPO", fp"${factory_dir}/../xsh")?
  let xsh_path = process.which("xsh")?
  let run_agent = fp"${factory_dir}/run-agent.xsh"
  let home = env.get("HOME")?
  let auth_file = env.path("PI_AUTH_FILE", fp"${home}/.pi/agent/auth.json")?
  let pi_command = env.get_or("PI_COMMAND", "pi")?
  let platform = env.get_or("FACTORY_PLATFORM", "linux/arm64")?
  fs.mkdir(fp"${factory_dir}/runs")?
  if fs.exists(active_run)? and fs.read_text(active_run)?.trim() != "" {
    eprint "another factory run is already active"
    abort(1)
  }
  fs.mkdir(run_dir)?
  runtime.stage_cto_improvement(factory_dir, run_dir)?
  runtime.register_cycle_controller(run_dir)?
  let skip_cycle_budget = env.get_or("FACTORY_SKIP_CYCLE_BUDGET", "false")? == "true"
  if ! skip_cycle_budget {
    let _cycle_budget_watch = runtime.start_cycle_budget_watch(factory_dir, run_dir)?
  }
  fs.mkdir(worker_root)?
  fs.mkdir(messages_dir)?
  fs.mkdir(fp"${run_dir}/proposals")?
  fs.mkdir(proposal_dir)?
  fs.mkdir(fp"${proposal_dir}/runtime")?
  fs.mkdir(fp"${worker_root}/eval-designer/${worker_id}")?
  let scaffold_source = env.get_or("FACTORY_EVAL_SCAFFOLD", "task-bigfiles")?
  let scaffold_manifest = fp"${factory_dir}/evals/${scaffold_source}/EVAL.md"
  if ! fs.exists(scaffold_manifest)? or control.eval_is_disabled(scaffold_manifest.read_text()?) {
    eprint f"eval-design scaffold is missing or disabled: ${scaffold_source}"
    abort(2)
  }
  let scaffold_dir = fp"${factory_dir}/evals/${scaffold_source}"
  for scaffold in [
    "EVAL.md",
    "executor.xsh",
    "evaluate.xsh",
    "evaluator.xsh",
    "runtime/task.md",
    "runtime/artifact.md",
  ] {
    fs.copy(fp"${scaffold_dir}/${scaffold}",
      fp"${proposal_dir}/${scaffold}", overwrite: true)?
  }
  fs.copy(fp"${factory_dir}/templates/EVAL-DESIGNER-REPORT.md", designer_report, overwrite: true)?
  fs.write(active_run, run_dir.display() + "\n")?
  defer fs.remove(active_run, missing_ok: true)?
  fs.copy(request, fp"${run_dir}/CYCLE-REQUEST.md", overwrite: true)?
  runtime.emit_event(event_template, run_dir, "00-cycle-started", "eval-design", "started", 1, "controller", "standalone eval-design dispatch")?

  let xsh_commit = run.text "git" "-C" $xsh_repo.display() "rev-parse" "HEAD" ?
  let xsh_git_status = run.text "git" "-C" $xsh_repo.display() "status" "--porcelain" ?
  if xsh_git_status.trim() != "" {
    eprint "eval-design requires a clean XSH worktree at admission"
    abort(2)
  }

  let assignment_values: List[control.TemplateValue] = [
    {key: "FACTORY_DIR", value: factory_dir.display()},
    {key: "RUN_DIR", value: run_dir.display()},
    {key: "WORKER_ID", value: worker_id},
  ]
  let assignment = control.fill_template(assignment_template.read_text()?, assignment_values)
  let assignment_path = fp"${messages_dir}/eval-designer-${worker_id}.md"
  fs.write(assignment_path, assignment)?
  runtime.write_dispatch_record(
    run_dir, "eval-designer", worker_id, assignment_path, factory_dir,
    "eval-design", design_eval_id, "", ""
  )?
  let _initial_report = process.run(process.command_argv(
    xsh_path,
    [xsh_path.display(), fp"${factory_dir}/audit-run.xsh", "--", run_dir.display(), "eval-design"],
    cwd: factory_dir,
  ))?

  let worker_env = {
    PATH: env.get("PATH")?,
    HOME: env.get("HOME")?,
    XSH_MODULE_PATH: env.get_or("XSH_MODULE_PATH", factory_dir.display())?,
    FACTORY_DIR: factory_dir.display(),
    FACTORY_RUN_DIR: run_dir.display(),
    FACTORY_RUN_AGENT: run_agent.display(),
    FACTORY_WORKER_DIR: worker_dir.display(),
    FACTORY_ROLE: "eval-designer",
    FACTORY_WORKER_ID: worker_id,
    FACTORY_PARENT_ID: "eval-design-controller",
    FACTORY_MODE: "eval-design",
    FACTORY_EVAL_ID: design_eval_id,
    FACTORY_TICKET_ID: "",
    FACTORY_ASSIGNMENT_SHA: "",
    FACTORY_WORKDIR: factory_dir.display(),
    FACTORY_HANDBOOK_FILE: fp"${factory_dir}/runtime/handbook.md".display(),
    FACTORY_NORTH_STAR_FILE: fp"${factory_dir}/NORTH-STAR.md".display(),
    FACTORY_XSH_REPO: xsh_repo.display(),
    FACTORY_XSH_COMMIT: xsh_commit.trim(),
    FACTORY_IMAGE_ID: "not-used-design-cycle",
    FACTORY_EVAL_DIR: "",
    FACTORY_EVAL_IMAGE: "",
    FACTORY_EVAL_TASK_FILE: "",
    FACTORY_EVAL_ARTIFACT: "",
    FACTORY_LINEAGE_DIR: "",
    FACTORY_PLATFORM: platform,
    PI_AUTH_FILE: auth_file.display(),
    PI_COMMAND: pi_command,
    FACTORY_DIRECTOR_PROVIDER: control.configured_role_setting("director", "PROVIDER")?,
    FACTORY_DIRECTOR_MODEL: control.configured_role_setting("director", "MODEL")?,
    FACTORY_DIRECTOR_THINKING: control.configured_role_setting("director", "THINKING")?,
    FACTORY_DIRECTOR_BUDGET_USD: control.configured_role_setting("director", "BUDGET_USD")?,
    FACTORY_DIRECTOR_MAX_TURNS: control.configured_role_setting("director", "MAX_TURNS")?,
    FACTORY_DIRECTOR_MAX_WALL_SECONDS: control.configured_role_setting("director", "MAX_WALL_SECONDS")?,
    FACTORY_DIRECTOR_TOOLS: control.configured_role_setting("director", "TOOLS")?,
    FACTORY_EVAL_DESIGNER_PROVIDER: control.configured_role_setting("eval-designer", "PROVIDER")?,
    FACTORY_EVAL_DESIGNER_MODEL: control.configured_role_setting("eval-designer", "MODEL")?,
    FACTORY_EVAL_DESIGNER_THINKING: control.configured_role_setting("eval-designer", "THINKING")?,
    FACTORY_EVAL_DESIGNER_BUDGET_USD: control.configured_role_setting("eval-designer", "BUDGET_USD")?,
    FACTORY_EVAL_DESIGNER_MAX_TURNS: control.configured_role_setting("eval-designer", "MAX_TURNS")?,
    FACTORY_EVAL_DESIGNER_MAX_WALL_SECONDS: control.configured_role_setting("eval-designer", "MAX_WALL_SECONDS")?,
    FACTORY_EVAL_DESIGNER_TOOLS: control.configured_role_setting("eval-designer", "TOOLS")?,
    FACTORY_EVAL_MANAGER_PROVIDER: control.configured_role_setting("eval-manager", "PROVIDER")?,
    FACTORY_EVAL_MANAGER_MODEL: control.configured_role_setting("eval-manager", "MODEL")?,
    FACTORY_EVAL_MANAGER_THINKING: control.configured_role_setting("eval-manager", "THINKING")?,
    FACTORY_EVAL_MANAGER_BUDGET_USD: control.configured_role_setting("eval-manager", "BUDGET_USD")?,
    FACTORY_EVAL_MANAGER_MAX_TURNS: control.configured_role_setting("eval-manager", "MAX_TURNS")?,
    FACTORY_EVAL_MANAGER_MAX_WALL_SECONDS: control.configured_role_setting("eval-manager", "MAX_WALL_SECONDS")?,
    FACTORY_EVAL_MANAGER_TOOLS: control.configured_role_setting("eval-manager", "TOOLS")?,
    FACTORY_EVAL_WORKER_PROVIDER: control.configured_role_setting("eval-worker", "PROVIDER")?,
    FACTORY_EVAL_WORKER_MODEL: control.configured_role_setting("eval-worker", "MODEL")?,
    FACTORY_EVAL_WORKER_THINKING: control.configured_role_setting("eval-worker", "THINKING")?,
    FACTORY_EVAL_WORKER_BUDGET_USD: control.configured_role_setting("eval-worker", "BUDGET_USD")?,
    FACTORY_EVAL_WORKER_MAX_TURNS: control.configured_role_setting("eval-worker", "MAX_TURNS")?,
    FACTORY_EVAL_WORKER_MAX_WALL_SECONDS: control.configured_role_setting("eval-worker", "MAX_WALL_SECONDS")?,
    FACTORY_EVAL_WORKER_TOOLS: control.configured_role_setting("eval-worker", "TOOLS")?,
    FACTORY_ENGINEER_PROVIDER: control.configured_role_setting("engineer", "PROVIDER")?,
    FACTORY_ENGINEER_MODEL: control.configured_role_setting("engineer", "MODEL")?,
    FACTORY_ENGINEER_THINKING: control.configured_role_setting("engineer", "THINKING")?,
    FACTORY_ENGINEER_BUDGET_USD: control.configured_role_setting("engineer", "BUDGET_USD")?,
    FACTORY_ENGINEER_MAX_TURNS: control.configured_role_setting("engineer", "MAX_TURNS")?,
    FACTORY_ENGINEER_MAX_WALL_SECONDS: control.configured_role_setting("engineer", "MAX_WALL_SECONDS")?,
    FACTORY_ENGINEER_TOOLS: control.configured_role_setting("engineer", "TOOLS")?,
  }
  runtime.emit_event(event_template, run_dir, "20-designer-started", "eval-designer", "started", 1, "controller", "one proposal row dispatched")?
  runtime.emit_event(event_template, run_dir, "21-proposal-started", "eval-proposal", "started", 1, "controller", "proposal package assigned")?
  let worker_status = process.run(process.command_argv(
    xsh_path,
    [xsh_path.display(), run_agent.display(), "--", "eval-designer", worker_id,
      fp"${factory_dir}/roles/eval-designer.md".display(), assignment_path.display()],
    cwd: factory_dir,
    env: worker_env,
    stdout: fp"${run_dir}/designer.stdout",
    stderr: fp"${run_dir}/designer.stderr",
  ))?
  runtime.emit_event(event_template, run_dir, "80-designer-completed", "eval-designer",
    if worker_status.ok { "completed" } else { "failed" }, 1, "eval-designer", "worker process returned")?
  runtime.emit_event(event_template, run_dir, "81-proposal-completed", "eval-proposal", "completed", 1, "eval-designer", "proposal package produced")?
  let designer_exit = if worker_status.ok { 0 } else { worker_status.exit_code() ?? 1 }
  runtime.emit_process_output(run_dir, "eval-designer-proposal-1", "stdout", fp"${run_dir}/designer.stdout", designer_exit)?
  runtime.emit_process_output(run_dir, "eval-designer-proposal-1", "stderr", fp"${run_dir}/designer.stderr", designer_exit)?

  let session_ok = fs.exists(session)?
  let worker_report_ok = fs.exists(worker_report)? and ! fs.exists(fp"${run_dir}/workers/eval-designer/${worker_id}/REPORT-MISSING")? and
    schema.valid(json.read(worker_report)?, "worker")
  let designer_report_ok = fs.exists(designer_report)? and ! fs.exists(fp"${run_dir}/workers/eval-designer/${worker_id}/REPORT-MISSING")? and
    control.designer_report_contract_ok(designer_report.read_text()?)
  let north_star_read_ok = runtime.session_read_path(session, fp"${factory_dir}/NORTH-STAR.md")?
  let handbook_read_ok = runtime.session_read_path(session, fp"${factory_dir}/runtime/handbook.md")?
  let proposal_ok = fs.exists(proposal_dir)? and fs.exists(fp"${proposal_dir}/EVAL.md")? and
    fs.exists(fp"${proposal_dir}/executor.xsh")? and fs.exists(fp"${proposal_dir}/evaluate.xsh")? and
    fs.exists(fp"${proposal_dir}/runtime/task.md")? and
    fs.exists(fp"${proposal_dir}/runtime/artifact.md")?
  let proposal_complete = proposal_ok and fs.exists(fp"${proposal_dir}/evaluator.xsh")? and
    control.eval_difficulty_contract_ok(fs.read_text(fp"${proposal_dir}/EVAL.md")?)
  let evaluator_source_ok = proposal_complete and
    control.eval_evaluator_package_owned(fs.read_text(fp"${proposal_dir}/evaluator.xsh")?)
  let evaluator_check_ok = if evaluator_source_ok {
    process.run(process.command_argv(
      "xsht", ["xsht", "check", fp"${proposal_dir}/evaluator.xsh".display()],
      cwd: factory_dir,
    ))?.ok
  } else {
    false
  }
  let audit_status = process.run(process.command_argv(
    xsh_path,
    [xsh_path.display(), fp"${factory_dir}/audit-run.xsh", "--", run_dir.display(), "eval-design"],
    cwd: factory_dir,
  ))?
  let audit_file = fp"${run_dir}/report.json"
  let audit_report_ok = audit_status.ok and fs.exists(audit_file)? and
    schema.valid(json.read(audit_file)?, "phase")
  let audit_result = if audit_report_ok { schema.value_text(json.get(json.read(audit_file)?, ["result"], "missing")) } else { "missing" }
  let audit_pass = audit_report_ok and audit_result == "pass"
  let review_result = if designer_report_ok and proposal_complete and evaluator_check_ok and audit_pass { "accepted" } else { "rejected" }
  let promoted = if proposal_ok {
    runtime.promote_eval_proposal(factory_dir, proposal_dir, run_dir, review_result)?
  } else {
    false
  }
  let review_template = fp"${factory_dir}/templates/CTO-EVAL-REVIEW.md"
  let eval_id = if fs.exists(fp"${proposal_dir}/EVAL.md")? {
    control.eval_id_from_contract(fp"${proposal_dir}/EVAL.md".read_text()?)
  } else { "" }
  let proposal_path = control.factory_relative_path(factory_dir.display(), proposal_dir)
  let promoted_path = if eval_id != "" { f"evals/${eval_id}" } else { "not-promoted" }
  let package_state = if proposal_complete { "complete" } else { "incomplete" }
  let missing_package_files = if proposal_complete { "None." } else { "evaluator.xsh (package-owned evaluator)" }
  let promoted_status = if review_result == "accepted" { "Approved." } else { "Draft." }
  let review_reason = if review_result == "accepted" {
    "The designer report, materialized package, evaluator syntax check, required reads, and deterministic audit passed."
  } else {
    "The package was preserved for inspection, but one or more CTO review gates did not pass."
  }
  let promotion_result = if promoted { "completed" } else { "not completed" }
  fs.write(fp"${run_dir}/CTO-EVAL-REVIEW.md", control.fill_template(review_template.read_text()?, [
    {key: "EVAL_ID", value: if eval_id == "" { "unknown" } else { eval_id }},
    {key: "RESULT", value: review_result},
    {key: "REASON", value: review_reason},
    {key: "PROPOSAL_PATH", value: proposal_path},
    {key: "PROMOTION", value: if promoted { "promoted" } else { "not-promoted" }},
    {key: "PROMOTED_PATH", value: promoted_path},
    {key: "STATUS", value: promoted_status},
    {key: "PACKAGE_STATE", value: package_state},
    {key: "MISSING_PACKAGE_FILES", value: missing_package_files},
  ]))?
  runtime.emit_event(event_template, run_dir, "84-cto-reviewed", "eval-proposal",
    if promoted { "validated" } else { "failed" }, 1, "eval-designer",
    f"CTO review ${review_result}; promotion ${promotion_result}")?
  let initial_result = if worker_status.ok and session_ok and worker_report_ok and
    designer_report_ok and proposal_complete and evaluator_check_ok and promoted and north_star_read_ok and handbook_read_ok and audit_pass {
    "pass"
  } else {
    "fail"
  }
  let cto_status = runtime.write_cto_report(factory_dir, run_dir, initial_result)?
  let outcome_note = f"product=${if proposal_complete { "pass" } else { "fail" }}; evaluator=${if evaluator_check_ok { "pass" } else { "fail" }}; infrastructure=${if audit_pass { "pass" } else { "fail" }}"
  let result = if initial_result == "pass" and cto_status { "pass" } else { "fail" }
  if result == "pass" {
    runtime.emit_event(event_template, run_dir, "85-designer-validated", "eval-designer", "validated", 1, "controller", "proposal, reports, reads, cost, and audit passed")?
    runtime.emit_event(event_template, run_dir, "90-cycle-completed", "eval-design", "completed", 1, "controller", outcome_note)?
    runtime.emit_event(event_template, run_dir, "95-cycle-validated", "eval-design", "validated", 1, "controller", "proposal is ready for CTO review")?
  } else {
    runtime.emit_event(event_template, run_dir, "85-designer-failed", "eval-designer", "failed", 1, "controller", "one or more design outputs failed validation")?
    runtime.emit_event(event_template, run_dir, "90-cycle-failed", "eval-design", "failed", 1, "controller", "one or more required outputs failed")?
  }
  if ! skip_cycle_budget {
    runtime.stop_cycle_budget_watch(run_dir)?
  }
  print f"factory run: ${run_dir} (${result})"
  abort(if result == "pass" { 0 } else { 1 })
}
