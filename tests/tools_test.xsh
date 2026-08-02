##! Native tests for factory tools. These fixtures use synthetic sessions and
##! harmless subprocesses; they never launch Pi.

use factory_control as control
use factory_runtime as runtime

proc test_session_report_uses_synthetic_pi_session(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "session-report")?
  let session = fp"${root}/session.jsonl"
  let report = fp"${root}/WORKER-REPORT.md"
  let tool = fp"${fs.cwd()?}/tools/session-report.xsh"
  fs.write(session, r"""
{"timestamp":"2026-08-01T12:00:00.000Z","type":"message","message":{"role":"user","content":"task"}}
{"timestamp":"2026-08-01T12:00:01.000Z","type":"message","message":{"role":"assistant","provider":"openrouter","model":"deepseek/deepseek-v4-flash-0731","stopReason":"toolUse","content":[{"type":"thinking","thinking":"inspect the fixture"},{"type":"toolCall","name":"read"}],"usage":{"input":10,"output":20,"reasoning":7,"totalTokens":30,"cost":{"input":0.001,"output":0.002,"total":0.003}}}}
{"timestamp":"2026-08-01T12:00:02.000Z","type":"message","message":{"role":"toolResult","isError":false,"usage":{"input":2,"output":3,"totalTokens":5,"cost":{"total":0.0005}}}}
""")?
  let xsh = process.which("xsh")?
  let status = process.run(process.command_argv(
    xsh,
    [xsh.display(), tool.display(), "--", "worker", "--session", session.display(),
      "--output", report.display(), "--role", "eval-worker", "--worker-id", "fixture",
      "--budget-usd", "2"],
  ))?
  test.ok(status.ok, "session-report should accept a well-formed synthetic session")?
  let rendered = fs.read_text(report)?
  let thinking = fs.read_text(fp"${root}/thinking.md")?
  test.contains(rendered, "Assistant turns: 1")?
  test.contains(rendered, "Reasoning/thinking tokens (provider subset of output): 7")?
  test.contains(rendered, "Budget: $0.50")?
  test.contains(rendered, "Budget status: pass")?
  test.contains(thinking, "inspect the fixture")?
}

proc test_aggregate_cost_report_uses_role_budgets(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "aggregate-budgets")?
  let director = fp"${root}/workers/director/director"
  let manager = fp"${root}/workers/eval-manager/task-ecount"
  let worker = fp"${root}/workers/eval-worker/task-ecount-1"
  for directory in [director, manager, worker] {
    fs.mkdir(directory)?
  }
  let session = r"""
{"timestamp":"2026-08-01T12:00:00.000Z","type":"message","message":{"role":"user","content":"task"}}
{"timestamp":"2026-08-01T12:00:01.000Z","type":"message","message":{"role":"assistant","provider":"openrouter","model":"deepseek/deepseek-v4-flash-0731","stopReason":"stop","content":[{"type":"thinking","thinking":"fixture"}],"usage":{"input":10,"output":20,"reasoning":7,"totalTokens":30,"cost":{"total":0.003}}}}
"""
  for directory in [director, manager, worker] {
    fs.write(fp"${directory}/session.jsonl", session)?
  }
  let output = fp"${root}/COST.md"
  let xsh = process.which("xsh")?
  let status = process.run(process.command_argv(
    xsh,
    [xsh.display(), fp"${fs.cwd()?}/tools/session-report.xsh", "--", "run",
      "--run-dir", root.display(), "--output", output.display()],
  ))?
  test.ok(status.ok, "aggregate cost report should render")?
  let rendered = fs.read_text(output)?
  test.contains(rendered, "| `director` | `director` |")?
  test.contains(rendered, "| `eval-manager` | `task-ecount` |")?
  test.contains(rendered, "| `eval-worker` | `task-ecount-1` |")?
  test.contains(rendered, "| $0.06 |")?
  test.contains(rendered, "| $0.15 |")?
  test.contains(rendered, "| $0.50 |")?
  test.ok(! rendered.contains("$2.00"))?
}

proc test_eval_image_stages_shared_factory_modules(ctx: TestContext) [fs, error] {
  let factory = fs.cwd()?
  let dockerfile = fs.read_text(fp"${factory}/evals/Dockerfile.base")?
  let controller = fs.read_text(fp"${factory}/run-eval.xsh")?
  test.contains(dockerfile, ".dist/factory_control.xsh")?
  test.contains(dockerfile, ".dist/factory_runtime.xsh")?
  test.contains(controller, "stage_control")?
  test.contains(controller, "stage_runtime")?
  let _ = ctx
}

proc test_engineer_patch_artifact_survives_worktree_cleanup(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "engineer-patch-cleanup")?
  let product = fp"${root}/xsh"
  let worktree = fp"${root}/worktree"
  let patch_file = fp"${root}/patches/task.diff"
  let patch_stderr = fp"${root}/patches/task.stderr"
  fs.mkdir(fp"${root}/patches")?
  fs.mkdir(product)?
  let init = process.run(process.command_argv("git", ["git", "-C", product.display(), "init", "-b", "main"]))?
  test.ok(init.ok, "fixture product repository should initialize")?
  for setting in [["user.email", "factory@test.invalid"], ["user.name", "Factory Test"]] {
    let configured = process.run(process.command_argv("git", ["git", "-C", product.display(), "config", setting[0], setting[1]]))?
    test.ok(configured.ok, "fixture repository should have an author")?
  }
  fs.write(fp"${product}/README", "base\n")?
  let base_commit_status = process.run(process.command_argv("git", ["git", "-C", product.display(), "add", "README"]))?
  test.ok(base_commit_status.ok)?
  let base_commit_write = process.run(process.command_argv("git", ["git", "-C", product.display(), "commit", "-m", "base"]))?
  test.ok(base_commit_write.ok)?
  let base = run.text "git" "-C" $product.display() "rev-parse" "HEAD" ?
  let branch = "factory/test-patch"
  let add_worktree = process.run(process.command_argv(
    "git", ["git", "-C", product.display(), "worktree", "add", "-b", branch, worktree.display(), base.trim()],
  ))?
  test.ok(add_worktree.ok, "fixture engineer worktree should initialize")?
  fs.write(fp"${worktree}/README", "base\nchanged\n")?
  let add_change = process.run(process.command_argv("git", ["git", "-C", worktree.display(), "add", "README"]))?
  test.ok(add_change.ok)?
  let commit_change = process.run(process.command_argv("git", ["git", "-C", worktree.display(), "commit", "-m", "change"]))?
  test.ok(commit_change.ok)?
  let head = run.text "git" "-C" $worktree.display() "rev-parse" "HEAD" ?
  let patch_ok = runtime.write_engineer_patch(worktree, base.trim(), head.trim(), patch_file, patch_stderr)?
  test.ok(patch_ok, "validated engineer output should produce a non-empty patch")?
  test.contains(fs.read_text(patch_file)?, "+changed")?
  test.ok(runtime.remove_clean_worktree(product, worktree)?, "clean engineer worktree should be removable")?
  test.ok(! fs.exists(worktree)?, "worktree contents should be removed")?
  let branches = run.text "git" "-C" $product.display() "branch" "--list" $branch ?
  test.contains(branches, branch, "review branch must survive worktree cleanup")?
}

proc test_run_dispatcher_fails_preflight_before_agent_launch(ctx: TestContext) [fs, process, env, error] {
  let root = test.temp_dir(ctx, name: "dispatcher-preflight")?
  let request = fp"${root}/cycle.md"
  fs.write(request, "# Cycle\n\n## Mode\n\n- `organization`\n\n## Active evals\n\n- `task-ecount`\n\n## Trial plan\n\n- Count: `1`\n\n## New eval proposals\n\n- Count: `1`\n")?
  let xsh = process.which("xsh")?
  let factory_dir = fs.cwd()?
  let status = process.run(process.command_argv(
    xsh,
    [xsh.display(), fp"${factory_dir}/run.xsh".display(), "--", request.display()],
    cwd: factory_dir,
    env: {
      PATH: env.get("PATH")?,
      HOME: env.get("HOME")?,
      FACTORY_DIR: root.display(),
      XSH_MODULE_PATH: factory_dir.display(),
    },
  ))?
  test.ok(! status.ok, "dispatcher should stop before workers when XSH repo admission fails")?
  test.ok(! fs.exists(fp"${root}/runs/ORGANIZATION-ACTIVE")?)?
}

proc test_disabled_eval_is_rejected_before_executor_launch(ctx: TestContext) [fs, process, env, error] {
  let root = test.temp_dir(ctx, name: "disabled-eval")?
  let factory = fs.cwd()?
  fs.mkdir(fp"${root}/evals/task-tags")?
  fs.write(fp"${root}/evals/task-tags/EVAL.md", "# Eval task-tags\n\n## Status\n\nDisabled.\n")?
  let request = fp"${root}/cycle.md"
  fs.write(request, "# Cycle\n\n## Mode\n\n- `eval`\n\n## Active evals\n\n- `task-tags`\n")?
  let xsh = process.which("xsh")?
  let status = process.run(process.command_argv(
    xsh,
    [xsh.display(), fp"${factory}/run-eval.xsh".display(), "--", request.display()],
    cwd: root,
    env: {
      PATH: env.get("PATH")?,
      FACTORY_DIR: root.display(),
      XSH_MODULE_PATH: factory.display(),
    },
  ))?
  test.ok(! status.ok, "disabled eval must be rejected before launching a worker")?
  test.ok(! fs.exists(fp"${root}/runs/ACTIVE")?)?
}

proc test_organization_overlaps_design_with_primary_using_fake_children(ctx: TestContext) [fs, process, env, error] {
  let root = test.temp_dir(ctx, name: "organization-schedule")?
  let factory = fs.cwd()?
  fs.mkdir(fp"${root}/evals")?
  fs.mkdir(fp"${root}/runtime")?
  fs.mkdir(fp"${root}/tools")?
  let copied_templates = fs.copy_tree(fp"${factory}/templates", fp"${root}/templates")?
  let copied_eval = fs.copy_tree(fp"${factory}/evals/task-tags", fp"${root}/evals/task-tags")?
  fs.copy(fp"${factory}/NORTH-STAR.md", fp"${root}/NORTH-STAR.md", overwrite: true)?
  fs.copy(fp"${factory}/runtime/handbook.md", fp"${root}/runtime/handbook.md", overwrite: true)?
  fs.copy(fp"${factory}/tools/session-report.xsh", fp"${root}/tools/session-report.xsh", overwrite: true)?
  fs.copy(fp"${factory}/tools/cto-report.xsh", fp"${root}/tools/cto-report.xsh", overwrite: true)?

  let fake_child = fp"${root}/fake-child.sh"
  fs.write(fake_child, r"""#!/bin/sh
set -eu
printf 'start:%s\n' "$FACTORY_PHASE_DIR" >> "$FACTORY_TEST_LOG"
sleep 1
printf 'end:%s\n' "$FACTORY_PHASE_DIR" >> "$FACTORY_TEST_LOG"
cp "$FACTORY_TEST_REPORT" "$FACTORY_PHASE_DIR/RUN.md"
cp "$FACTORY_TEST_REPORT" "$FACTORY_PHASE_DIR/RUN-DESIGN.md"
""")?
  let chmod = process.run(process.command_argv("chmod", ["chmod", "+x", fake_child.display()]))?
  test.ok(chmod.ok, "fake organization child should be executable")?
  let request = fp"${root}/cycle.md"
  fs.copy(fp"${factory}/tests/fixtures/organization-no-ticket.md", request, overwrite: true)?
  let log = fp"${root}/schedule.log"
  let report = fp"${factory}/tests/fixtures/organization-pass.md"
  let xsh = process.which("xsh")?
  let product = fp"${root}/xsh"
  fs.mkdir(product)?
  fs.write(fp"${product}/README", "base\n")?
  let product_init = process.run(process.command_argv(
    "git", ["git", "-C", product.display(), "init", "-b", "main"],
  ))?
  test.ok(product_init.ok, "fake product repository should initialize")?
  for setting in [["user.email", "factory-test@example.invalid"], ["user.name", "Factory Test"]] {
    let configured = process.run(process.command_argv(
      "git", ["git", "-C", product.display(), "config", setting[0], setting[1]],
    ))?
    test.ok(configured.ok, "fake product git identity should configure")?
  }
  let product_commit = process.run(process.command_argv(
    "git", ["git", "-C", product.display(), "add", "README"],
  ))?
  test.ok(product_commit.ok)?
  let product_commit_write = process.run(process.command_argv(
    "git", ["git", "-C", product.display(), "commit", "-m", "base"],
  ))?
  test.ok(product_commit_write.ok)?
  let status = process.run(process.command_argv(
    xsh,
    [xsh.display(), fp"${factory}/run-organization.xsh".display(), "--", request.display()],
    cwd: root,
    env: {
      PATH: env.get("PATH")?,
      HOME: env.get("HOME")?,
      FACTORY_DIR: root.display(),
      XSH_MODULE_PATH: factory.display(),
      FACTORY_XSH_REPO: product.display(),
      FACTORY_CHILD_RUNNER: "/bin/sh",
      FACTORY_PRIMARY_CONTROLLER: fake_child.display(),
      FACTORY_DESIGN_CONTROLLER: fake_child.display(),
      FACTORY_TEST_LOG: log.display(),
      FACTORY_TEST_REPORT: report.display(),
    },
  ))?
  test.ok(status.ok, "fake organization cycle should complete")?
  let schedule = fs.read_text(log)?
  let first_start = schedule.find("start:")
  let second_start = schedule.find("start:", first_start + 1)
  let first_end = schedule.find("end:")
  test.ok(first_start >= 0 and second_start > first_start, "both phases should start")?
  test.ok(first_end > second_start, "design and primary must overlap")?
}

proc test_organization_skips_design_when_request_count_is_zero(ctx: TestContext) [fs, process, env, error] {
  let root = test.temp_dir(ctx, name: "organization-no-design")?
  let factory = fs.cwd()?
  fs.mkdir(fp"${root}/evals")?
  fs.mkdir(fp"${root}/runtime")?
  fs.mkdir(fp"${root}/tools")?
  let _copied_templates = fs.copy_tree(fp"${factory}/templates", fp"${root}/templates")?
  let _copied_eval = fs.copy_tree(fp"${factory}/evals/task-tags", fp"${root}/evals/task-tags")?
  fs.copy(fp"${factory}/NORTH-STAR.md", fp"${root}/NORTH-STAR.md", overwrite: true)?
  fs.copy(fp"${factory}/runtime/handbook.md", fp"${root}/runtime/handbook.md", overwrite: true)?
  fs.copy(fp"${factory}/tools/session-report.xsh", fp"${root}/tools/session-report.xsh", overwrite: true)?
  fs.copy(fp"${factory}/tools/cto-report.xsh", fp"${root}/tools/cto-report.xsh", overwrite: true)?

  let fake_child = fp"${root}/fake-child.sh"
  fs.write(fake_child, r"""#!/bin/sh
set -eu
printf 'start:%s\n' "$FACTORY_PHASE_DIR" >> "$FACTORY_TEST_LOG"
printf 'end:%s\n' "$FACTORY_PHASE_DIR" >> "$FACTORY_TEST_LOG"
cp "$FACTORY_TEST_REPORT" "$FACTORY_PHASE_DIR/RUN.md"
""")?
  let chmod = process.run(process.command_argv("chmod", ["chmod", "+x", fake_child.display()]))?
  test.ok(chmod.ok, "fake organization child should be executable")?
  let request = fp"${root}/cycle.md"
  fs.copy(fp"${factory}/tests/fixtures/organization-no-design.md", request, overwrite: true)?
  let log = fp"${root}/schedule.log"
  let report = fp"${factory}/tests/fixtures/organization-pass.md"
  let xsh = process.which("xsh")?
  let product = fp"${root}/xsh"
  fs.mkdir(product)?
  fs.write(fp"${product}/README", "base\n")?
  let product_init = process.run(process.command_argv(
    "git", ["git", "-C", product.display(), "init", "-b", "main"],
  ))?
  test.ok(product_init.ok, "fake product repository should initialize")?
  for setting in [["user.email", "factory-test@example.invalid"], ["user.name", "Factory Test"]] {
    let configured = process.run(process.command_argv(
      "git", ["git", "-C", product.display(), "config", setting[0], setting[1]],
    ))?
    test.ok(configured.ok, "fake product git identity should configure")?
  }
  let product_commit = process.run(process.command_argv(
    "git", ["git", "-C", product.display(), "add", "README"],
  ))?
  test.ok(product_commit.ok)?
  let product_commit_write = process.run(process.command_argv(
    "git", ["git", "-C", product.display(), "commit", "-m", "base"],
  ))?
  test.ok(product_commit_write.ok)?
  let status = process.run(process.command_argv(
    xsh,
    [xsh.display(), fp"${factory}/run-organization.xsh".display(), "--", request.display()],
    cwd: root,
    env: {
      PATH: env.get("PATH")?,
      HOME: env.get("HOME")?,
      FACTORY_DIR: root.display(),
      XSH_MODULE_PATH: factory.display(),
      FACTORY_XSH_REPO: product.display(),
      FACTORY_CHILD_RUNNER: "/bin/sh",
      FACTORY_PRIMARY_CONTROLLER: fake_child.display(),
      FACTORY_DESIGN_CONTROLLER: fake_child.display(),
      FACTORY_TEST_LOG: log.display(),
      FACTORY_TEST_REPORT: report.display(),
      FACTORY_SKIP_CYCLE_BUDGET: "true",
    },
  ))?
  test.ok(status.ok, "organization cycle without eval design should complete")?
  let schedule = fs.read_text(log)?
  let start_count = schedule.lines() |> where .starts_with("start:") |> count()
  test.eq(start_count, 1, "zero new eval proposals should launch only the primary phase")?
  test.ok(! schedule.contains("eval-design"), "zero new eval proposals should not launch eval-design")?
  var run_dir: Path? = null
  for entry in fs.children(fp"${root}/runs", ordered: true)? {
    if entry.name.starts_with("run-") {
      run_dir = entry.path
    }
  }
  test.ok(run_dir != null, "organization run directory should exist")?
  let run_path = run_dir ?? Path("")
  let run_report = fs.read_text(fp"${run_path}/RUN.md")?
  test.contains(run_report, "Eval design: `not-requested`")?
  test.contains(fs.read_text(fp"${run_path}/ORGANIZATION-PLAN.md")?, "Run eval-design phase when requested: `not-requested`")?
  test.ok(! fs.exists(fp"${run_path}/phase-requests/02-eval-design.md")?, "design request should not be materialized")?
}

proc test_organization_overlaps_independent_eval_with_ticket(ctx: TestContext) [fs, process, env, error] {
  let root = test.temp_dir(ctx, name: "organization-ticket-overlap")?
  let factory = fs.cwd()?
  fs.mkdir(fp"${root}/evals")?
  fs.mkdir(fp"${root}/runtime")?
  fs.mkdir(fp"${root}/tools")?
  fs.mkdir(fp"${root}/tickets")?
  let _copied_templates = fs.copy_tree(fp"${factory}/templates", fp"${root}/templates")?
  let _copied_eval = fs.copy_tree(fp"${factory}/evals/task-tags", fp"${root}/evals/task-tags")?
  fs.copy(fp"${factory}/NORTH-STAR.md", fp"${root}/NORTH-STAR.md", overwrite: true)?
  fs.copy(fp"${factory}/runtime/handbook.md", fp"${root}/runtime/handbook.md", overwrite: true)?
  fs.copy(fp"${factory}/tools/session-report.xsh", fp"${root}/tools/session-report.xsh", overwrite: true)?
  fs.copy(fp"${factory}/tools/cto-report.xsh", fp"${root}/tools/cto-report.xsh", overwrite: true)?
  fs.copy(fp"${factory}/tests/fixtures/organization-ticket-overlap-ticket.md",
    fp"${root}/tickets/task-overlap.md", overwrite: true)?
  let fake_child = fp"${root}/fake-child.sh"
  fs.copy(fp"${factory}/tests/fixtures/fake-organization-ticket-overlap.sh", fake_child, overwrite: true)?
  let chmod = process.run(process.command_argv("chmod", ["chmod", "+x", fake_child.display()]))?
  test.ok(chmod.ok, "fake overlap child should be executable")?
  let request = fp"${root}/cycle.md"
  fs.copy(fp"${factory}/tests/fixtures/organization-ticket-overlap.md", request, overwrite: true)?
  let log = fp"${root}/schedule.log"
  let report = fp"${factory}/tests/fixtures/organization-pass.md"
  let product = fp"${root}/xsh"
  fs.mkdir(product)?
  fs.write(fp"${product}/README", "base\n")?
  test.ok((process.run(process.command_argv(
    "git", ["git", "-C", product.display(), "init", "-b", "main"],
  ))?).ok, "fake product repository should initialize")?
  for setting in [["user.email", "factory-test@example.invalid"], ["user.name", "Factory Test"]] {
    test.ok((process.run(process.command_argv(
      "git", ["git", "-C", product.display(), "config", setting[0], setting[1]],
    ))?).ok, "fake product git identity should configure")?
  }
  test.ok((process.run(process.command_argv(
    "git", ["git", "-C", product.display(), "add", "README"],
  ))?).ok)?
  test.ok((process.run(process.command_argv(
    "git", ["git", "-C", product.display(), "commit", "-m", "base"],
  ))?).ok)?
  let xsh = process.which("xsh")?
  let status = process.run(process.command_argv(
    xsh,
    [xsh.display(), fp"${factory}/run-organization.xsh".display(), "--", request.display()],
    cwd: root,
    env: {
      PATH: env.get("PATH")?,
      HOME: env.get("HOME")?,
      FACTORY_DIR: root.display(),
      XSH_MODULE_PATH: factory.display(),
      FACTORY_XSH_REPO: product.display(),
      FACTORY_CHILD_RUNNER: "/bin/sh",
      FACTORY_PRIMARY_CONTROLLER: fake_child.display(),
      FACTORY_EVAL_CONTROLLER: fake_child.display(),
      FACTORY_REEVAL_CONTROLLER: fake_child.display(),
      FACTORY_TEST_LOG: log.display(),
      FACTORY_TEST_REPORT: report.display(),
      FACTORY_SKIP_CYCLE_BUDGET: "true",
    },
  ))?
  test.ok(status.ok, "ticket overlap cycle should complete")?
  let schedule = fs.read_text(log)?
  let primary_start = schedule.find("start:", 0)
  let independent_start = schedule.find("start:", primary_start + 1)
  let primary_end = schedule.find("end:", 0)
  test.ok(primary_start >= 0 and independent_start > primary_start, "ticket and independent eval should both start")?
  test.ok(primary_end > independent_start, "independent eval should start before ticket implementation ends")?
}

proc test_audit_run_preserves_separate_evaluator_outcomes(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "audit-run")?
  let run_dir = fp"${root}/run-1"
  let director_dir = fp"${run_dir}/workers/director/director"
  let manager_dir = fp"${run_dir}/workers/eval-manager/task-tags"
  let worker_dir = fp"${run_dir}/workers/eval-worker/task-tags-1"
  fs.mkdir(director_dir)?
  fs.mkdir(manager_dir)?
  fs.mkdir(worker_dir)?
  fs.write(fp"${run_dir}/CYCLE-REQUEST.md", "# Cycle\n\n## Active evals\n\n- `task-tags`\n\n## Trial plan\n\n- Count: `1`\n\n## New eval proposals\n\n- Count: `0`\n")?

  let provenance_template = fs.read_text(fp"${fs.cwd()?}/templates/PROVENANCE.md")?
  fs.write(fp"${run_dir}/PROVENANCE.md", control.fill_template(provenance_template, [
    {key: "RUN_ID", value: run_dir.display()},
    {key: "MODE", value: "eval"},
    {key: "REQUEST", value: "CYCLE-REQUEST.md"},
    {key: "BUILD_ID", value: "fixture-build"},
    {key: "XSH_COMMIT", value: "fixture-xsh"},
    {key: "CANDIDATE_TICKET", value: "not-reevaluation"},
    {key: "CANDIDATE_WORKTREE", value: "not-reevaluation"},
    {key: "IMAGE", value: "fixture-image"},
    {key: "IMAGE_ID", value: "fixture-image-id"},
    {key: "PLATFORM", value: "fixture-platform"},
    {key: "APPROVED_HANDBOOK_SHA", value: "approved"},
    {key: "CANDIDATE_HANDBOOK_SHA", value: "candidate"},
    {key: "TICKET_SNAPSHOT_SHA", value: "not-ticket-cycle"},
  ]))?
  let lineage_template = fs.read_text(fp"${fs.cwd()?}/templates/LINEAGE.md")?
  fs.write(fp"${run_dir}/LINEAGE.md", control.fill_template(lineage_template, [
    {key: "BASELINE_SHA", value: "approved"},
    {key: "CANDIDATE_SHA", value: "candidate"},
    {key: "TRIAL1_SHA", value: "approved"},
    {key: "TRIAL2_SHA", value: "not-requested"},
    {key: "APPROVED_SNAPSHOT_UNCHANGED", value: "true"},
    {key: "CHECKED_IN_HANDBOOK_UNCHANGED", value: "true"},
    {key: "LINEAGE_STATE", value: "pass"},
  ]))?
  fs.write(fp"${run_dir}/COST.md", "# Run cost report\n\n## Workers\n\nfixture\n\n## Role totals\n\nfixture\n\n## Run total\n\nfixture\n\n- Budget failures or unknown costs: 0\n")?
  fs.write(fp"${run_dir}/DIRECTOR-REPORT.md", "# Director report\n\n## Result\n\npass\n\n## Cycle\n\nfixture\n\n## Children\n\nfixture\n\n## Required-output status\n\npass\n\n## North-star impact\n\nfixture\n")?
  fs.write(fp"${run_dir}/workers/eval-manager/task-tags/MANAGER-REPORT.md", "# Manager report\n\n## Result\n\npass\n\n## Effort metrics\n\nfixture\n\n## Usage and cost\n\nfixture\n\n## Thinking evidence\n\nfixture\n\n## Timing evidence\n\nfixture\n\n## Observation classification\n\nfixture\n\n## Handbook decision\n\nfixture\n\n## Tickets created\n\nfixture\n\n## Post-merge decisions\n\nfixture\n\n## Next replay\n\nfixture\n\n## North-star impact\n\nfixture\n")?

  let session_text = r"""
{"timestamp":"2026-08-01T12:00:00.000Z","type":"message","message":{"role":"user","content":"fixture"}}
{"timestamp":"2026-08-01T12:00:01.000Z","type":"message","message":{"role":"assistant","provider":"openrouter","model":"deepseek/deepseek-v4-flash-0731","stopReason":"stop","content":[{"type":"thinking","thinking":"fixture"}],"usage":{"input":1,"output":2,"reasoning":1,"totalTokens":3,"cost":{"total":0.001}}}}
"""
  for target in [director_dir, manager_dir, worker_dir] {
    fs.write(fp"${target}/session.jsonl", session_text)?
  }
  let xsh = process.which("xsh")?
  for entry in [
    {path: director_dir, role: "director", worker: "director"},
    {path: manager_dir, role: "eval-manager", worker: "task-tags"},
    {path: worker_dir, role: "eval-worker", worker: "task-tags-1"},
  ] {
    let report_status = process.run(process.command_argv(
      xsh,
      [xsh.display(), fp"${fs.cwd()?}/tools/session-report.xsh", "--", "worker",
        "--session", fp"${entry.path}/session.jsonl".display(),
        "--output", fp"${entry.path}/WORKER-REPORT.md".display(),
        "--role", entry.role, "--worker-id", entry.worker,
        "--budget-usd", if entry.role == "director" { "0.06" } else if entry.role == "eval-manager" { "0.15" } else { "0.50" }],
    ))?
    test.ok(report_status.ok, "synthetic worker report should render")?
  }
  fs.write(fp"${worker_dir}/EXECUTOR-REPORT.md", "# Executor report\n\n## Result\n\npass\n\n## Failure classification\n\npass\n\n## Trial\n\n1\n\n## Artifact\n\npresent\n\n## Evidence\n\nfixture\n")?
  fs.write(fp"${worker_dir}/run.json", r"""
{
  "eval_id": "task-tags",
  "trial_id": "1",
  "result": "pass",
  "classification": "pass",
  "inputs": {"handbook_sha256": "approved"},
  "outputs": {"candidate_sha256": "candidate-output", "oracle_sha256": "oracle-output"},
  "protocol": {"artifact_present": true, "review_ok": true},
  "correctness": {"all_exact": true},
  "restrictions": {"passed": true},
  "timings": {"candidate_wall_ns": 100, "oracle_wall_ns": 100, "ratio": 1.0}
}
""")?

  let audit_tool = fp"${fs.cwd()?}/audit-run.xsh"
  let first = process.run(process.command_argv(
    xsh, [xsh.display(), audit_tool.display(), "--", run_dir.display(), "eval"],
  ))?
  test.ok(first.ok, "audit generation should succeed for valid evidence")?
  let audit = fs.read_text(fp"${run_dir}/AUDIT.md")?
  test.ok(control.audit_report_contract_ok(audit))?
  test.eq(control.audit_result(audit), "pass")?
  test.contains(audit, "protocol=pass; correctness=true; restrictions=true")?
  test.contains(audit, "timing=ratio=1.000; gate=unknown")?

  fs.write(fp"${manager_dir}/REPORT-MISSING", "required report missing\n")?
  let marker_audit_status = process.run(process.command_argv(
    xsh, [xsh.display(), audit_tool.display(), "--", run_dir.display(), "eval"],
  ))?
  test.ok(marker_audit_status.ok, "audit should still render marker evidence")?
  let marker_audit = fs.read_text(fp"${run_dir}/AUDIT.md")?
  test.eq(control.audit_result(marker_audit), "fail")?
  fs.remove(fp"${manager_dir}/REPORT-MISSING")?

  fs.write(fp"${worker_dir}/run.json", r"""
{
  "eval_id": "task-tags",
  "trial_id": "1",
  "result": "fail",
  "classification": "protocol_failed",
  "inputs": {"handbook_sha256": "approved"},
  "outputs": {"candidate_sha256": "candidate-output", "oracle_sha256": "oracle-output"},
  "protocol": {"artifact_present": true, "review_ok": false},
  "correctness": {"all_exact": true},
  "restrictions": {"passed": true},
  "timings": {"candidate_wall_ns": 100, "oracle_wall_ns": 100}
}
""")?
  let second = process.run(process.command_argv(
    xsh, [xsh.display(), audit_tool.display(), "--", run_dir.display(), "eval"],
  ))?
  test.ok(second.ok, "audit generation should preserve failed evidence")?
  let failed_audit = fs.read_text(fp"${run_dir}/AUDIT.md")?
  test.eq(control.audit_result(failed_audit), "fail")?
  test.contains(failed_audit, "protocol=fail; correctness=true; restrictions=true")?
  test.contains(failed_audit, "classification=protocol_failed")?
}

proc test_budget_watch_terminates_a_harmless_fake_worker(ctx: TestContext) [fs, process, error] {
  # The sleep process is the test double for Pi: it has a real PID for the
  # process-list boundary, but no agent, network, or model is involved.
  let root = test.temp_dir(ctx, name: "budget-watch")?
  let session = fp"${root}/session.jsonl"
  let marker = fp"${root}/budget.marker"
  let tool = fp"${fs.cwd()?}/tools/budget-watch.xsh"
  fs.write(session, "{\"message\":{\"usage\":{\"cost\":{\"total\":1.25}}}}\n")?
  let child = process.spawn(process.command_argv("sh", ["sh", "-c", "sleep 5"]))?
  let xsh = process.which("xsh")?
  let status = process.run(process.command_argv(
    xsh,
    [xsh.display(), tool.display(), "--", "--session", session.display(),
      "--pid", f"${child.pid}", "--budget-usd", "1.00", "--marker", marker.display()],
  ))?
  test.ok(status.exited_with(3), "budget breach should use the documented exit code")?
  test.ok(fs.exists(marker)?, "budget breach should leave a durable marker")?
  test.contains(fs.read_text(marker)?, "budget exceeded: 1.250000 > 1.00")?
}

proc test_cycle_budget_watch_writes_postmortem_and_cleans_process_tree(ctx: TestContext) [fs, process, env, error] {
  let root = test.temp_dir(ctx, name: "cycle-budget-breach")?
  let run_dir = fp"${root}/run"
  let worker_dir = fp"${run_dir}/workers/eval-worker/task-tags-1"
  let processes = fp"${run_dir}/processes"
  let session = fp"${worker_dir}/session.jsonl"
  let marker = fp"${run_dir}/AGGREGATE-BUDGET-BREACH"
  let stop = fp"${run_dir}/AGGREGATE-BUDGET-STOP"
  let postmortem = fp"${run_dir}/POSTMORTEM.md"
  let factory = fs.cwd()?
  let tool = fp"${factory}/tools/cycle-budget-watch.xsh"
  fs.mkdir(worker_dir)?
  fs.mkdir(processes)?
  fs.write(session, r"""
{"message":{"usage":{"cost":{"total":0.30}}}}
{"message":{"usage":{"cost":{"total":0.25}}}}
""")?
  let child = spawn process.command_argv("sh", ["sh", "-c", "sleep 5"])?
  fs.write(fp"${processes}/controller.pids", f"${child.pid}\n")?
  let xsh = process.which("xsh")?
  let status = process.run(process.command_argv(
    xsh,
    [xsh.display(), tool.display(), "--", "--run-dir", run_dir.display(),
      "--pid", f"${child.pid}", "--budget-usd", "0.50", "--marker", marker.display(),
      "--stop", stop.display(), "--postmortem", postmortem.display()],
    cwd: factory,
    env: {
      PATH: env.get("PATH")?,
      FACTORY_DIR: factory.display(),
      XSH_MODULE_PATH: factory.display(),
    },
  ))?
  test.ok(status.exited_with(3), "aggregate budget breach should use exit code 3")?
  test.ok(fs.exists(marker)?, "aggregate breach should leave a durable marker")?
  test.contains(fs.read_text(marker)?, "budget exceeded: 0.550000 > 0.50")?
  test.ok(fs.exists(postmortem)?, "aggregate breach should write a postmortem")?
  test.contains(fs.read_text(postmortem)?, "Hard cap: `$0.50`")?
  test.contains(fs.read_text(postmortem)?, "Observed spend: `$0.550000`")?
  let child_status = wait child?
  test.ok(! child_status.ok, "aggregate cleanup should terminate the registered controller")?
  test.ok(! (process.list()? |> any .pid == child.pid), "aggregate cleanup should terminate the registered controller")?
}

proc test_cycle_budget_watch_stops_cleanly_without_breach(ctx: TestContext) [fs, process, env, time, error] {
  let root = test.temp_dir(ctx, name: "cycle-budget-stop")?
  let run_dir = fp"${root}/run"
  let worker_dir = fp"${run_dir}/workers/eval-worker/task-tags-1"
  let session = fp"${worker_dir}/session.jsonl"
  let marker = fp"${run_dir}/AGGREGATE-BUDGET-BREACH"
  let stop = fp"${run_dir}/AGGREGATE-BUDGET-STOP"
  let postmortem = fp"${run_dir}/POSTMORTEM.md"
  let factory = fs.cwd()?
  let tool = fp"${factory}/tools/cycle-budget-watch.xsh"
  fs.mkdir(worker_dir)?
  fs.write(session, "{\"message\":{\"usage\":{\"cost\":{\"total\":0.10}}}}\n")?
  let child = spawn process.command_argv("sh", ["sh", "-c", "sleep 5"])?
  let xsh = process.which("xsh")?
  let watcher = spawn process.command_argv(
    xsh,
    [xsh.display(), tool.display(), "--", "--run-dir", run_dir.display(),
      "--pid", f"${child.pid}", "--budget-usd", "0.50", "--marker", marker.display(),
      "--stop", stop.display(), "--postmortem", postmortem.display()],
    cwd: factory,
    env: {
      PATH: env.get("PATH")?,
      FACTORY_DIR: factory.display(),
      XSH_MODULE_PATH: factory.display(),
    },
  )?
  time.sleep(150ms)?
  fs.write_atomic(stop, "normal controller shutdown\n")?
  let watcher_status = wait watcher?
  test.ok(watcher_status.ok, "normal stop should let the aggregate watcher exit cleanly")?
  test.ok(! fs.exists(marker)?, "normal stop should not create a breach marker")?
  test.ok(! fs.exists(postmortem)?, "normal stop should not create a postmortem")?
  test.ok(process.list()? |> any .pid == child.pid, "normal stop should not kill the controller")?
  let kill_status = process.kill(child.pid, signal: "TERM")
  let child_status = wait child?
}

proc test_cycle_budget_watch_fails_closed_on_unknown_cost(ctx: TestContext) [fs, process, env, error] {
  let root = test.temp_dir(ctx, name: "cycle-budget-unknown")?
  let run_dir = fp"${root}/run"
  let worker_dir = fp"${run_dir}/workers/eval-worker/task-tags-1"
  let session = fp"${worker_dir}/session.jsonl"
  let marker = fp"${run_dir}/AGGREGATE-BUDGET-BREACH"
  let stop = fp"${run_dir}/AGGREGATE-BUDGET-STOP"
  let postmortem = fp"${run_dir}/POSTMORTEM.md"
  let factory = fs.cwd()?
  let tool = fp"${factory}/tools/cycle-budget-watch.xsh"
  fs.mkdir(worker_dir)?
  fs.write(session, "{\"message\":{\"usage\":{\"input\":10}}}\n")?
  let child = spawn process.command_argv("sh", ["sh", "-c", "sleep 5"])?
  let xsh = process.which("xsh")?
  let status = process.run(process.command_argv(
    xsh,
    [xsh.display(), tool.display(), "--", "--run-dir", run_dir.display(),
      "--pid", f"${child.pid}", "--budget-usd", "0.50", "--marker", marker.display(),
      "--stop", stop.display(), "--postmortem", postmortem.display()],
    cwd: factory,
    env: {
      PATH: env.get("PATH")?,
      FACTORY_DIR: factory.display(),
      XSH_MODULE_PATH: factory.display(),
    },
  ))?
  test.ok(status.exited_with(3), "unknown cost should stop the cycle")?
  test.contains(fs.read_text(marker)?, "budget exceeded: unknown > 0.50")?
  test.contains(fs.read_text(postmortem)?, "Observed spend: `$unknown`")?
  let child_status = wait child?
  test.ok(! child_status.ok, "unknown cost shutdown should terminate the controller")?
}

proc test_cycle_budget_watch_fails_closed_on_missing_run_tree(ctx: TestContext) [fs, process, env, error] {
  let root = test.temp_dir(ctx, name: "cycle-budget-missing-tree")?
  let run_dir = fp"${root}/run-that-disappeared"
  let marker = fp"${root}/AGGREGATE-BUDGET-BREACH"
  let stop = fp"${root}/AGGREGATE-BUDGET-STOP"
  let postmortem = fp"${root}/POSTMORTEM.md"
  let factory = fs.cwd()?
  let tool = fp"${factory}/tools/cycle-budget-watch.xsh"
  let child = spawn process.command_argv("sh", ["sh", "-c", "sleep 5"])?
  let xsh = process.which("xsh")?
  let status = process.run(process.command_argv(
    xsh,
    [xsh.display(), tool.display(), "--", "--run-dir", run_dir.display(),
      "--pid", f"${child.pid}", "--budget-usd", "0.50", "--marker", marker.display(),
      "--stop", stop.display(), "--postmortem", postmortem.display()],
    cwd: factory,
    env: {
      PATH: env.get("PATH")?,
      FACTORY_DIR: factory.display(),
      XSH_MODULE_PATH: factory.display(),
    },
  ))?
  test.ok(status.exited_with(3), "missing run evidence should stop the cycle")?
  test.contains(fs.read_text(marker)?, "budget exceeded: unknown > 0.50")?
  test.contains(fs.read_text(postmortem)?, "aggregate cost evidence could not be enumerated")?
  let child_status = wait child?
  test.ok(! child_status.ok, "missing run evidence shutdown should terminate the controller")?
}

proc test_cycle_budget_is_wired_once_per_top_level_controller(ctx: TestContext) [fs, error] {
  let factory = fs.cwd()?
  for controller in ["run-ticket.xsh", "run-eval.xsh", "run-design.xsh", "run-organization.xsh"] {
    let source = fs.read_text(fp"${factory}/${controller}")?
    test.contains(source, "runtime.start_cycle_budget_watch")?
    test.contains(source, "runtime.stop_cycle_budget_watch")?
    test.contains(source, "runtime.register_cycle_controller")?
    test.contains(source, "runtime.write_cto_report")?
    test.contains(source, "CTO_STATE")?
  }
  let organization = fs.read_text(fp"${factory}/run-organization.xsh")?
  test.contains(organization, "FACTORY_SKIP_CYCLE_BUDGET=true")?
  let dispatcher = fs.read_text(fp"${factory}/run.xsh")?
  test.contains(dispatcher, "templates/POSTMORTEM.md")?
  test.contains(dispatcher, "top-level dispatcher cannot disable the aggregate cycle budget")?
  let _ = ctx
}

proc test_cto_report_consolidates_phases_costs_and_employee_decisions(ctx: TestContext) [fs, process, env, error] {
  let root = test.temp_dir(ctx, name: "cto-report")?
  let run_dir = fp"${root}/run-1"
  let manager_dir = fp"${run_dir}/workers/eval-manager/task-tags"
  let designer_dir = fp"${run_dir}/workers/eval-designer/proposal-1"
  let phase_dir = fp"${run_dir}/phases/eval"
  fs.mkdir(manager_dir)?
  fs.mkdir(designer_dir)?
  fs.mkdir(phase_dir)?
  fs.write(fp"${run_dir}/CYCLE-REQUEST.md", fs.read_text(fp"${fs.cwd()?}/tests/fixtures/organization-no-ticket.md")?)?
  fs.write(fp"${run_dir}/AUDIT.md", "# Factory audit\n\n## Result\n\npass\n")?
  fs.write(fp"${run_dir}/PROVENANCE.md", "# Factory provenance\n")?
  fs.write(fp"${run_dir}/RUN.md", "# Organization run\n\n## Result\n\npass\n")?
  fs.write(fp"${run_dir}/phases/eval/RUN.md", "# Factory run\n\n## Result\n\npass\n")?
  let fixtures = fp"${fs.cwd()?}/tests/fixtures"
  fs.copy(fp"${fixtures}/cto-report-cost.md", fp"${run_dir}/COST.md", overwrite: true)?
  fs.copy(fp"${fixtures}/cto-report-director.md", fp"${run_dir}/DIRECTOR-REPORT.md", overwrite: true)?
  fs.copy(fp"${fixtures}/cto-report-manager.md", fp"${manager_dir}/MANAGER-REPORT.md", overwrite: true)?
  fs.copy(fp"${fixtures}/cto-report-designer.md", fp"${designer_dir}/DESIGNER-REPORT.md", overwrite: true)?
  let output = fp"${run_dir}/CTO-REPORT.md"
  let xsh = process.which("xsh")?
  let factory = fs.cwd()?
  let status = process.run(process.command_argv(
    xsh,
    [xsh.display(), fp"${factory}/tools/cto-report.xsh".display(), "--",
      "--run-dir", run_dir.display(), "--output", output.display(), "--result", "pass"],
    cwd: factory,
    env: {
      PATH: env.get("PATH")?,
      FACTORY_DIR: factory.display(),
      XSH_MODULE_PATH: factory.display(),
    },
  ))?
  test.ok(status.ok, "CTO briefing should render from deterministic run evidence")?
  let rendered = fs.read_text(output)?
  test.contains(rendered, "# CTO briefing run-1")?
  test.contains(rendered, "Mode: `organization`")?
  test.contains(rendered, "- Role: `director`")?
  test.contains(rendered, "- Role: `eval-manager`")?
  test.contains(rendered, "- Role: `eval-designer`")?
  test.contains(rendered, "eval-manager/task-tags")?
  test.contains(rendered, "Total provider cost: `$0.12`")?
  test.contains(rendered, "Open task-tags-003 for a reproducible follow-up.")?
  test.contains(rendered, "Proposal is ready for review.")?
}

proc test_eval_executor_disables_eval_when_mock_worker_breaches_budget(ctx: TestContext) [fs, process, env, error] {
  let root = test.temp_dir(ctx, name: "eval-budget-breach")?
  let factory = fs.cwd()?
  let worker = fp"${root}/worker"
  let fake_docker = fp"${root}/fake-docker"
  fs.mkdir(worker)?
  fs.mkdir(fp"${root}/evals/task-tags/runtime")?
  fs.mkdir(fp"${root}/runtime")?
  fs.mkdir(fp"${root}/templates")?
  fs.mkdir(fp"${root}/tools")?
  fs.write(fp"${root}/evals/task-tags/EVAL.md", "# Eval task-tags\n\n## Status\n\nApproved.\n")?
  fs.write(fp"${root}/evals/task-tags/runtime/artifact.md", "artifact.txt\n")?
  fs.write(fp"${root}/evals/task-tags/runtime/task.md", "fake task\n")?
  fs.write(fp"${root}/runtime/agents.md", "agents\n")?
  fs.write(fp"${root}/runtime/review.md", "review\n")?
  fs.write(fp"${root}/runtime/handbook.md", "handbook\n")?
  for name in ["BUDGET-BREACH.md", "EXECUTOR-REPORT.md"] {
    fs.copy(fp"${factory}/templates/${name}", fp"${root}/templates/${name}", overwrite: true)?
  }
  for name in ["budget-watch.xsh", "session-report.xsh"] {
    fs.copy(fp"${factory}/tools/${name}", fp"${root}/tools/${name}", overwrite: true)?
  }
  fs.copy(fp"${factory}/tests/fixtures/fake-docker-budget-breach.sh", fake_docker, overwrite: true)?
  let chmod = process.run(process.command_argv("chmod", ["chmod", "+x", fake_docker.display()]))?
  test.ok(chmod.ok)?
  let xsh = process.which("xsh")?
  let status = process.run(process.command_argv(
    xsh,
    [xsh.display(), fp"${factory}/eval-executor.xsh".display(), "--", "task-tags"],
    cwd: root,
    env: {
      PATH: f"${root.display()}:${env.get("PATH")?}",
      FACTORY_DIR: root.display(),
      FACTORY_EVAL_WORKER_DIR: worker.display(),
      FACTORY_EVAL_IMAGE: "fake-image",
      FACTORY_EVAL_WORKER_BUDGET_USD: "2",
      FACTORY_PLATFORM: "linux/arm64",
      FACTORY_XSH_MODULE_PATH: factory.display(),
      XSH_MODULE_PATH: factory.display(),
      PI_AUTH_FILE: "/dev/null",
      DOCKER: fake_docker.display(),
    },
  ))?
  test.ok(! status.ok, "a budget-breached executor must fail the trial")?
  let eval_text = fs.read_text(fp"${root}/evals/task-tags/EVAL.md")?
  test.ok(control.eval_is_disabled(eval_text))?
  test.contains(eval_text, "Reason: eval-worker budget exceeded")?
  test.contains(eval_text, "worker/WORKER-REPORT.md")?
  let executor = fs.read_text(fp"${worker}/EXECUTOR-REPORT.md")?
  test.contains(executor, "Primary: `budget_breach`")?
  test.contains(executor, "Budget watcher: `breached`")?
}

proc test_run_agent_closes_assigned_ticket_when_mock_engineer_breaches_budget(ctx: TestContext) [fs, process, env, error] {
  let root = test.temp_dir(ctx, name: "engineer-budget-breach")?
  let factory = fs.cwd()?
  let run_dir = fp"${root}/runs/run-1"
  let workdir = fp"${run_dir}/worktrees/task-tags-002"
  let message = fp"${run_dir}/messages/task-tags-002.md"
  let fake_pi = fp"${root}/bin/fake-pi"
  fs.mkdir(fp"${run_dir}/messages")?
  fs.mkdir(workdir)?
  fs.mkdir(fp"${root}/tickets")?
  fs.mkdir(fp"${root}/runtime")?
  fs.mkdir(fp"${root}/templates")?
  fs.mkdir(fp"${root}/tools")?
  fs.write(fp"${root}/tickets/task-tags-002.md", "# Ticket task-tags-002\n\n## Status\n\nApproved.\n")?
  fs.write(fp"${root}/NORTH-STAR.md", "north star\n")?
  fs.write(fp"${root}/runtime/handbook.md", "handbook\n")?
  for name in ["WORKER.md", "BUDGET-BREACH.md", "ENGINEER-ASSIGNMENT.md"] {
    fs.copy(fp"${factory}/templates/${name}", fp"${root}/templates/${name}", overwrite: true)?
  }
  for name in ["budget-watch.xsh", "session-report.xsh"] {
    fs.copy(fp"${factory}/tools/${name}", fp"${root}/tools/${name}", overwrite: true)?
  }
  fs.mkdir(fp"${root}/bin")?
  fs.copy(fp"${factory}/tests/fixtures/fake-pi-budget-breach.sh", fake_pi, overwrite: true)?
  let chmod = process.run(process.command_argv("chmod", ["chmod", "+x", fake_pi.display()]))?
  test.ok(chmod.ok)?
  let ticket_path = fp"${root}/tickets/task-tags-002.md"
  let assignment_template = fs.read_text(fp"${factory}/templates/ENGINEER-ASSIGNMENT.md")?
  let assignment = control.fill_template(assignment_template, [
    {key: "TICKET_ID", value: "task-tags-002"},
    {key: "TICKET_PATH", value: ticket_path.display()},
    {key: "TICKET_SHA", value: hash.sha256(ticket_path)?.hex()},
    {key: "WORKTREE", value: workdir.display()},
    {key: "BRANCH", value: "factory/task-tags-002/run-1"},
    {key: "XSH_COMMIT", value: "xsh-sha"},
    {key: "ENGINEER_REPORT", value: fp"${run_dir}/workers/engineer/task-tags-002/ENGINEER-REPORT.md".display()},
    {key: "FACTORY_DIR", value: root.display()},
    {key: "FACTORY_RUN_DIR", value: run_dir.display()},
    {key: "NORTH_STAR_FILE", value: fp"${root}/NORTH-STAR.md".display()},
    {key: "HANDBOOK_FILE", value: fp"${root}/runtime/handbook.md".display()},
    {key: "XSH_AGENTS_FILE", value: "xsh/AGENTS.md"},
    {key: "XSH_RATIONALE_FILE", value: "xsh/docs/CHAPTER-01-why-xsh.md"},
    {key: "TICKET_TEXT", value: "## Observation\n\nfixture"},
  ])
  fs.write(message, assignment)?
  let assignment_sha = hash.sha256(message)?.hex()
  let xsh = process.which("xsh")?
  let status = process.run(process.command_argv(
    xsh,
    [xsh.display(), fp"${factory}/run-agent.xsh".display(), "--", "engineer", "task-tags-002",
      fp"${factory}/roles/engineer.md".display(), message.display()],
    cwd: root,
    env: {
      PATH: f"${root}/bin:${env.get("PATH")?}",
      XSH_MODULE_PATH: factory.display(),
      FACTORY_DIR: root.display(),
      FACTORY_RUN_DIR: run_dir.display(),
      FACTORY_RUN_AGENT: fp"${factory}/run-agent.xsh".display(),
      FACTORY_PARENT_ID: "director",
      FACTORY_MODE: "ticket-implementation",
      FACTORY_TICKET_ID: "task-tags-002",
      FACTORY_ASSIGNMENT_SHA: assignment_sha,
      FACTORY_WORKDIR: workdir.display(),
      FACTORY_XSH_REPO: fp"${factory}/../xsh".display(),
      FACTORY_ENGINEER_BUDGET_USD: "2",
      PI_AUTH_FILE: "/dev/null",
      PI_COMMAND: "fake-pi",
    },
  ))?
  test.ok(! status.ok, "an over-budget engineer runner must fail the worker")?
  let ticket = fs.read_text(ticket_path)?
  test.ok(control.ticket_is_closed(ticket))?
  test.contains(ticket, "Reason: too difficult")?
  test.contains(ticket, "runs/run-1/workers/engineer/task-tags-002/WORKER-REPORT.md")?
  test.ok(fs.exists(fp"${run_dir}/workers/engineer/task-tags-002/BUDGET-BREACH")?)?
}

proc test_audit_run_accepts_standalone_eval_design_evidence(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "audit-design")?
  let run_dir = fp"${root}/run-1"
  let worker_dir = fp"${run_dir}/workers/eval-designer/proposal-1"
  let proposal_dir = fp"${run_dir}/proposals/proposal-1"
  fs.mkdir(worker_dir)?
  fs.mkdir(proposal_dir)?
  fs.write(fp"${run_dir}/CYCLE-REQUEST.md", "# Design\n\n## Mode\n\n- `eval-design`\n")?
  let provenance_template = fs.read_text(fp"${fs.cwd()?}/templates/PROVENANCE.md")?
  fs.write(fp"${run_dir}/PROVENANCE.md", control.fill_template(provenance_template, [
    {key: "RUN_ID", value: run_dir.display()},
    {key: "MODE", value: "eval-design"},
    {key: "REQUEST", value: "CYCLE-REQUEST.md"},
    {key: "BUILD_ID", value: "fixture-design"},
    {key: "XSH_COMMIT", value: "fixture-xsh"},
    {key: "CANDIDATE_TICKET", value: "not-reevaluation"},
    {key: "CANDIDATE_WORKTREE", value: "not-reevaluation"},
    {key: "IMAGE", value: "not-used"},
    {key: "IMAGE_ID", value: "not-used"},
    {key: "PLATFORM", value: "fixture-platform"},
    {key: "APPROVED_HANDBOOK_SHA", value: "approved"},
    {key: "CANDIDATE_HANDBOOK_SHA", value: "not-used"},
    {key: "TICKET_SNAPSHOT_SHA", value: "not-used"},
  ]))?
  fs.write(fp"${run_dir}/COST.md", "# Cost\n\n## Workers\n\nfixture\n\n## Role totals\n\nfixture\n\n## Run total\n\nfixture\n\n- Budget failures or unknown costs: 0\n")?
  fs.write(fp"${run_dir}/proposals/proposal-1/EVAL.md", "proposal\n")?
  fs.write(fp"${worker_dir}/DESIGNER-REPORT.md", "# Designer\n\n## Result\n\nready-for-review\n\n## Proposal\n\nproposal\n\n## Dry run\n\nevidence\n\n## North-star impact\n\nimpact\n\n## Known risks\n\nnone\n\n## Review path\n\npath\n")?
  fs.write(fp"${worker_dir}/session.jsonl", r"""
{"timestamp":"2026-08-01T12:00:00.000Z","type":"message","message":{"role":"user","content":"fixture"}}
{"timestamp":"2026-08-01T12:00:01.000Z","type":"message","message":{"role":"assistant","provider":"openrouter","model":"deepseek/deepseek-v4-flash-0731","stopReason":"stop","content":[{"type":"thinking","thinking":"fixture"}],"usage":{"input":1,"output":2,"reasoning":1,"totalTokens":3,"cost":{"total":0.001}}}}
""")?
  let xsh = process.which("xsh")?
  let report_status = process.run(process.command_argv(
    xsh,
    [xsh.display(), fp"${fs.cwd()?}/tools/session-report.xsh", "--", "worker",
      "--session", fp"${worker_dir}/session.jsonl".display(),
      "--output", fp"${worker_dir}/WORKER-REPORT.md".display(),
      "--role", "eval-designer", "--worker-id", "proposal-1", "--budget-usd", "0.30"],
  ))?
  test.ok(report_status.ok, "synthetic design worker report should render")?
  let audit_status = process.run(process.command_argv(
    xsh,
    [xsh.display(), fp"${fs.cwd()?}/audit-run.xsh", "--", run_dir.display(), "eval-design"],
  ))?
  test.ok(audit_status.ok, "standalone design audit should run")?
  let audit = fs.read_text(fp"${run_dir}/AUDIT.md")?
  test.ok(control.audit_report_contract_ok(audit))?
  test.eq(control.audit_result(audit), "pass")?
  test.contains(audit, "Mode: `eval-design`")?
}

proc test_audit_run_accepts_ready_for_review_ticket_evidence(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "audit-ticket")?
  let run_dir = fp"${root}/run-1"
  let director_dir = fp"${run_dir}/workers/director/director"
  let engineer_dir = fp"${run_dir}/workers/engineer/task-tags-002"
  let factory = fs.cwd()?
  fs.mkdir(director_dir)?
  fs.mkdir(engineer_dir)?
  fs.copy(fp"${factory}/tests/fixtures/audit-ticket-request.md", fp"${run_dir}/CYCLE-REQUEST.md", overwrite: true)?
  fs.copy(fp"${factory}/tests/fixtures/audit-ticket-director-report.md", fp"${run_dir}/DIRECTOR-REPORT.md", overwrite: true)?
  fs.copy(fp"${factory}/tests/fixtures/audit-ticket-cost.md", fp"${run_dir}/COST.md", overwrite: true)?
  fs.copy(fp"${factory}/tests/fixtures/audit-ticket-engineer-report.md", fp"${engineer_dir}/ENGINEER-REPORT.md", overwrite: true)?
  for target in [director_dir, engineer_dir] {
    fs.copy(fp"${factory}/tests/fixtures/audit-ticket-session.jsonl", fp"${target}/session.jsonl", overwrite: true)?
  }

  let provenance_template = fs.read_text(fp"${factory}/templates/PROVENANCE.md")?
  fs.write(fp"${run_dir}/PROVENANCE.md", control.fill_template(provenance_template, [
    {key: "RUN_ID", value: run_dir.display()},
    {key: "MODE", value: "ticket-implementation"},
    {key: "REQUEST", value: "CYCLE-REQUEST.md"},
    {key: "BUILD_ID", value: "fixture-ticket"},
    {key: "XSH_COMMIT", value: "fixture-xsh"},
    {key: "CANDIDATE_TICKET", value: "task-tags-002"},
    {key: "CANDIDATE_WORKTREE", value: "fixture-worktree"},
    {key: "IMAGE", value: "not-used"},
    {key: "IMAGE_ID", value: "not-used"},
    {key: "PLATFORM", value: "fixture-platform"},
    {key: "APPROVED_HANDBOOK_SHA", value: "not-requested"},
    {key: "CANDIDATE_HANDBOOK_SHA", value: "not-requested"},
    {key: "TICKET_SNAPSHOT_SHA", value: "fixture-ticket"},
  ]))?

  let xsh = process.which("xsh")?
  for entry in [
    {path: director_dir, role: "director", worker: "director"},
    {path: engineer_dir, role: "engineer", worker: "task-tags-002"},
  ] {
    let report_status = process.run(process.command_argv(
      xsh,
      [xsh.display(), fp"${factory}/tools/session-report.xsh".display(), "--", "worker",
        "--session", fp"${entry.path}/session.jsonl".display(),
        "--output", fp"${entry.path}/WORKER-REPORT.md".display(),
        "--role", entry.role, "--worker-id", entry.worker, "--budget-usd", "0.05"],
    ))?
    test.ok(report_status.ok, "synthetic ticket worker report should render")?
  }

  let audit_status = process.run(process.command_argv(
    xsh, [xsh.display(), fp"${factory}/audit-run.xsh".display(), "--", run_dir.display(), "ticket-implementation"],
  ))?
  test.ok(audit_status.ok, "ticket audit should accept a ready-for-review engineer report")?
  let audit = fs.read_text(fp"${run_dir}/AUDIT.md")?
  test.ok(control.audit_report_contract_ok(audit))?
  test.eq(control.audit_result(audit), "pass")?
  test.ok(audit.contains("Ticket evidence") and ! audit.contains("Ticket evidence: fail"))?
  test.contains(audit, "| ticket | task-tags-002 | ready-for-review | engineer | pass |")?
}

proc test_cleanup_run_uses_a_mock_container_command(ctx: TestContext) [fs, process, error] {
  let run_dir = test.temp_dir(ctx, name: "cleanup-run")?
  let registry = fp"${run_dir}/processes"
  let fake_docker = fp"${run_dir}/fake-docker"
  let docker_log = fp"${run_dir}/docker.log"
  fs.mkdir(registry)?
  fs.mkdir(fp"${run_dir}/phases/01/processes")?
  fs.write(fp"${registry}/worker.pids", "2147483647\nnot-a-pid\n")?
  fs.write(fp"${run_dir}/phases/01/processes/worker.pids", "2147483646\n")?
  fs.write(fp"${run_dir}/worker.cid", "fake-container\n")?
  fs.write(fp"${run_dir}/phases/01/worker.cid", "fake-phase-container\n")?
  fs.write(fp"${run_dir}/phases/01/ACTIVE", run_dir.display() + "\n")?
  fs.write(fp"${run_dir.parent()}/ACTIVE", run_dir.display() + "\n")?
  fs.write(fake_docker, f"#!/bin/sh\nprintf called >> '${docker_log.display()}'\n")?
  let chmod = process.run(process.command_argv("chmod", ["chmod", "+x", fake_docker.display()]))?
  test.ok(chmod.ok)?
  let tool = fp"${fs.cwd()?}/tools/cleanup-run.xsh"
  let xsh = process.which("xsh")?
  let status = process.run(process.command_argv(
    xsh,
    [xsh.display(), tool.display(), "--", run_dir.display()],
    env: {PATH: f"${run_dir.display()}:/usr/bin:/bin", DOCKER: fake_docker.display()},
  ))?
  test.ok(status.ok, "cleanup should tolerate stale and malformed registry entries")?
  test.ok(! (fs.exists(fp"${run_dir.parent()}/ACTIVE")?))?
  test.ok(! (fs.exists(fp"${run_dir}/phases/01/ACTIVE")?))?
  test.eq(fs.read_text(docker_log)?, "calledcalledcalledcalled")?
}

proc test_cleanup_run_can_leave_the_handling_controller_alive(ctx: TestContext) [fs, process, error] {
  let run_dir = test.temp_dir(ctx, name: "cleanup-exclude")?
  let registry = fp"${run_dir}/processes"
  fs.mkdir(registry)?
  let controller = spawn process.command_argv("sh", ["sh", "-c", "sleep 5"])?
  fs.write(fp"${registry}/controller.pids", f"${controller.pid}\n")?
  let tool = fp"${fs.cwd()?}/tools/cleanup-run.xsh"
  let xsh = process.which("xsh")?
  let status = process.run(process.command_argv(
    xsh,
    [xsh.display(), tool.display(), "--", run_dir.display(),
      "--exclude-pid", f"${controller.pid}"],
  ))?
  test.ok(status.ok, "cleanup should support excluding the controller handling SIGINT")?
  test.ok(process.list()? |> any .pid == controller.pid, "excluded controller should remain alive")?
  let kill_status = process.kill(controller.pid, signal: "TERM")
  let controller_status = wait controller?
  test.ok(! controller_status.ok, "test controller should be terminated explicitly")?
}

proc test_clean_factory_removes_runs_and_dist_but_keeps_branches(ctx: TestContext) [fs, process, env, error] {
  let root = test.temp_dir(ctx, name: "clean-factory")?
  let factory = fs.cwd()?
  let product = fp"${root}/xsh"
  let run_dir = fp"${root}/runs/run-1"
  let worktrees = fp"${run_dir}/worktrees"
  let worktree = fp"${worktrees}/task"
  fs.mkdir(product)?
  fs.mkdir(worktrees)?
  let init = process.run(process.command_argv("git", ["git", "-C", product.display(), "init", "-b", "main"]))?
  test.ok(init.ok)?
  for setting in [["user.email", "factory@test.invalid"], ["user.name", "Factory Test"]] {
    let configured = process.run(process.command_argv("git", ["git", "-C", product.display(), "config", setting[0], setting[1]]))?
    test.ok(configured.ok)?
  }
  fs.write(fp"${product}/README", "base\n")?
  test.ok((process.run(process.command_argv("git", ["git", "-C", product.display(), "add", "README"]))?).ok)?
  test.ok((process.run(process.command_argv("git", ["git", "-C", product.display(), "commit", "-m", "base"]))?).ok)?
  let base = run.text "git" "-C" $product.display() "rev-parse" "HEAD" ?
  let branch = "factory/clean-test"
  let add_worktree = process.run(process.command_argv(
    "git", ["git", "-C", product.display(), "worktree", "add", "-b", branch, worktree.display(), base.trim()],
  ))?
  test.ok(add_worktree.ok)?
  fs.write(fp"${worktree}/README", "temporary\n")?
  test.ok((process.run(process.command_argv("git", ["git", "-C", worktree.display(), "add", "README"]))?).ok)?
  test.ok((process.run(process.command_argv("git", ["git", "-C", worktree.display(), "commit", "-m", "temporary"]))?).ok)?
  fs.mkdir(fp"${root}/evals")?
  fs.mkdir(fp"${root}/evals/task-tags")?
  fs.mkdir(fp"${root}/evals/.dist")?
  fs.mkdir(fp"${root}/evals/task-tags/.dist")?
  fs.mkdir(fp"${root}/runs/.cache")?
  fs.write(fp"${root}/runs/.cache/xsh-test-aarch64-unknown-linux-musl.stamp", "fixture\n")?
  fs.write(fp"${root}/runs/organization.lock", "")?
  fs.write(fp"${root}/evals/.dist/xsh", "staged")?
  fs.write(fp"${root}/evals/task-tags/.dist/xsht", "staged")?
  let tool = fp"${factory}/tools/clean-factory.xsh"
  let xsh = process.which("xsh")?
  let status = process.run(process.command_argv(
    xsh,
    [xsh.display(), tool.display()],
    cwd: root,
    env: {
      PATH: env.get("PATH")?,
      FACTORY_DIR: root.display(),
      FACTORY_XSH_REPO: product.display(),
      XSH_MODULE_PATH: factory.display(),
    },
  ))?
  test.ok(status.ok, "clean factory command should complete")?
  test.ok(! fs.exists(run_dir)?, "clean should remove generated run state")?
  test.ok(! fs.exists(fp"${root}/evals/.dist")?, "clean should remove shared build staging")?
  test.ok(! fs.exists(fp"${root}/evals/task-tags/.dist")?, "clean should remove eval build staging")?
  test.ok(! fs.exists(fp"${root}/runs/.cache")?, "clean should remove the toolchain cache")?
  test.ok(! fs.exists(fp"${root}/runs/organization.lock")?, "clean should remove the advisory organization lock")?
  test.ok(! fs.exists(worktree)?, "clean should remove product worktree contents")?
  let branches = run.text "git" "-C" $product.display() "branch" "--list" $branch ?
  test.contains(branches, branch, "clean should retain the review branch")?
}

proc test_clean_factory_refuses_active_state(ctx: TestContext) [fs, process, env, error] {
  let root = test.temp_dir(ctx, name: "clean-factory-active")?
  let factory = fs.cwd()?
  let product = fp"${root}/xsh"
  fs.mkdir(product)?
  let init = process.run(process.command_argv("git", ["git", "-C", product.display(), "init", "-b", "main"]))?
  test.ok(init.ok)?
  fs.mkdir(fp"${root}/runs")?
  fs.mkdir(fp"${root}/runs/run-1")?
  fs.write(fp"${root}/runs/ACTIVE", f"${root}/runs/run-1\n")?
  let tool = fp"${factory}/tools/clean-factory.xsh"
  let xsh = process.which("xsh")?
  let status = process.run(process.command_argv(
    xsh,
    [xsh.display(), tool.display()],
    cwd: root,
    env: {
      PATH: env.get("PATH")?,
      FACTORY_DIR: root.display(),
      FACTORY_XSH_REPO: product.display(),
      XSH_MODULE_PATH: factory.display(),
    },
  ))?
  test.ok(! status.ok, "clean must refuse an active factory run")?
  test.ok(fs.exists(fp"${root}/runs/run-1")?, "active clean refusal must preserve state")?
}
