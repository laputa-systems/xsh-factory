##! Native tests for structured reports, shutdown, and patch boundaries.
use factory.control as control
use factory.paths as paths
use factory.runtime as runtime
use factory.schema as schema
use factory.tools.budget as budget
use factory.tools.cleanup as cleanup

proc command_ok(command: Path, args: List[Str]) [process, error] -> Result[Bool] {
  return process.run(process.command_argv(command, args))?.ok
}

proc run_session_report(session: Path, output: Path) [fs, process, error] -> Result[Bool] {
  let xsh = process.which("xsh")?
  let status = process.run(
    process.command_argv(
      xsh,
      [
        xsh.display(),
        fp"${fs.cwd()?}/factory/tools/session.xsh",
        "--",
        "worker",
        "--session",
        session.display(),
        "--output",
        output.display(),
        "--role",
        "eval-worker",
        "--worker-id",
        "fixture",
        "--budget-usd",
        "0.50",
      ],
      env: {FACTORY_DIR: fs.cwd()?.display(), XSH_MODULE_PATH: fs.cwd()?.display()},
    ),
  )?
  return status.ok
}

proc run_factory_entrypoint(file: Str, args: List[Str]) [fs, process, error] -> Result[Bool] {
  let factory = fs.cwd()?
  let xsh = process.which("xsh")?
  let status = process.run(
    process.command_argv(
      xsh,
      [xsh.display(), fp"${factory}/${file}", "--"].extend(args),
      cwd: factory,
      env: {FACTORY_DIR: factory.display(), XSH_MODULE_PATH: factory.display()},
    ),
  )?
  status.ok
}

proc test_controller_and_tool_entrypoints_fail_closed(ctx: TestContext) [fs, process, error] {
  for source in [
    "run.xsh",
    "factory/controllers/organization.xsh",
    "factory/controllers/ticket.xsh",
    "factory/controllers/eval.xsh",
    "factory/controllers/design.xsh",
    "factory/controllers/reuse.xsh",
    "factory/entrypoints/run-agent.xsh",
    "factory/entrypoints/eval-executor.xsh",
  ] {
    let source_text = fs.read_text(fp"${fs.cwd()?}/${source}")?
    test.contains(source_text, "FACTORY_SOURCE_SHA")?
    test.contains(source_text, "verify_factory_source")?
  }
  test.ok(! run_factory_entrypoint("run.xsh", [])?)?
  test.ok(! run_factory_entrypoint("run.xsh", ["missing-request.md"])?)?
  test.ok(! run_factory_entrypoint("factory/controllers/eval.xsh", [])?)?
  test.ok(! run_factory_entrypoint("factory/controllers/eval.xsh", ["missing-request.md"])?)?
  test.ok(! run_factory_entrypoint("factory/controllers/organization.xsh", [])?)?
  test.ok(! run_factory_entrypoint("factory/controllers/organization.xsh", ["missing-request.md"])?)?
  test.ok(! run_factory_entrypoint("factory/controllers/ticket.xsh", [])?)?
  test.ok(! run_factory_entrypoint("factory/controllers/ticket.xsh", ["missing-request.md"])?)?
  test.ok(! run_factory_entrypoint("factory/controllers/design.xsh", [])?)?
  test.ok(! run_factory_entrypoint("factory/controllers/design.xsh", ["missing-request.md"])?)?
  test.ok(! run_factory_entrypoint("factory/controllers/reuse.xsh", ["unexpected"])?)?
  test.ok(
    ! run_factory_entrypoint("factory/entrypoints/run-agent.xsh", ["unknown-role", "worker", "prompt", "message"])?,
  )?
  test.ok(! run_factory_entrypoint("factory/entrypoints/eval-executor.xsh", [])?)?
  test.ok(! run_factory_entrypoint("factory/tools/budget-watch.xsh", [])?)?
  test.ok(! run_factory_entrypoint("factory/tools/session-watch.xsh", [])?)?
  test.ok(! run_factory_entrypoint("factory/tools/cto.xsh", ["unexpected"])?)?

  let root = test.temp_dir(ctx, name: "entrypoint-tool-probes")?
  let factory = fp"${root}/factory"
  let product = fp"${root}/product"
  fs.mkdir(factory)?
  fs.mkdir(product)?
  fs.mkdir(fp"${root}/run")?
  fs.mkdir(fp"${root}/eval-worker")?
  let xsh = process.which("xsh")?
  let eval_request = fp"${root}/eval-request.md"
  fs.write(
    eval_request,
    """# Coverage eval request

## Mode

- `eval`

## Active evals

- `task-bigfiles`

## Trial plan

- Count: `0`

## New eval proposals

- Count: `0`
""",
  )?
  let eval_request_status = process.run(
    process.command_argv(
      xsh,
      [
        xsh.display(),
        fp"${fs.cwd()?}/factory/controllers/eval.xsh",
        "--",
        eval_request.display(),
      ],
      cwd: factory,
      env: {FACTORY_DIR: fs.cwd()?.display(), XSH_MODULE_PATH: fs.cwd()?.display()},
    ),
  )?
  test.ok(! eval_request_status.ok)?

  let organization_request = fp"${root}/organization-request.md"
  fs.write(
    organization_request,
    """# Coverage organization request

## Mode

- `organization`

## Trial plan

- Count: `0`

## New eval proposals

- Count: `0`

## Approved tickets

- None.
""",
  )?
  let organization_request_status = process.run(
    process.command_argv(
      xsh,
      [
        xsh.display(),
        fp"${fs.cwd()?}/factory/controllers/organization.xsh",
        "--",
        organization_request.display(),
      ],
      cwd: factory,
      env: {FACTORY_DIR: fs.cwd()?.display(), XSH_MODULE_PATH: fs.cwd()?.display()},
    ),
  )?
  test.ok(! organization_request_status.ok)?

  let design_request = fp"${root}/design-request.md"
  fs.write(
    design_request,
    """# Coverage design request

## Mode

- `organization`
""",
  )?
  let design_request_status = process.run(
    process.command_argv(
      xsh,
      [
        xsh.display(),
        fp"${fs.cwd()?}/factory/controllers/design.xsh",
        "--",
        design_request.display(),
      ],
      cwd: factory,
      env: {FACTORY_DIR: fs.cwd()?.display(), XSH_MODULE_PATH: fs.cwd()?.display()},
    ),
  )?
  test.ok(! design_request_status.ok)?

  let ticket_request = fp"${root}/ticket-request.md"
  fs.write(
    ticket_request,
    """# Coverage ticket request

## Mode

- `ticket-implementation`

## Approved tickets

- None.
""",
  )?
  let ticket_request_status = process.run(
    process.command_argv(
      xsh,
      [
        xsh.display(),
        fp"${fs.cwd()?}/factory/controllers/ticket.xsh",
        "--",
        ticket_request.display(),
      ],
      cwd: factory,
      env: {
        FACTORY_DIR: fs.cwd()?.display(),
        PI_AUTH_FILE: fp"${root}/missing-auth.json".display(),
        XSH_MODULE_PATH: fs.cwd()?.display(),
      },
    ),
  )?
  test.ok(! ticket_request_status.ok)?

  test.ok(
    run_factory_entrypoint(
      "factory/tools/budget-watch.xsh",
      [
        "--session",
        fp"${root}/missing-session".display(),
        "--pid",
        "999999999",
        "--budget-usd",
        "1.00",
        "--marker",
        fp"${root}/budget-marker".display(),
      ],
    )?,
  )?
  test.ok(
    run_factory_entrypoint(
      "factory/tools/session-watch.xsh",
      [
        "--session",
        fp"${root}/missing-session".display(),
        "--pid",
        "999999999",
        "--max-turns",
        "10",
        "--max-seconds",
        "10",
        "--marker",
        fp"${root}/session-marker".display(),
        "--role",
        "eval-worker",
      ],
    )?,
  )?

  let run_agent_status = process.run(
    process.command_argv(
      xsh,
      [
        xsh.display(),
        fp"${fs.cwd()?}/factory/entrypoints/run-agent.xsh",
        "--",
        "eval-manager",
        "worker-1",
        fp"${fs.cwd()?}/templates/WORKER.md".display(),
        fp"${fs.cwd()?}/templates/EVAL-MANAGER-REPORT.md".display(),
      ],
      cwd: factory,
      env: {
        FACTORY_DIR: fs.cwd()?.display(),
        FACTORY_RUN_DIR: fp"${root}/run".display(),
        PI_COMMAND: "xsh",
        XSH_MODULE_PATH: fs.cwd()?.display(),
      },
    ),
  )?
  test.ok(! run_agent_status.ok)?

  let eval_executor_status = process.run(
    process.command_argv(
      xsh,
      [
        xsh.display(),
        fp"${fs.cwd()?}/factory/entrypoints/eval-executor.xsh",
        "--",
        "task-no-evaluator",
      ],
      cwd: factory,
      env: {
        FACTORY_DIR: fs.cwd()?.display(),
        FACTORY_EVAL_ID: "task-no-evaluator",
        FACTORY_EVAL_WORKER_DIR: fp"${root}/eval-worker".display(),
        PI_AUTH_FILE: fp"${root}/missing-auth.json".display(),
        XSH_MODULE_PATH: fs.cwd()?.display(),
      },
    ),
  )?
  test.ok(! eval_executor_status.ok)?

  let clean_status = process.run(
    process.command_argv(
      xsh,
      [
        xsh.display(),
        fp"${fs.cwd()?}/factory/tools/clean-factory.xsh",
        "--",
      ],
      cwd: factory,
      env: {
        FACTORY_DIR: factory.display(),
        FACTORY_XSH_REPO: fp"${root}/missing-product".display(),
        XSH_MODULE_PATH: fs.cwd()?.display(),
      },
    ),
  )?
  test.ok(! clean_status.ok)?

  let clean_success_status = process.run(
    process.command_argv(
      xsh,
      [
        xsh.display(),
        fp"${fs.cwd()?}/factory/tools/clean-factory.xsh",
        "--",
      ],
      cwd: factory,
      env: {
        FACTORY_DIR: factory.display(),
        FACTORY_XSH_REPO: fp"${fs.cwd()?}/../xsh".resolve()?.display(),
        XSH_MODULE_PATH: fs.cwd()?.display(),
      },
    ),
  )?
  test.ok(clean_success_status.ok)?

  let reconcile_status = process.run(
    process.command_argv(
      xsh,
      [
        xsh.display(),
        fp"${fs.cwd()?}/factory/tools/reconcile.xsh",
        "--",
      ],
      cwd: factory,
      env: {
        FACTORY_DIR: factory.display(),
        FACTORY_XSH_REPO: product.display(),
        XSH_MODULE_PATH: fs.cwd()?.display(),
      },
    ),
  )?
  test.ok(! reconcile_status.ok)?

  let reuse_status = process.run(
    process.command_argv(
      xsh,
      [
        xsh.display(),
        fp"${fs.cwd()?}/factory/controllers/reuse.xsh",
        "--",
      ],
      cwd: factory,
      env: {
        FACTORY_DIR: fs.cwd()?.display(),
        FACTORY_PHASE_DIR: fp"${root}/reuse-phase".display(),
        FACTORY_TICKET_ID: "coverage-probe",
        FACTORY_TICKET_BRANCH: "HEAD",
        FACTORY_XSH_COMMIT: "HEAD~1",
        FACTORY_XSH_REPO: fp"${fs.cwd()?}/../xsh".resolve()?.display(),
        XSH_MODULE_PATH: fs.cwd()?.display(),
      },
    ),
  )?
  test.ok(reuse_status.ok)?

  test.ok(budget.can_start(0.1, 1.0, 0.2))?
  test.ok(budget.stops_new_work(null, false))?
  test.ok(cleanup.can_remove(fp"${root}/run", fp"${root}/run/ACTIVE", "ACTIVE")?)?
}

proc test_ticket_controller_happy_path_with_fake_pi(ctx: TestContext) [fs, process, env, error] {
  let root = test.temp_dir(ctx, name: "ticket-controller-happy-path")?
  let source_factory = fs.cwd()?
  let fixture_root = fp"${root}/fixture"
  let product = fp"${root}/product"
  let run_dir = fp"${source_factory}/runs/run-ticket-coverage-${root.name()}"
  let bin_dir = fp"${root}/bin"
  let fake_pi = fp"${bin_dir}/factory-coverage-pi"
  let ticket_id = "coverage-ticket"
  fs.mkdir(fixture_root)?
  fs.mkdir(run_dir.parent())?
  test.ok(! fs.exists(run_dir)?)?
  defer fs.remove(run_dir, missing_ok: true)?
  fs.mkdir(product)?
  fs.mkdir(bin_dir)?
  let canonical_product = product.resolve()?
  let canonical_run_dir = fp"${source_factory.resolve()?.display()}/runs/run-ticket-coverage-${root.name()}"
  let ticket_path = fp"${source_factory}/tickets/${ticket_id}.md"
  test.ok(! fs.exists(ticket_path)?)?
  defer fs.remove(ticket_path, missing_ok: true)?
  fs.write(
    ticket_path,
    """# Ticket coverage-ticket

## Status

Approved.

## Change target

- `product`

## Observation

Deterministic controller coverage fixture.

## Proposed XSH change

The fixture makes one product change.

## Acceptance criteria

The controller validates the worker evidence and portable patch.

## North-star impact

The controller path remains bounded and evidence-driven.
""",
  )?
  fs.write(
    fp"${fixture_root}/ticket-request.md",
    """# Coverage ticket cycle

## Mode

- `ticket-implementation`

## Approved tickets

- `coverage-ticket`
""",
  )?
  fs.write(
    fp"${product}/README.md",
    """fixture product
""",
  )?
  let git = process.which("git")?
  test.ok(command_ok(git, ["git", "init", "-q", product.display()])?)?
  test.ok(command_ok(git, ["git", "-C", product.display(), "config", "user.email", "coverage@example.test"])?)?
  test.ok(command_ok(git, ["git", "-C", product.display(), "config", "user.name", "Coverage Fixture"])?)?
  test.ok(command_ok(git, ["git", "-C", product.display(), "add", "README.md"])?)?
  test.ok(command_ok(git, ["git", "-C", product.display(), "commit", "-qm", "fixture baseline"])?)?
  fs.write(
    fp"${root}/auth.json",
    """{}
""",
  )?
  fs.write(fp"${root}/active", "")?
  fs.write(fp"${root}/factory.lock", "")?
  fs.write(
    fake_pi,
    r"""#!/bin/sh
session=""
previous=""
for argument in "$@"; do
  if [ "$previous" = "--session" ]; then
    session="$argument"
  fi
  previous="$argument"
done
worker_dir="$FACTORY_RUN_DIR/workers/$FACTORY_ROLE/$FACTORY_WORKER_ID"
mkdir -p "$worker_dir"
if [ "$FACTORY_ROLE" = "engineer" ]; then
  printf 'candidate handbook\n' > "$FACTORY_HANDBOOK_CANDIDATE_FILE"
  printf 'fixture change\n' > "$FACTORY_WORKDIR/coverage-fixture.txt"
  git -C "$FACTORY_WORKDIR" add coverage-fixture.txt
  git -C "$FACTORY_WORKDIR" commit -qm 'fixture engineer change'
  branch=$(git -C "$FACTORY_WORKDIR" branch --show-current)
  commit=$(git -C "$FACTORY_WORKDIR" rev-parse HEAD)
  cat > "$worker_dir/REPORT.md" <<EOF
# Engineer report

## Result

ready-for-review

## Branch

$branch

## Commit

$commit

## Files changed

coverage-fixture.txt

## Tests

fixture commit

## North-star impact

Deterministic controller integration coverage.

## Remaining risks

None.
EOF
else
  cat > "$worker_dir/REPORT.md" <<EOF
# Director report

## Result

pass

## Cycle

ticket-implementation coverage fixture

## Children

engineer/$FACTORY_TICKET_ID: pass

## Required-output status

All required outputs are present and valid.

## North-star impact

The bounded controller evidence is reconciled.
EOF
fi
cat > "$session" <<EOF
{"type":"message","timestamp":"2026-08-06T00:00:00.000Z","message":{"role":"assistant","provider":"fixture","model":"fixture","stopReason":"stop","content":[{"type":"toolCall","name":"read","arguments":{"path":"$FACTORY_NORTH_STAR_FILE"}}],"usage":{"input":1,"output":1,"cost":{"total":0.01}}}}
{"type":"message","timestamp":"2026-08-06T00:00:01.000Z","message":{"role":"assistant","provider":"fixture","model":"fixture","stopReason":"stop","content":[{"type":"toolCall","name":"read","arguments":{"path":"$FACTORY_HANDBOOK_FILE"}}],"usage":{"input":1,"output":1,"cost":{"total":0.01}}}}
EOF
exit 0
""",
  )?
  test.ok(command_ok(process.which("chmod")?, ["chmod", "+x", fake_pi.display()])?)?
  let xsh = process.which("xsh")?
  let inherited_path = env.get("PATH")?
  let env_path = f"${bin_dir.display()}:${inherited_path}"
  let status = process.run(
    process.command_argv(
      xsh,
      [
        xsh.display(),
        fp"${source_factory}/factory/controllers/ticket.xsh",
        "--",
        fp"${fixture_root}/ticket-request.md".display(),
      ],
      cwd: source_factory,
      env: {
        FACTORY_DIR: source_factory.display(),
        FACTORY_ACTIVE_RUN: fp"${root}/active".resolve()?.display(),
        FACTORY_LOCK_PATH: fp"${root}/factory.lock".resolve()?.display(),
        FACTORY_PHASE_DIR: canonical_run_dir.display(),
        FACTORY_SKIP_CYCLE_BUDGET: "true",
        FACTORY_XSH_REPO: canonical_product.display(),
        HOME: root.display(),
        PATH: env_path,
        PI_AUTH_FILE: fp"${root}/auth.json".display(),
        PI_COMMAND: "factory-coverage-pi",
        XSH_MODULE_PATH: source_factory.display(),
      },
      stdout: fp"${root}/controller.stdout",
      stderr: fp"${root}/controller.stderr",
    ),
  )?
  test.ok(status.ok, fs.read_text(fp"${root}/controller.stderr")?)?
  test.ok(fs.exists(fp"${run_dir}/report.json")?)?
  test.ok(fs.exists(fp"${run_dir}/CTO-REPORT.md")?)?
  test.ok(fs.exists(fp"${run_dir}/events.jsonl")?)?
  test.eq(fs.read_text(fp"${run_dir}/lineage/handbook-candidate.md")?, "candidate handbook\n")?
  test.ok(fs.exists(fp"${run_dir}/patches/${ticket_id}.diff")?)?
  test.ok(! fs.exists(runtime.ticket_worktree_path(product, run_dir, ticket_id))?)?
  let branches = run.text "git" "-C" $product "branch" "--format=%(refname:short)" ?
  test.ok(f"factory/${ticket_id}/" in branches)?
  let phase_report = json.read(fp"${run_dir}/report.json")?
  test.eq(schema.value_text(json.get(phase_report, ["result"], "")), "pass")?
}

proc test_eval_controller_persists_build_preflight_failure(ctx: TestContext) [fs, process, env, error] {
  let root = test.temp_dir(ctx, name: "eval-controller-preflight")?
  let factory = fs.cwd()?
  let xsh_repo = fp"${factory}/../xsh".resolve()?
  let run_dir = fp"${factory}/runs/run-eval-preflight-${root.name()}"
  let bin_dir = fp"${root}/bin"
  let fake_make = fp"${bin_dir}/make"
  fs.mkdir(bin_dir)?
  test.ok(! fs.exists(run_dir)?)?
  defer fs.remove(run_dir, missing_ok: true)?
  fs.write(
    fp"${root}/eval-request.md",
    """# Coverage eval request

## Mode

- `eval`

## Active evals

- `task-bigfiles`

## Trial plan

- Count: `1`

## New eval proposals

- Count: `0`
""",
  )?
  fs.write(
    fp"${root}/auth.json",
    """{}
""",
  )?
  fs.write(fp"${root}/active", "")?
  fs.write(fp"${root}/factory.lock", "")?
  fs.write(
    fake_make,
    r"""#!/bin/sh
exit 17
""",
  )?
  test.ok(command_ok(process.which("chmod")?, ["chmod", "+x", fake_make.display()])?)?
  let inherited_path = env.get("PATH")?
  let env_path = f"${bin_dir.display()}:${inherited_path}"
  let xsh = process.which("xsh")?
  let status = process.run(
    process.command_argv(
      xsh,
      [
        xsh.display(),
        fp"${factory}/factory/controllers/eval.xsh",
        "--",
        fp"${root}/eval-request.md".display(),
      ],
      cwd: factory,
      env: {
        FACTORY_DIR: factory.display(),
        FACTORY_ACTIVE_RUN: fp"${root}/active".resolve()?.display(),
        FACTORY_FORCE_XSH_TOOLCHAIN_REBUILD: "true",
        FACTORY_LOCK_PATH: fp"${root}/factory.lock".resolve()?.display(),
        FACTORY_PHASE_DIR: run_dir.display(),
        FACTORY_SKIP_TICKET_RECONCILE: "true",
        FACTORY_XSH_REPO: xsh_repo.display(),
        HOME: root.display(),
        PATH: env_path,
        PI_AUTH_FILE: fp"${root}/auth.json".display(),
        XSH_MODULE_PATH: factory.display(),
      },
      stdout: fp"${root}/controller.stdout",
      stderr: fp"${root}/controller.stderr",
    ),
  )?
  test.ok(! status.ok, fs.read_text(fp"${root}/controller.stderr")?)?
  test.ok(fs.exists(fp"${run_dir}/report.json")?)?
  let report = json.read(fp"${run_dir}/report.json")?
  test.ok(schema.valid(report, "phase"))?
  test.eq(schema.value_text(json.get(report, ["result"], "")), "fail")?
  let report_text = fs.read_text(fp"${run_dir}/report.json")?
  test.contains(report_text, "\"stage\": \"xsh\"")?
}

proc test_factory_source_fingerprint_detects_immutable_mutation(ctx: TestContext) [fs, error] {
  let root = test.temp_dir(ctx, name: "factory-source-fingerprint")?
  for directory in ["factory/controllers", "roles", "templates", "evals/task-test", "runtime", "tickets", "runs"] {
    fs.mkdir(fp"${root}/${directory}")?
  }
  for file in [
    "run.xsh",
    "NORTH-STAR.md",
    "FACTORY.md",
    "README.md",
    "CTO.md",
    "THROUGHPUT.md",
    "runtime/handbook.md",
    "runtime/handbook-ledger.md",
    "factory/controllers/eval.xsh",
  ] {
    fs.write(fp"${root}/${file}", "stable\n")?
  }

  let before = runtime.factory_source_fingerprint(root)?
  test.ok(before != "")?
  fs.write(fp"${root}/factory/controllers/eval.xsh", "changed\n")?
  let after_source_change = runtime.factory_source_fingerprint(root)?
  test.ok(after_source_change != before)?
  fs.write(fp"${root}/tickets/task-test.md", "lifecycle-only\n")?
  let after_ticket_change = runtime.factory_source_fingerprint(root)?
  test.eq(after_ticket_change, after_source_change)?
}

proc test_factory_handbook_edit_is_quarantined_and_restored(ctx: TestContext) [fs, error] {
  let root = test.temp_dir(ctx, name: "factory-handbook-quarantine")?
  for directory in ["factory/controllers", "roles", "templates", "evals/task-test", "runtime", "tickets", "runs"] {
    fs.mkdir(fp"${root}/${directory}")?
  }
  for file in [
    "run.xsh",
    "NORTH-STAR.md",
    "FACTORY.md",
    "README.md",
    "CTO.md",
    "THROUGHPUT.md",
    "runtime/handbook.md",
    "runtime/handbook-ledger.md",
    "factory/controllers/eval.xsh",
  ] {
    fs.write(fp"${root}/${file}", if file == "runtime/handbook.md" { "approved\n" } else { "stable\n" })?
  }
  let run_dir = fp"${root}/runs/run-1"
  let before = runtime.factory_source_fingerprint(root)?
  runtime.stage_factory_source_snapshot(root, run_dir)?
  fs.write(fp"${root}/runtime/handbook.md", "candidate\n")?
  let state = runtime.quarantine_factory_handbook(root, run_dir, before)?
  test.eq(state, "handbook-quarantined")?
  test.eq(fs.read_text(fp"${root}/runtime/handbook.md")?, "approved\n")?
  test.eq(fs.read_text(fp"${run_dir}/factory-source/handbook-candidate.md")?, "candidate\n")?
  test.ok(runtime.verify_factory_source(root, before)?)?
  test.eq(runtime.unresolved_handbook_candidates(root)?, 1)?
}

proc test_eval_controller_completes_with_fake_build_docker_and_pi(ctx: TestContext) [fs, process, env, error] {
  let root = test.temp_dir(ctx, name: "eval-controller-success")?
  let factory = fs.cwd()?
  let xsh_repo = fp"${factory}/../xsh".resolve()?
  let run_dir = fp"${factory}/runs/run-eval-success-${root.name()}"
  let bin_dir = fp"${root}/bin"
  let fake_make = fp"${bin_dir}/make"
  let fake_docker = fp"${bin_dir}/docker"
  let fake_pi = fp"${bin_dir}/factory-eval-pi"
  let fixture_target = "fixture-target"
  let toolchain_stamp = fp"${factory}/runs/.cache/xsh-test-${fixture_target}.stamp"
  let fixture_dist = fp"${xsh_repo}/target/${fixture_target}"
  let staged_eval_context = fp"${factory}/evals/.dist"
  fs.mkdir(bin_dir)?
  test.ok(! fs.exists(run_dir)?)?
  defer fs.remove(run_dir, missing_ok: true)?
  # This fixture deliberately replaces the product build with shell doubles.
  # Remove both shared transient outputs so a later real eval cannot accept the
  # fixture's cache stamp and stage the no-op doubles into its Docker image.
  defer fs.remove(toolchain_stamp, missing_ok: true)?
  defer fs.remove(fixture_dist, missing_ok: true)?
  defer fs.remove(staged_eval_context, missing_ok: true)?
  fs.write(
    fp"${root}/eval-request.md",
    """# Coverage eval request

## Mode

- `eval`

## Active evals

- `task-bigfiles`

## Trial plan

- Count: `1`

## New eval proposals

- Count: `0`
""",
  )?
  fs.write(
    fp"${root}/auth.json",
    """{}
""",
  )?
  fs.write(fp"${root}/active", "")?
  fs.write(fp"${root}/factory.lock", "")?
  fs.write(
    fake_make,
    r"""#!/bin/sh
repo=""
target=""
previous=""
for argument in "$@"; do
  if [ "$previous" = "-C" ]; then
    repo="$argument"
  fi
  case "$argument" in
    TARGET=*) target="${argument#TARGET=}" ;;
  esac
  previous="$argument"
done
dist="$repo/target/${target}/dist"
mkdir -p "$dist"
printf '#!/bin/sh\nexit 0\n' > "$dist/xsh"
printf '#!/bin/sh\nexit 0\n' > "$dist/xsht"
dd if=/dev/zero bs=1024 count=1 2>/dev/null >> "$dist/xsh"
dd if=/dev/zero bs=1024 count=1 2>/dev/null >> "$dist/xsht"
chmod +x "$dist/xsh" "$dist/xsht"
exit 0
""",
  )?
  fs.write(
    fake_docker,
    r"""#!/bin/sh
if [ "$1" = "image" ]; then
  for argument in "$@"; do
    if [ "$argument" = "--format" ]; then
      printf 'sha256:coverage-image\n'
      exit 0
    fi
  done
  exit 1
fi
if [ "$1" = "run" ]; then
  work_dir=""
  session_dir=""
  export_dir=""
  is_agent=false
  previous=""
  for argument in "$@"; do
    if [ "$argument" = "/usr/local/lib/xsh-factory/eval-worker.xsh" ]; then
      is_agent=true
    fi
    if [ "$previous" = "--mount" ]; then
      source="${argument#*src=}"
      source="${source%%,dst=*}"
      destination="${argument##*,dst=}"
      case "$destination" in
        /work) work_dir="$source" ;;
        /session) session_dir="$source" ;;
        /export) export_dir="$source" ;;
      esac
    fi
    previous="$argument"
  done
  if [ "$is_agent" = "true" ]; then
    mkdir -p "$work_dir" "$session_dir"
    printf '#!/bin/sh\nexit 0\n' > "$work_dir/bigfiles.xsh"
    cat > "$work_dir/review.md" <<'EOF'
## XSH language proposals

None.

## xsht friction

None.
EOF
    cat > "$session_dir/session.jsonl" <<EOF
{"type":"message","timestamp":"2026-08-06T00:00:00.000Z","message":{"role":"assistant","provider":"fixture","model":"fixture","stopReason":"stop","content":[{"type":"toolCall","name":"read","arguments":{"path":"/work/handbook.md"}}],"usage":{"input":1,"output":1,"cost":{"total":0.01}}}}
EOF
  else
    mkdir -p "$session_dir"
    cat > "$session_dir/run.json" <<'EOF'
{"eval_id":"task-bigfiles","trial_id":"1","result":"pass","classification":"pass","protocol":{"artifact_present":true,"review_ok":true},"correctness":{"all_exact":true,"passed":true},"restrictions":{"passed":true},"timings":{"passed":true}}
EOF
  fi
  exit 0
fi
exit 0
""",
  )?
  fs.write(
    fake_pi,
    r"""#!/bin/sh
session=""
previous=""
for argument in "$@"; do
  if [ "$previous" = "--session" ]; then
    session="$argument"
  fi
  previous="$argument"
done
worker_dir="$FACTORY_RUN_DIR/workers/$FACTORY_ROLE/$FACTORY_WORKER_ID"
mkdir -p "$worker_dir"
cp "$FACTORY_HANDBOOK_FILE" "$FACTORY_RUN_DIR/lineage/handbook-candidate.md"
cat > "$worker_dir/REPORT.md" <<EOF
# Eval manager report

## Result

pass

## Effort metrics

One deterministic fixture session.

## Usage and cost

One assistant turn and zero tool errors.

## Thinking evidence

No provider reasoning tokens reported.

## Tool-error findings

None.

## Timing evidence

Evaluator timing passed.

## Observation classification

Infrastructure integration signal.

## Handbook decision

unchanged

## Tickets created

None.

## Post-merge decisions

None.

## Next replay

None.

## North-star impact

The deterministic eval path preserves trustworthy evidence.
EOF
cat > "$session" <<EOF
{"type":"message","timestamp":"2026-08-06T00:00:00.000Z","message":{"role":"assistant","provider":"fixture","model":"fixture","stopReason":"stop","content":[{"type":"toolCall","name":"read","arguments":{"path":"$FACTORY_NORTH_STAR_FILE"}}],"usage":{"input":1,"output":1,"cost":{"total":0.01}}}}
{"type":"message","timestamp":"2026-08-06T00:00:01.000Z","message":{"role":"assistant","provider":"fixture","model":"fixture","stopReason":"stop","content":[{"type":"toolCall","name":"read","arguments":{"path":"$FACTORY_HANDBOOK_FILE"}}],"usage":{"input":1,"output":1,"cost":{"total":0.01}}}}
{"type":"message","timestamp":"2026-08-06T00:00:02.000Z","message":{"role":"assistant","provider":"fixture","model":"fixture","stopReason":"stop","content":[{"type":"toolCall","name":"read","arguments":{"path":"$FACTORY_RUN_DIR/report.json"}}],"usage":{"input":1,"output":1,"cost":{"total":0.01}}}}
EOF
exit 0
""",
  )?
  test.ok(
    command_ok(process.which("chmod")?, ["chmod", "+x", fake_make.display(), fake_docker.display(), fake_pi.display()])?,
  )?
  let xsh = process.which("xsh")?
  let inherited_path = env.get("PATH")?
  let env_path = f"${bin_dir.display()}:${inherited_path}"
  let status = process.run(
    process.command_argv(
      xsh,
      [
        xsh.display(),
        fp"${factory}/factory/controllers/eval.xsh",
        "--",
        fp"${root}/eval-request.md".display(),
      ],
      cwd: factory,
      env: {
        DOCKER: fake_docker.display(),
        FACTORY_ACTIVE_RUN: fp"${root}/active".resolve()?.display(),
        FACTORY_DIR: factory.display(),
        FACTORY_FORCE_XSH_TOOLCHAIN_REBUILD: "true",
        FACTORY_LOCK_PATH: fp"${root}/factory.lock".resolve()?.display(),
        FACTORY_PHASE_DIR: run_dir.display(),
        FACTORY_SKIP_CYCLE_BUDGET: "true",
        FACTORY_SKIP_TICKET_RECONCILE: "true",
        FACTORY_XSH_REPO: xsh_repo.display(),
        HOME: root.display(),
        PATH: env_path,
        PI_AUTH_FILE: fp"${root}/auth.json".display(),
        PI_COMMAND: "factory-eval-pi",
        XSH_TARGET: fixture_target,
        XSH_MODULE_PATH: factory.display(),
      },
      stdout: fp"${root}/controller.stdout",
      stderr: fp"${root}/controller.stderr",
    ),
  )?
  test.ok(status.ok, fs.read_text(fp"${root}/controller.stderr")?)?
  let report = json.read(fp"${run_dir}/report.json")?
  test.ok(schema.valid(report, "phase"))?
  test.eq(schema.value_text(json.get(report, ["result"], "")), "pass")?
  test.eq(json.get(json.read(fp"${run_dir}/required-outputs.json")?, ["required"], false), true)?
  test.eq(json.get(json.read(fp"${run_dir}/workers/eval-worker/task-bigfiles-1/run.json")?, ["result"], ""), "pass")?
  test.ok(fs.exists(fp"${run_dir}/CTO-REPORT.md")?)?
}

proc test_organization_controller_completes_primary_and_design_phases(ctx: TestContext) [fs, process, env, error] {
  let root = test.temp_dir(ctx, name: "organization-controller-success")?
  let factory = fs.cwd()?
  let fixture_factory = fp"${root}/factory"
  let xsh_repo = fp"${factory}/../xsh".resolve()?
  let bin_dir = fp"${root}/bin"
  let fake_phase = fp"${bin_dir}/fake-phase-controller.xsh"
  fs.mkdir(bin_dir)?
  fs.mkdir(fixture_factory)?
  fs.mkdir(fp"${fixture_factory}/factory")?
  fs.mkdir(fp"${fixture_factory}/factory/tools")?
  fs.mkdir(fp"${fixture_factory}/runtime")?
  fs.mkdir(fp"${fixture_factory}/templates")?
  fs.mkdir(fp"${fixture_factory}/tickets")?
  fs.mkdir(fp"${fixture_factory}/evals")?
  fs.mkdir(fp"${fixture_factory}/evals/task-bigfiles")?
  for relative in [
    "factory/control.xsh",
    "factory/schema.xsh",
    "factory/tools/audit.xsh",
    "factory/tools/cto-report.xsh",
    "runtime/handbook.md",
    "runtime/handbook-ledger.md",
    "evals/task-bigfiles/EVAL.md",
    "templates/CTO-IMPROVEMENT.md",
    "templates/CTO-PRODUCTIVITY-REPORT.md",
    "templates/ORGANIZATION-PHASE-REQUEST.md",
    "templates/TICKET.md",
    "templates/TICKET-RETIRED-EVAL-DISPOSITION.md",
    "templates/CTO-REPORT.md",
    "templates/CTO-EMPLOYEE.md",
    "templates/CTO-WORKER.md",
    "templates/CTO-TOOL-ERROR.md",
    "templates/CTO-PHASE.md",
    "templates/CTO-TOTAL.md",
  ] {
    fs.copy(fp"${factory}/${relative}", fp"${fixture_factory}/${relative}", overwrite: true)?
  }

  fs.write(
    fp"${root}/organization-request.md",
    """# Coverage organization request

## Mode

- `organization`

## Active evals

- `task-bigfiles`

## Trial plan

- Count: `1`

## New eval proposals

- Count: `1`

## Approved tickets

- None.
""",
  )?
  fs.write(
    fp"${root}/auth.json",
    """{}
""",
  )?
  fs.write(
    fake_phase,
    r"""#!/bin/sh
mkdir -p "$FACTORY_PHASE_DIR"
cat > "$FACTORY_PHASE_DIR/report.json" <<EOF
{
  "schema_version": 1,
  "kind": "phase",
  "identity": {
    "run_id": "$(basename "$FACTORY_PHASE_DIR")",
    "mode": "$FACTORY_MODE"
  },
  "state": "completed",
  "result": "pass",
  "data": {
    "mode": "$FACTORY_MODE",
    "cost": {
      "workers": 0,
      "assistant_turns": 0,
      "total_bucket_tokens": 0,
      "cost_usd": 0.0,
      "tool_errors": 0
    }
  },
  "findings": [],
  "artifacts": []
}
EOF
exit 0
""",
  )?
  test.ok(command_ok(process.which("chmod")?, ["chmod", "+x", fake_phase.display()])?)?
  test.ok(! fs.exists(fp"${fixture_factory}/runs/ORGANIZATION-ACTIVE")?)?

  let xsh = process.which("xsh")?
  let inherited_path = env.get("PATH")?
  let status = process.run(
    process.command_argv(
      xsh,
      [
        xsh.display(),
        fp"${factory}/factory/controllers/organization.xsh",
        "--",
        fp"${root}/organization-request.md".display(),
      ],
      cwd: factory,
      env: {
        FACTORY_DESIGN_CONTROLLER: fake_phase.display(),
        FACTORY_CHILD_RUNNER: fake_phase.display(),
        FACTORY_DIR: fixture_factory.display(),
        FACTORY_FORCE_IMAGE_REBUILD: "false",
        FACTORY_PRIMARY_CONTROLLER: fake_phase.display(),
        FACTORY_SKIP_CYCLE_BUDGET: "true",
        FACTORY_XSH_REPO: xsh_repo.display(),
        HOME: root.display(),
        PATH: f"${bin_dir.display()}:${inherited_path}",
        PI_AUTH_FILE: fp"${root}/auth.json".display(),
        PI_COMMAND: "unused-fixture-pi",
        XSH_MODULE_PATH: factory.display(),
      },
      stdout: fp"${root}/organization.stdout",
      stderr: fp"${root}/organization.stderr",
    ),
  )?
  test.ok(status.ok, fs.read_text(fp"${root}/organization.stderr")?)?
  let output = fs.read_text(fp"${root}/organization.stdout")?
  test.contains(output, "factory organization run:")?
  test.contains(output, "(pass)")?
  let run_text = output.lines().get(1, "").replace("factory organization run: ", "").split(" (").get(0, "").trim()
  let organization_run = fp"${run_text}"
  defer fs.remove(organization_run, missing_ok: true)?
  let report = json.read(fp"${organization_run}/report.json")?
  test.ok(schema.valid(report, "run"))?
  test.eq(schema.value_text(json.get(report, ["result"], "")), "pass")?
  test.eq(schema.value_text(json.get(report, ["data", "outcomes", "evaluator"], "")), "pass")?
  test.ok(fs.exists(fp"${organization_run}/phases/01-eval/report.json")?)?
  test.ok(fs.exists(fp"${organization_run}/phases/02-eval-design/report.json")?)?
  test.ok(fs.exists(fp"${organization_run}/CTO-PRODUCTIVITY-REPORT.md")?)?
}

proc test_untried_approved_eval_selection(ctx: TestContext) [fs, error] {
  let root = test.temp_dir(ctx, name: "untried-eval-selection")?
  fs.mkdir(fp"${root}/evals/task-a")?
  fs.mkdir(fp"${root}/evals/task-b")?
  fs.mkdir(fp"${root}/evals/task-c")?
  fs.write(
    fp"${root}/evals/task-a/EVAL.md",
    """# Eval task-a

## Status

Approved.
""",
  )?
  fs.write(
    fp"${root}/evals/task-b/EVAL.md",
    """# Eval task-b

## Status

Approved.
""",
  )?
  fs.write(
    fp"${root}/evals/task-c/EVAL.md",
    """# Eval task-c

## Status

Draft.
""",
  )?
  fs.mkdir(fp"${root}/runs/run-1/workers/eval-worker/task-b-1")?
  json.write(
    fp"${root}/runs/run-1/workers/eval-worker/task-b-1/report.json",
    {
      schema_version: 1,
      kind: "worker",
      identity: {
        role: "eval-worker",
        worker_id: "task-b-1",
        eval_id: "task-b",
        run_id: "run-1",
      },
      state: "completed",
      result: "pass",
      findings: [],
      artifacts: [],
    },
    pretty: true,
  )?
  test.eq(runtime.untried_approved_evals(root)?, ["task-a"])?
  test.eq(runtime.next_untried_approved_evals(root, 2)?, ["task-a"])?
  test.eq(runtime.next_untried_approved_eval(root)?, "task-a")?
  test.eq(runtime.adaptive_approved_evals(root, 2)?, ["task-a", "task-b"])?

  fs.mkdir(fp"${root}/runs/run-2/workers/eval-worker/task-a-1")?
  json.write(
    fp"${root}/runs/run-2/workers/eval-worker/task-a-1/report.json",
    {
      schema_version: 1,
      kind: "worker",
      identity: {
        role: "eval-worker",
        worker_id: "task-a-1",
        eval_id: "task-a",
        run_id: "run-2",
      },
      state: "completed",
      result: "pass",
      findings: [],
      artifacts: [],
    },
    pretty: true,
  )?
  test.eq(runtime.untried_approved_evals(root)?, [])?
  test.eq(runtime.adaptive_approved_evals(root, 2)?, ["task-a", "task-b"])?
}

proc test_eval_trends_aggregates_historical_worker_reports(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "eval-trends")?
  let factory = fs.cwd()?
  let report_dir = fp"${root}/runs/run-1/workers/eval-worker/task-bigfiles-1"
  fs.mkdir(report_dir)?
  json.write(
    fp"${report_dir}/report.json",
    {
      schema_version: 1,
      kind: "worker",
      identity: {
        role: "eval-worker",
        worker_id: "task-bigfiles-1",
        eval_id: "task-bigfiles",
      },
      state: "completed",
      result: "pass",
      usage: {
        assistant_turns: 10,
        total_bucket_tokens: 100.0,
        tool_errors: 1,
        cost_usd: 0.01,
      },
      timing: {
        session_span_ms: 1000,
      },
      provider_telemetry: {
        retry_count: 0,
        provider_errors: [],
      },
      execution: {
        classification: "pass",
      },
      findings: [],
      artifacts: [],
    },
    pretty: true,
  )?
  let xsh = process.which("xsh")?
  let output = fp"${root}/output.txt"
  let status = process.run(
    process.command_argv(
      xsh,
      [xsh.display(), fp"${factory}/factory/tools/eval-trends.xsh", "--", "--factory-dir", root.display()],
      cwd: factory,
      stdout: output,
      env: {XSH_MODULE_PATH: factory.display(), FACTORY_DIR: factory.display()},
    ),
  )?
  test.ok(status.ok, "eval trend tool should summarize a fixture report")?
  let text = output.read_text()?
  test.contains(text, "task-bigfiles")?
  test.contains(text, "10")?
  test.contains(text, "100")?
}

proc test_session_report_is_structured_and_counts_thinking(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "structured-session")?
  let session = fp"${root}/session.jsonl"
  let output = fp"${root}/report.json"
  fs.write(
    session,
    r"""
{"timestamp":"2026-08-01T12:00:00.000Z","type":"message","message":{"role":"user","content":"task"}}
{"timestamp":"2026-08-01T12:00:01.000Z","type":"message","message":{"role":"assistant","provider":"openrouter","model":"deepseek/deepseek-v4-flash-0731","stopReason":"toolUse","content":[{"type":"thinking","thinking":"inspect"},{"type":"toolCall","name":"read"}],"usage":{"input":10,"output":20,"reasoning":7,"totalTokens":30,"cost":{"total":0.003}}}}
{"timestamp":"2026-08-01T12:00:02.000Z","type":"message","message":{"role":"toolResult","toolName":"read","isError":false,"usage":{"input":2,"output":3,"totalTokens":5,"cost":{"total":0.0005}}}}
""",
  )?
  let status = run_session_report(session, output)?
  test.ok(status, "known-cost session should normalize successfully")?
  let report = json.read(output)?
  test.ok(schema.valid(report, "worker"))?
  test.eq(json.get(report, ["usage", "assistant_turns"], 0), 1)?
  test.eq(json.get(report, ["usage", "thinking_blocks"], 0), 1)?
  test.eq(schema.value_text(json.get(report, ["usage", "reasoning_tokens"], null)), "7")?
  test.eq(json.get(report, ["usage", "tool_errors"], 0), 0)?
  test.eq(json.get(report, ["provider_telemetry", "present"], true), false)?
  test.eq(json.get(report, ["result"], "unknown"), "pass")?
  test.ok(! fs.exists(fp"${root}/WORKER-REPORT.md")?)?
  test.ok(! fs.exists(fp"${root}/thinking.md")?)?
}

proc test_session_report_captures_provider_telemetry(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "provider-telemetry")?
  let session = fp"${root}/session.jsonl"
  let events = fp"${session.display()}.events.jsonl"
  let output = fp"${root}/report.json"
  fs.write(
    session,
    r"""
{"type":"message","timestamp":"2026-08-01T12:00:00.000Z","message":{"role":"assistant","provider":"fixture","model":"fixture","content":[],"usage":{"output":20,"cost":{"total":0.001}}}}
""",
  )?
  fs.write(
    events,
    r"""
{"type":"turn_start","timestamp":1000}
{"type":"auto_retry_start","attempt":1,"delayMs":2000,"errorMessage":"503 overloaded"}
{"type":"auto_retry_end","success":true,"attempt":1}
{"type":"turn_end","message":{"role":"assistant","timestamp":3000,"usage":{"output":20}}}
""",
  )?
  test.ok(run_session_report(session, output)?, "telemetry fixture should normalize")?
  let report = json.read(output)?
  test.eq(json.get(report, ["provider_telemetry", "present"], false), true)?
  test.eq(json.get(report, ["provider_telemetry", "retry_count"], 0), 1)?
  test.eq(json.get(report, ["provider_telemetry", "retry_delay_ms"], 0), 2000)?
  test.eq(json.get(report, ["provider_telemetry", "retry_successes"], 0), 1)?
  test.eq(json.get(report, ["provider_telemetry", "event_turns"], 0), 1)?
  test.eq(schema.value_text(json.get(report, ["provider_telemetry", "output_tokens_per_second"], null)), "10")?
}

proc test_session_report_retains_every_tool_error_in_json(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "structured-tool-errors")?
  let session = fp"${root}/session.jsonl"
  let output = fp"${root}/report.json"
  fs.write(
    session,
    r"""
{"timestamp":"2026-08-01T12:00:01.000Z","type":"message","message":{"role":"assistant","provider":"openrouter","model":"fixture","content":[{"type":"toolCall","name":"bash"}],"usage":{"input":1,"output":1,"cost":{"total":0.001}}}}
{"timestamp":"2026-08-01T12:00:02.000Z","type":"message","message":{"role":"toolResult","toolName":"bash","isError":true,"content":[{"type":"text","text":"invalid xsht api query 1"}]}}
{"timestamp":"2026-08-01T12:00:03.000Z","type":"message","message":{"role":"assistant","provider":"openrouter","model":"fixture","content":[{"type":"toolCall","name":"bash"}]}}
{"timestamp":"2026-08-01T12:00:04.000Z","type":"message","message":{"role":"toolResult","toolName":"bash","isError":true,"content":[{"type":"text","text":"invalid xsht api query 2"}]}}
""",
  )?
  let status = run_session_report(session, output)?
  test.ok(status, "tool failures do not prevent structured normalization")?
  let report = json.read(output)?
  test.eq(json.get(report, ["usage", "tool_errors"], 0), 2)?
  let errors = json.get(report, ["tool_errors"], [])
  match errors {
    values is List[Any] => {
      test.eq(values.len(), 2)?
      test.contains(schema.value_text(json.get(values[0], ["summary"], "")), "invalid xsht api query 1")?
      test.contains(schema.value_text(json.get(values[1], ["summary"], "")), "invalid xsht api query 2")?
    }
    _ => test.ok(false, "tool_errors must be a JSON list")?
  }

  test.ok(! fs.exists(fp"${root}/TOOL-ERRORS.md")?)?
  test.eq(json.get(report, ["provider_telemetry", "present"], true), false)?
}

proc test_session_report_fails_closed_on_unknown_cost(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "unknown-cost")?
  let session = fp"${root}/session.jsonl"
  let output = fp"${root}/report.json"
  fs.write(
    session,
    """{"type":"message","message":{"role":"assistant","content":[]}}
""",
  )?
  let status = run_session_report(session, output)?
  test.ok(! status, "unknown provider cost must fail the worker gate")?
  test.eq(json.get(json.read(output)?, ["result"], ""), "unknown")?
}

proc write_eval_phase_fixture(root: Path, factory: Path) [fs, error] {
  fs.mkdir(fp"${root}/workers/eval-worker/task-tags-1")?
  fs.mkdir(fp"${root}/workers/eval-manager/task-tags")?
  fs.mkdir(fp"${root}/workers/director/director")?
  fs.mkdir(fp"${root}/lineage")?
  fs.copy(fp"${factory}/runtime/handbook.md", fp"${root}/lineage/handbook-approved.md", overwrite: true)?
  fs.write(
    fp"${root}/lineage/handbook-candidate.md",
    """candidate handbook
""",
  )?
  fs.mkdir(fp"${root}/phases/02-eval-design")?
  fs.write(
    fp"${root}/phases/02-eval-design/CTO-EVAL-REVIEW.md",
    """# Eval review

phase review
""",
  )?
  fs.write(
    fp"${root}/CYCLE-REQUEST.md",
    """# Cycle

## Mode

- `eval`

## Active evals

- `task-tags`

## Trial plan

- Count: `1`

## New eval proposals

- Count: `0`
""",
  )?
  fs.write(
    fp"${root}/lineage/handbook-approved.md",
    """approved
""",
  )?
  fs.write(
    fp"${root}/lineage/handbook-candidate.md",
    """candidate
""",
  )?
  json.write(
    fp"${root}/workers/eval-worker/task-tags-1/report.json",
    {
      schema_version: 1,
      kind: "worker",
      identity: {
        role: "eval-worker",
        worker_id: "task-tags-1",
      },
      state: "completed",
      result: "pass",
      session: "workers/eval-worker/task-tags-1/session.jsonl",
      execution: {
        result: "fail",
        classification: "worker_failed",
      },
      usage: {
        assistant_turns: 2,
        total_bucket_tokens: 30,
        cost_usd: 0.01,
        budget_usd: 0.50,
        tool_errors: 0,
      },
      tool_errors: [],
      findings: [],
      artifacts: [],
    },
    pretty: true,
  )?
  fs.write(
    fp"${root}/workers/eval-worker/task-tags-1/session.jsonl",
    """{}
""",
  )?
  fs.write(
    fp"${root}/workers/eval-worker/task-tags-1/run.json",
    """{"eval_id":"task-tags","trial_id":"1","result":"pass","protocol":{"artifact_present":true,"review_ok":true},"correctness":{"exact":true},"restrictions":{"passed":true},"timings":{"passed":true}}
""",
  )?
  json.write(
    fp"${root}/workers/eval-manager/task-tags/report.json",
    {
      schema_version: 1,
      kind: "worker",
      identity: {
        role: "eval-manager",
        worker_id: "task-tags",
      },
      state: "completed",
      result: "pass",
      usage: {
        assistant_turns: 1,
        total_bucket_tokens: 10,
        cost_usd: 0.01,
        budget_usd: 0.15,
        tool_errors: 0,
      },
      tool_errors: [],
      findings: [],
      artifacts: [],
    },
    pretty: true,
  )?
  json.write(
    fp"${root}/workers/director/director/report.json",
    {
      schema_version: 1,
      kind: "worker",
      identity: {
        role: "director",
        worker_id: "director",
      },
      state: "completed",
      result: "pass",
      usage: {
        assistant_turns: 1,
        total_bucket_tokens: 10,
        cost_usd: 0.01,
        budget_usd: 0.06,
        tool_errors: 0,
      },
      tool_errors: [],
      findings: [],
      artifacts: [],
    },
    pretty: true,
  )?
  fs.write(
    fp"${root}/workers/eval-manager/task-tags/REPORT.md",
    """# Manager

## Result

pass

## Effort metrics

fixture

## Usage and cost

fixture

## Thinking evidence

fixture

## Tool-error findings

None.

## Timing evidence

fixture

## Observation classification

fixture

## Handbook decision

unchanged

## Tickets created

None.

## Post-merge decisions

None.

## Next replay

None.

## North-star impact

fixture
""",
  )?
  fs.write(
    fp"${root}/workers/director/director/REPORT.md",
    """# Director

## Result

pass

## Cycle

fixture

## Children

fixture

## Required-output status

pass

## North-star impact

fixture
""",
  )?
}

proc test_audit_accepts_concise_exact_manifest(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "audit-exact-manifest")?
  let factory = fs.cwd()?
  write_eval_phase_fixture(root, factory)?
  fs.write(
    fp"${root}/workers/eval-worker/task-tags-1/run.json",
    """{"eval_id":"task-tags","trial_id":"1","result":"pass","protocol":{"artifact_present":true,"review_ok":true},"correctness":{"exact":true},"restrictions":{"passed":true},"timings":{"passed":true}}
""",
  )?
  let status = process.run(
    process.command_argv(
      process.which("xsh")?,
      ["xsh", fp"${factory}/factory/tools/audit.xsh", "--", root.display(), "eval"],
      cwd: factory,
      env: {FACTORY_DIR: factory.display(), XSH_MODULE_PATH: factory.display(), FACTORY_XSH_COMMIT: "fixture"},
    ),
  )?
  test.ok(status.ok, "audit must accept an exact=true package manifest")?
  test.eq(json.get(json.read(fp"${root}/report.json")?, ["result"], ""), "pass")?
}

proc test_audit_accepts_per_case_correctness_manifest(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "audit-case-map-manifest")?
  let factory = fs.cwd()?
  write_eval_phase_fixture(root, factory)?
  fs.write(
    fp"${root}/workers/eval-worker/task-tags-1/run.json",
    """{"eval_id":"task-tags","trial_id":"1","result":"pass","protocol":{"artifact_present":true,"review_ok":true},"correctness":{"public":true,"hidden":true},"restrictions":{"passed":true},"timings":{"passed":true}}
""",
  )?
  let status = process.run(
    process.command_argv(
      process.which("xsh")?,
      ["xsh", fp"${factory}/factory/tools/audit.xsh", "--", root.display(), "eval"],
      cwd: factory,
      env: {FACTORY_DIR: factory.display(), XSH_MODULE_PATH: factory.display(), FACTORY_XSH_COMMIT: "fixture"},
    ),
  )?
  test.ok(status.ok, "audit must accept a per-case correctness manifest")?
  test.eq(json.get(json.read(fp"${root}/report.json")?, ["result"], ""), "pass")?
}

proc test_audit_compiles_one_phase_report(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "audit-phase")?
  let factory = fs.cwd()?
  write_eval_phase_fixture(root, factory)?
  let xsh = process.which("xsh")?
  let status = process.run(
    process.command_argv(
      xsh,
      [xsh.display(), fp"${factory}/factory/tools/audit.xsh", "--", root.display(), "eval"],
      cwd: factory,
      env: {FACTORY_DIR: factory.display(), XSH_MODULE_PATH: factory.display(), FACTORY_XSH_COMMIT: "fixture"},
    ),
  )?
  test.ok(status.ok, "audit compiler should produce a phase report")?
  let report = json.read(fp"${root}/report.json")?
  test.ok(schema.valid(report, "phase"))?
  test.eq(json.get(report, ["result"], ""), "pass")?
  test.eq(json.get(report, ["data", "cost", "tool_errors"], -1), 0)?
  test.eq(json.get(report, ["data", "tool_errors"], []).len(), 0)?
  test.ok(! fs.exists(fp"${root}/AUDIT.md")?)?
  test.ok(! fs.exists(fp"${root}/COST.md")?)?
}

proc test_audit_preserves_controller_required_output_failure(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "audit-required-output-gate")?
  let factory = fs.cwd()?
  write_eval_phase_fixture(root, factory)?
  json.write(fp"${root}/required-outputs.json", {required: false, manager_report: false}, pretty: true)?
  let xsh = process.which("xsh")?
  let status = process.run(
    process.command_argv(
      xsh,
      [xsh.display(), fp"${factory}/factory/tools/audit.xsh", "--", root.display(), "eval"],
      cwd: factory,
      env: {FACTORY_DIR: factory.display(), XSH_MODULE_PATH: factory.display(), FACTORY_XSH_COMMIT: "fixture"},
    ),
  )?
  test.ok(status.ok, "audit compiler should write a report even when the gate fails")?
  let report = json.read(fp"${root}/report.json")?
  test.eq(json.get(report, ["result"], ""), "fail")?
  test.eq(json.get(report, ["data", "required_outputs", "required"], true), false)?
}

proc test_organization_audit_only_admits_direct_phase_children(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "audit-organization")?
  let factory = fs.cwd()?
  fs.mkdir(fp"${root}/phases/01-eval/workers/eval-worker")?
  json.write(
    fp"${root}/phases/01-eval/report.json",
    {
      schema_version: 1,
      kind: "phase",
      identity: {
        run_id: "01-eval",
        mode: "eval",
      },
      state: "completed",
      result: "pass",
      data: {
        cost: {
          workers: 0,
          assistant_turns: 0,
          total_bucket_tokens: 0,
          cost_usd: 0.0,
          tool_errors: 0,
        },
      },
      findings: [],
      artifacts: [],
    },
    pretty: true,
  )?
  let xsh = process.which("xsh")?
  let status = process.run(
    process.command_argv(
      xsh,
      [xsh.display(), fp"${factory}/factory/tools/audit.xsh", "--", root.display(), "organization"],
      cwd: factory,
      env: {FACTORY_DIR: factory.display(), XSH_MODULE_PATH: factory.display(), FACTORY_XSH_COMMIT: "fixture"},
    ),
  )?
  test.ok(status.ok, "organization audit should accept the direct phase")?
  let report = json.read(fp"${root}/report.json")?
  test.ok(schema.valid(report, "run"))?
  test.eq(json.get(report, ["result"], ""), "pass")?
  let phases = json.get(report, ["data", "phases"], [])
  match phases {
    values is List[Any] => test.eq(values.len(), 1)?
    _ => test.ok(false, "organization phases must be a list")?
  }
}

proc test_organization_audit_projects_throughput_from_existing_evidence(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "audit-organization-throughput")?
  let factory = fs.cwd()?
  fs.mkdir(fp"${root}/phases/01-reuse-task-a")?
  fs.mkdir(fp"${root}/workers/engineer/task-b")?
  json.write(
    fp"${root}/phases/01-reuse-task-a/report.json",
    {
      schema_version: 1,
      kind: "phase",
      identity: {run_id: "01-reuse-task-a", mode: "ticket-reuse", ticket_id: "task-a"},
      state: "completed",
      result: "pass",
      data: {fast_path: true},
      findings: [],
      artifacts: [],
    },
    pretty: true,
  )?
  json.write(
    fp"${root}/workers/engineer/task-b/report.json",
    {
      schema_version: 1,
      kind: "worker",
      identity: {role: "engineer", worker_id: "task-b"},
      state: "completed",
      result: "pass",
      usage: {
        assistant_turns: 1,
        total_bucket_tokens: 1,
        cost_usd: 0.01,
        budget_usd: 0.50,
        tool_errors: 0,
      },
      tool_errors: [],
      findings: [],
      artifacts: [],
    },
    pretty: true,
  )?
  fs.write(
    fp"${root}/events.jsonl",
    """{"event_id":"10-reeval-started","subject":"task-a-reevaluation"}
{"event_id":"80-reeval-completed","subject":"task-a-reevaluation","state":"completed"}
{"event_id":"86-ticket-task-a-delivered","subject":"task-a","payload":{"status":"delivered"}}
""",
  )?
  let xsh = process.which("xsh")?
  let status = process.run(
    process.command_argv(
      xsh,
      [xsh.display(), fp"${factory}/factory/tools/audit.xsh", "--", root.display(), "organization"],
      cwd: factory,
      env: {FACTORY_DIR: factory.display(), XSH_MODULE_PATH: factory.display(), FACTORY_XSH_COMMIT: "fixture"},
    ),
  )?
  test.ok(status.ok, "organization audit should project throughput into the run report")?
  let throughput = json.get(json.read(fp"${root}/report.json")?, ["data", "throughput"], null)
  test.eq(json.get(throughput, ["admitted_tickets"], -1), 1)?
  test.eq(json.get(throughput, ["fresh_engineer_rows"], -1), 1)?
  test.eq(json.get(throughput, ["retained_fast_paths"], -1), 1)?
  test.eq(json.get(throughput, ["reeval_passed"], -1), 1)?
  test.eq(json.get(throughput, ["delivered_tickets"], -1), 1)?
  test.ok(json.get(throughput, ["overlap_retained_fresh"], false))?
}

proc test_reconciliation_ignores_retired_branch_reference(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "retired-branch-reconciliation")?
  let factory = fs.cwd()?
  let product = fp"${root}/product"
  fs.mkdir(fp"${root}/tickets")?
  fs.mkdir(fp"${root}/tickets")?
  fs.mkdir(fp"${root}/templates")?
  fs.copy(fp"${factory}/templates/TICKET.md", fp"${root}/templates/TICKET.md", overwrite: true)?
  fs.mkdir(product)?
  let git = process.which("git")?
  test.ok(command_ok(git, ["git", "-C", product.display(), "init", "-q", "-b", "main"])?)?
  test.ok(command_ok(git, ["git", "-C", product.display(), "config", "user.email", "factory@test"])?)?
  test.ok(command_ok(git, ["git", "-C", product.display(), "config", "user.name", "Factory Test"])?)?
  fs.write(
    fp"${product}/README",
    """base
""",
  )?
  test.ok(command_ok(git, ["git", "-C", product.display(), "add", "README"])?)?
  test.ok(command_ok(git, ["git", "-C", product.display(), "commit", "-qm", "base"])?)?
  fs.copy(fp"${factory}/templates/TICKET.md", fp"${root}/tickets/task-a.md", overwrite: true)?
  let ticket = fs.read_text(fp"${root}/tickets/task-a.md")?.replace("- Eval:", "- Eval: task-envcfg")
  fs.write(fp"${root}/tickets/task-a.md", ticket)?
  let helper = fp"${root}/helper.xsh"
  fs.write(
    helper,
    """use factory.runtime as runtime
proc main() [fs, process, env, error, io] { let repo = env.path("FACTORY_XSH_REPO")?; let _ = runtime.reconcile_tickets(fs.cwd()?, repo, run.text "git" "-C" $repo.display() "rev-parse" "HEAD" ?)? }
""",
  )?
  let status = process.run(
    process.command_argv(
      process.which("xsh")?,
      ["xsh", helper.display()],
      cwd: root,
      env: {FACTORY_XSH_REPO: product.display(), XSH_MODULE_PATH: factory.display()},
    ),
  )?
  test.ok(status.ok, "reconciliation must ignore missing historical branches")?
}

proc test_retired_eval_closes_and_archives_ticket(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "retired-eval-ticket-lifecycle")?
  let factory = fs.cwd()?
  let product = fp"${root}/product"
  fs.mkdir(fp"${root}/tickets")?
  fs.mkdir(fp"${root}/templates")?
  fs.mkdir(fp"${root}/evals")?
  fs.copy(fp"${factory}/templates/TICKET.md", fp"${root}/templates/TICKET.md", overwrite: true)?
  fs.copy(
    fp"${factory}/templates/TICKET-RETIRED-EVAL-DISPOSITION.md",
    fp"${root}/templates/TICKET-RETIRED-EVAL-DISPOSITION.md",
    overwrite: true,
  )?
  fs.write(
    fp"${root}/evals/RETIREMENTS.md",
    """# Retired evals

## task-tags

Retired for fixture.
""",
  )?
  fs.mkdir(product)?
  let git = process.which("git")?
  test.ok(command_ok(git, ["git", "-C", product.display(), "init", "-q", "-b", "main"])?)?
  test.ok(command_ok(git, ["git", "-C", product.display(), "config", "user.email", "factory@test"])?)?
  test.ok(command_ok(git, ["git", "-C", product.display(), "config", "user.name", "Factory Test"])?)?
  fs.write(
    fp"${product}/README",
    """base
""",
  )?
  test.ok(command_ok(git, ["git", "-C", product.display(), "add", "README"])?)?
  test.ok(command_ok(git, ["git", "-C", product.display(), "commit", "-qm", "base"])?)?
  test.ok(command_ok(git, ["git", "-C", product.display(), "branch", "factory/task-tags-003/1"])?)?
  let ticket = fs.read_text(fp"${factory}/templates/TICKET.md")?.replace("- Eval:", "- Eval: `task-tags`")
  fs.write(fp"${root}/tickets/task-tags-003.md", ticket)?

  let closed = runtime.close_tickets_for_retired_evals(root)?
  test.eq(closed, ["task-tags-003"])?
  let closed_ticket = fs.read_text(fp"${root}/tickets/task-tags-003.md")?
  test.eq(control.ticket_status(closed_ticket), "Closed.")?
  test.contains(closed_ticket, "controller-owned director reconciliation")?
  test.contains(closed_ticket, "evals/RETIREMENTS.md")?

  test.eq(runtime.archive_retired_ticket_branches(product, root)?, 1)?
  let branches = run.text "git" "-C" $product "branch" "--format=%(refname:short)" ?
  test.contains(branches, "archive/retired/task-tags-003/1")?
  test.ok("factory/task-tags-003/1" not in branches)?
}

proc test_stale_branch_inventory_is_documented() [fs, error] {
  let runtime = fs.read_text(fp"${fs.cwd()?}/factory/runtime.xsh")?
  let cto = fs.read_text(fp"${fs.cwd()?}/factory/tools/cto.xsh")?
  test.contains(runtime, "stale_ticket_branches")?
  test.contains(cto, "Stale branch candidates")?
  test.contains(cto, "retire_stale_ticket_branches")?
  test.contains(runtime, "retire_stale_ticket_branches")?
}

proc test_eval_cap_is_admission_policy() [fs, error] {
  let launcher = fs.read_text(fp"${fs.cwd()?}/run.xsh")?
  test.contains(launcher, "max_eval_contracts()")?
  test.contains(launcher, "eval contract cap exceeded")?
}

proc test_cto_report_pins_factory_root() [fs, error] {
  let runtime = fs.read_text(fp"${fs.cwd()?}/factory/runtime.xsh")?
  test.contains(runtime, "env: {FACTORY_DIR: factory_dir.display(), XSH_MODULE_PATH: factory_dir.display()}")?
}

proc test_cto_briefing_reads_json_not_projection(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "cto-briefing")?
  let factory = fs.cwd()?
  write_eval_phase_fixture(root, factory)?
  json.write(
    fp"${root}/report.json",
    {
      schema_version: 1,
      kind: "phase",
      identity: {
        run_id: "fixture",
        mode: "eval",
      },
      state: "completed",
      result: "pass",
      data: {
        cost: {
          workers: 1,
          assistant_turns: 2,
          total_bucket_tokens: 30,
          cost_usd: 0.01,
          tool_errors: 0,
        },
      },
      findings: [],
      artifacts: [],
    },
    pretty: true,
  )?
  let output = fp"${root}/CTO-REPORT.md"
  let xsh = process.which("xsh")?
  let status = process.run(
    process.command_argv(
      xsh,
      [
        xsh.display(),
        fp"${factory}/factory/tools/cto-report.xsh",
        "--",
        "--run-dir",
        root.display(),
        "--output",
        output.display(),
        "--result",
        "pass",
      ],
      cwd: factory,
      env: {FACTORY_DIR: factory.display(), XSH_MODULE_PATH: factory.display()},
    ),
  )?
  test.ok(status.ok, "CTO compiler should consume structured reports")?
  let text = fs.read_text(output)?
  test.contains(text, "Structured run or phase report")?
  test.contains(text, "## Outcome dimensions")?
  test.contains(text, "workers/eval-worker/task-tags-1/report.json")?
  test.contains(text, "Execution: `fail`; classification: `worker_failed`")?
  test.contains(text, "- Result: `pass`")?
  test.contains(text, "phases/02-eval-design/CTO-EVAL-REVIEW.md")?
  test.contains(text, "phase review")?
  test.contains(text, "CTO-IMPROVEMENT.md")?
  test.contains(text, "## Handbook lineage")?
  test.contains(text, "lineage/handbook-candidate.md")?
  test.contains(text, "promotion or rejection decision required")?
  test.contains(text, "Historical candidates:")?
  test.contains(text, "ledger-dispositioned:")?
  test.ok("COST.md" not in text)?
  test.ok("TOOL-ERRORS.md" not in text)?
}

proc test_aggregate_budget_breach_writes_postmortem_and_stops(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "aggregate-budget")?
  let session = fp"${root}/session.jsonl"
  let marker = fp"${root}/AGGREGATE-BUDGET-BREACH"
  let stop = fp"${root}/AGGREGATE-BUDGET-STOP"
  let postmortem = fp"${root}/POSTMORTEM.md"
  fs.write(
    session,
    """{"type":"message","message":{"role":"assistant","usage":{"cost":{"total":0.60}}}}
""",
  )?
  let child = spawn process.command_argv("sh", ["sh", "-c", "sleep 5"])?
  let xsh = process.which("xsh")?
  let status = process.run(
    process.command_argv(
      xsh,
      [
        xsh.display(),
        fp"${fs.cwd()?}/factory/tools/cycle-budget-watch.xsh",
        "--",
        "--run-dir",
        root.display(),
        "--pid",
        f"${child.pid}",
        "--budget-usd",
        "0.50",
        "--marker",
        marker.display(),
        "--stop",
        stop.display(),
        "--postmortem",
        postmortem.display(),
      ],
      env: {FACTORY_DIR: fs.cwd()?.display(), XSH_MODULE_PATH: fs.cwd()?.display()},
    ),
  )?
  let child_status = wait child?
  test.ok(! status.ok, "aggregate breach watcher must return failure")?
  test.ok(! child_status.ok, "aggregate breach must terminate its controller-owned child")?
  test.ok(fs.exists(marker)?)?
  test.ok(fs.exists(postmortem)?)?
  test.contains(fs.read_text(postmortem)?, "Factory cycle postmortem")?
}

proc test_structured_provenance_event_exists() [fs, error] {
  let runtime = fs.read_text(fp"${fs.cwd()?}/factory/runtime.xsh")?
  let ticket = fs.read_text(fp"${fs.cwd()?}/factory/controllers/ticket.xsh")?
  test.contains(runtime, "emit_structured_event")?
  test.contains(ticket, "amended_commit")?
}

proc test_organization_delivery_merges_exact_engineer_commit(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "organization-delivery")?
  let factory = fp"${root}/factory"
  let product = fp"${root}/product"
  let phase = fp"${factory}/runs/run-1/phases/01-ticket"
  let worker = fp"${phase}/workers/engineer/task-a"
  let worktree = fp"${root}/worktree"
  fs.mkdir(worker)?
  fs.mkdir(product)?
  let git = process.which("git")?
  test.ok(command_ok(git, ["git", "-C", product.display(), "init", "-q", "-b", "main"])?)?
  test.ok(command_ok(git, ["git", "-C", product.display(), "config", "user.email", "factory@test"])?)?
  test.ok(command_ok(git, ["git", "-C", product.display(), "config", "user.name", "Factory Test"])?)?
  fs.write(fp"${product}/README", "base\n")?
  test.ok(command_ok(git, ["git", "-C", product.display(), "add", "README"])?)?
  test.ok(command_ok(git, ["git", "-C", product.display(), "commit", "-qm", "base"])?)?
  let base = run.text "git" "-C" $product "rev-parse" "HEAD" ?
  test.ok(
    command_ok(
      git,
      [
        "git",
        "-C",
        product.display(),
        "worktree",
        "add",
        "-q",
        "-b",
        "factory/task-a/run-1",
        worktree.display(),
        base.trim(),
      ],
    )?,
  )?
  fs.write(fp"${worktree}/README", "base\nengineer\n")?
  test.ok(command_ok(git, ["git", "-C", worktree.display(), "add", "README"])?)?
  test.ok(command_ok(git, ["git", "-C", worktree.display(), "commit", "-qm", "engineer"])?)?
  let implementation = run.text "git" "-C" $worktree "rev-parse" "HEAD" ?
  fs.write(
    fp"${worker}/REPORT.md",
    f"""## Branch

factory/task-a/run-1

## Commit

${implementation.trim()}
""",
  )?
  let evidence = runtime.merge_validated_ticket(product, phase, "task-a", base.trim())?
  test.ok(evidence.merged, "validated organization delivery must update product HEAD")?
  let product_head = run.text "git" "-C" $product "rev-parse" "HEAD" ?
  let product_status = run.text "git" "-C" $product "status" "--porcelain" ?
  test.eq(product_head.trim(), implementation.trim())?
  test.ok(product_status.trim() == "")?
  test.ok(command_ok(git, ["git", "-C", product.display(), "worktree", "remove", "-f", worktree.display()])?)?

  let second_worker = fp"${phase}/workers/engineer/task-b"
  let second_worktree = fp"${root}/second-worktree"
  fs.mkdir(second_worker)?
  test.ok(
    command_ok(
      git,
      [
        "git",
        "-C",
        product.display(),
        "worktree",
        "add",
        "-q",
        "-b",
        "factory/task-b/run-1",
        second_worktree.display(),
        base.trim(),
      ],
    )?,
  )?
  fs.write(fp"${second_worktree}/SECOND", "second\n")?
  test.ok(command_ok(git, ["git", "-C", second_worktree.display(), "add", "SECOND"])?)?
  test.ok(command_ok(git, ["git", "-C", second_worktree.display(), "commit", "-qm", "second engineer"])?)?
  let second_implementation = run.text "git" "-C" $second_worktree "rev-parse" "HEAD" ?
  fs.write(
    fp"${second_worker}/REPORT.md",
    f"""## Branch

factory/task-b/run-1

## Commit

${second_implementation.trim()}
""",
  )?
  let second_evidence = runtime.merge_validated_ticket(product, phase, "task-b", base.trim())?
  test.ok(second_evidence.merged, "a second admitted branch must also be delivered")?
  test.ok(command_ok(git, ["git", "-C", product.display(), "merge-base", "--is-ancestor", implementation.trim(), "HEAD"])?)?
  test.ok(command_ok(git, ["git", "-C", product.display(), "merge-base", "--is-ancestor", second_implementation.trim(), "HEAD"])?)?
  test.ok(command_ok(git, ["git", "-C", product.display(), "worktree", "remove", "-f", second_worktree.display()])?)?

  # A retained branch from the old cycle baseline must still be deliverable
  # after an unrelated product commit advanced the current cycle baseline.
  fs.write(fp"${product}/CURRENT", "current\n")?
  test.ok(command_ok(git, ["git", "-C", product.display(), "add", "CURRENT"])?)?
  test.ok(command_ok(git, ["git", "-C", product.display(), "commit", "-qm", "current baseline"])?)?
  let current_base = run.text "git" "-C" $product "rev-parse" "HEAD" ?
  let third_worktree = fp"${root}/third-worktree"
  test.ok(
    command_ok(
      git,
      [
        "git",
        "-C",
        product.display(),
        "worktree",
        "add",
        "-q",
        "-b",
        "factory/task-c/run-1",
        third_worktree.display(),
        base.trim(),
      ],
    )?,
  )?
  fs.write(fp"${third_worktree}/THIRD", "third\n")?
  test.ok(command_ok(git, ["git", "-C", third_worktree.display(), "add", "THIRD"])?)?
  test.ok(command_ok(git, ["git", "-C", third_worktree.display(), "commit", "-qm", "third engineer"])?)?
  let third_implementation = run.text "git" "-C" $third_worktree "rev-parse" "HEAD" ?
  json.write(
    fp"${phase}/report.json",
    {
      data: {
        branch: "factory/task-c/run-1",
        implementation_commit: third_implementation.trim(),
        merge_base: base.trim(),
      },
    },
  )?
  let third_evidence = runtime.merge_validated_ticket(product, phase, "task-c", current_base.trim())?
  test.ok(third_evidence.merged, "a retained branch must merge from a verified common ancestor")?
  test.ok(command_ok(git, ["git", "-C", product.display(), "merge-base", "--is-ancestor", third_implementation.trim(), "HEAD"])?)?
  test.ok(command_ok(git, ["git", "-C", product.display(), "worktree", "remove", "-f", third_worktree.display()])?)?
}

proc test_engineer_provenance_amend(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "engineer-provenance")?
  let factory = fp"${root}/factory"
  let product = fp"${root}/product"
  let run_dir = fp"${factory}/runs/run-1"
  let worker_dir = fp"${run_dir}/workers/engineer/task-a"
  let assignment_file = fp"${run_dir}/messages/task-a.md"
  let patches = fp"${run_dir}/patches"
  let worktree = fp"${root}/worktree"
  fs.mkdir(worker_dir)?
  fs.mkdir(assignment_file.parent())?
  fs.mkdir(patches)?
  fs.mkdir(product)?
  fs.mkdir(worktree.parent())?
  let git = process.which("git")?
  test.ok(command_ok(git, ["git", "-C", product.display(), "init", "-q", "-b", "main"])?)?
  test.ok(command_ok(git, ["git", "-C", product.display(), "config", "user.email", "factory@test"])?)?
  test.ok(command_ok(git, ["git", "-C", product.display(), "config", "user.name", "Factory Test"])?)?
  fs.write(
    fp"${product}/README",
    """base
""",
  )?
  test.ok(command_ok(git, ["git", "-C", product.display(), "add", "README"])?)?
  test.ok(command_ok(git, ["git", "-C", product.display(), "commit", "-qm", "base"])?)?
  let base = run.text "git" "-C" $product "rev-parse" "HEAD" ?
  test.ok(
    command_ok(
      git,
      [
        "git",
        "-C",
        product.display(),
        "worktree",
        "add",
        "-q",
        "-b",
        "factory/task-a/run-1",
        worktree.display(),
        base.trim(),
      ],
    )?,
  )?
  fs.write(
    fp"${worktree}/README",
    """base
changed
""",
  )?
  test.ok(command_ok(git, ["git", "-C", worktree.display(), "add", "README"])?)?
  test.ok(command_ok(git, ["git", "-C", worktree.display(), "commit", "-qm", "change"])?)?
  let head = run.text "git" "-C" $worktree "rev-parse" "HEAD" ?
  fs.write(
    assignment_file,
    """controller assignment
""",
  )?
  let assignment_sha = hash.sha256(assignment_file)?.hex()
  let report = fp"${worker_dir}/report.json"
  let session = fp"${worker_dir}/session.jsonl"
  let missing = runtime.amend_engineer_commit(
    worktree,
    head.trim(),
    factory,
    run_dir,
    report,
    session,
    "task-a",
    "factory/task-a/run-1",
    base.trim(),
    assignment_sha,
    "missing",
  )?
  test.eq(missing, "")?
  let missing_session = fp"${worker_dir}/missing-session.jsonl"
  let missing_evidence = runtime.amend_engineer_commit(
    worktree,
    head.trim(),
    factory,
    run_dir,
    report,
    missing_session,
    "task-a",
    "factory/task-a/run-1",
    base.trim(),
    assignment_sha,
    "missing",
  )?
  test.eq(missing_evidence, "")?
  fs.write(
    fp"${worker_dir}/session.jsonl",
    """session evidence
""",
  )?
  fs.write(
    report,
    json.encode({
      models: ["openrouter/openai/gpt-5.6-luna"],
      usage: {
        assistant_turns: 81,
        tool_calls: 152,
        tool_errors: 11,
        thinking_blocks: 27,
        reasoning_tokens: 13963,
        total_bucket_tokens: 7348813,
        input_tokens: 243,
        output_tokens: 27898,
        cache_read_tokens: 7198079,
        cache_write_tokens: 122593,
        cost_usd: 0.104068015,
      },
      timing: {
        session_span_ms: 695496,
      },
    })? + "\n",
  )?
  let patch_path = fp"${patches}/task-a.diff"
  test.ok(runtime.write_engineer_patch(worktree, base.trim(), head.trim(), patch_path, fp"${patches}/task-a.stderr")?)?
  let patch_sha = hash.sha256(patch_path)?.hex()
  let amended = runtime.amend_engineer_commit(
    worktree,
    head.trim(),
    factory,
    run_dir,
    report,
    session,
    "task-a",
    "factory/task-a/run-1",
    base.trim(),
    assignment_sha,
    patch_sha,
  )?
  test.ok(amended != head.trim())?
  let message = run.text "git" "-C" $worktree "log" "-1" "--format=%B" ?
  test.contains(message, "Factory-Provenance-Version: 1")?
  test.contains(message, "Factory-Model: openai/gpt-5.6-luna")?
  test.contains(message, "Factory-Report-SHA256:")?
  test.contains(message, f"Factory-Assignment-SHA256: ${assignment_sha}")?
  test.contains(message, "Factory-Session-SHA256:")?
  test.contains(message, f"Factory-Patch-SHA256: ${patch_sha}")?
  test.contains(message, f"Factory-Patch-SHA256: ${patch_sha}")?
  test.contains(message, "Factory-Provenance-Version: 1")?
  test.contains(message, "Factory-Cost-USD: 0.104068015")?
  test.ok(command_ok(git, ["git", "-C", worktree.display(), "status", "--porcelain"])?)?
  fs.write(
    fp"${worktree}/DIRTY",
    """must block amendment
""",
  )?
  let dirty = runtime.amend_engineer_commit(
    worktree,
    amended,
    factory,
    run_dir,
    report,
    session,
    "task-a",
    "factory/task-a/run-1",
    base.trim(),
    assignment_sha,
    patch_sha,
  )?
  test.eq(dirty, "")?
  fs.remove(fp"${worktree}/DIRTY")?
  let second = runtime.amend_engineer_commit(
    worktree,
    amended,
    factory,
    run_dir,
    report,
    session,
    "task-a",
    "factory/task-a/run-1",
    base.trim(),
    assignment_sha,
    patch_sha,
  )?
  test.eq(second, amended)?
  test.ok(runtime.remove_clean_worktree(product, worktree)?)?
}

proc test_engineer_patch_survives_worktree_cleanup(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "patch-cleanup")?
  let product = fp"${root}/product"
  let worktree = fp"${root}/worktree"
  let patches = fp"${root}/patches"
  fs.mkdir(product)?
  fs.mkdir(patches)?
  let git = process.which("git")?
  test.ok(command_ok(git, ["git", "-C", product.display(), "init", "-q", "-b", "main"])?)?
  test.ok(command_ok(git, ["git", "-C", product.display(), "config", "user.email", "factory@test"])?)?
  test.ok(command_ok(git, ["git", "-C", product.display(), "config", "user.name", "Factory Test"])?)?
  fs.write(
    fp"${product}/README",
    """base
""",
  )?
  test.ok(command_ok(git, ["git", "-C", product.display(), "add", "README"])?)?
  test.ok(command_ok(git, ["git", "-C", product.display(), "commit", "-qm", "base"])?)?
  let base = run.text "git" "-C" $product "rev-parse" "HEAD" ?
  test.ok(
    command_ok(
      git,
      [
        "git",
        "-C",
        product.display(),
        "worktree",
        "add",
        "-q",
        "-b",
        "factory/test",
        worktree.display(),
        base.trim(),
      ],
    )?,
  )?
  fs.write(
    fp"${worktree}/README",
    """base
changed
""",
  )?
  test.ok(command_ok(git, ["git", "-C", worktree.display(), "add", "README"])?)?
  test.ok(command_ok(git, ["git", "-C", worktree.display(), "commit", "-qm", "change"])?)?
  let head = run.text "git" "-C" $worktree "rev-parse" "HEAD" ?
  let diff_path = fp"${patches}/task.diff"
  test.ok(runtime.write_engineer_patch(worktree, base.trim(), head.trim(), diff_path, fp"${patches}/task.stderr")?)?
  test.contains(fs.read_text(diff_path)?, "+changed")?
  test.ok(runtime.remove_clean_worktree(product, worktree)?)?
  test.ok(! fs.exists(worktree)?)?
  test.contains(run.text "git" "-C" $product "branch" "--list" "factory/test"?, "factory/test")?
}

proc test_run_worktree_cleanup_removes_dirty_worktrees_preserves_branch(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "run-worktree-cleanup")?
  let product = fp"${root}/product"
  let run_dir = fp"${root}/runs/run-1"
  let worktree = fp"${run_dir}/phases/01-ticket/worktrees/task-a"
  fs.mkdir(worktree.parent())?
  fs.mkdir(product)?
  let git = process.which("git")?
  test.ok(command_ok(git, ["git", "-C", product.display(), "init", "-q", "-b", "main"])?)?
  test.ok(command_ok(git, ["git", "-C", product.display(), "config", "user.email", "factory@test"])?)?
  test.ok(command_ok(git, ["git", "-C", product.display(), "config", "user.name", "Factory Test"])?)?
  fs.write(
    fp"${product}/README",
    """base
""",
  )?
  test.ok(command_ok(git, ["git", "-C", product.display(), "add", "README"])?)?
  test.ok(command_ok(git, ["git", "-C", product.display(), "commit", "-qm", "base"])?)?
  let base = run.text "git" "-C" $product "rev-parse" "HEAD" ?
  test.ok(
    command_ok(
      git,
      [
        "git",
        "-C",
        product.display(),
        "worktree",
        "add",
        "-q",
        "-b",
        "factory/task-a/run-1",
        worktree.display(),
        base.trim(),
      ],
    )?,
  )?
  fs.write(
    fp"${worktree}/DIRTY",
    """preserve branch evidence
""",
  )?
  test.ok(runtime.remove_run_worktrees(product, run_dir)?)?
  test.ok(! fs.exists(worktree)?)?
  test.contains(run.text "git" "-C" $product "branch" "--list" "factory/task-a/run-1"?, "factory/task-a/run-1")?
}

proc test_organization_reuses_existing_branch_without_duplicate_dispatch() [fs, error] {
  let organization = fs.read_text(fp"${fs.cwd()?}/factory/controllers/organization.xsh")?
  let reuse = fs.read_text(fp"${fs.cwd()?}/factory/controllers/reuse.xsh")?
  let launcher = fs.read_text(fp"${fs.cwd()?}/run.xsh")?
  test.contains(organization, "spawn_reuse_phase")?

  # Reuse mode must not gate the linked replay on a non-existent engineer
  # worker report; it uses the reuse phase report as the precondition.
  test.contains(organization, "if reuse_existing_branch {")?
  test.contains(organization, "phase_run_pass(primary_phase, \"report.json\")")?
  test.contains(reuse, "mode: \"ticket-reuse\"")?
  test.contains(reuse, "fast_path: true")?
  test.contains(organization, "retained branch fast path started before fresh primary wait")?
  test.contains(reuse, "worktree", "existing branch must use a detached worktree")?
  test.contains(launcher, "open_branch != \"\" and mode != \"organization\"")?
  test.contains(launcher, "open_branch != \"\" and mode != \"organization\"")?
  test.eq(
    runtime.ticket_worktree_path(/srv/xsh, /srv/factory/runs/run-1/phases/01-ticket, "task-a").display(),
    "/srv/.xsh-factory-worktrees/run-1/task-a",
  )?
}

proc test_organization_batches_retained_and_fresh_tickets() [fs, error] {
  let organization = fs.read_text(fp"${fs.cwd()?}/factory/controllers/organization.xsh")?
  test.contains(organization, "var reuse_tickets: List[Str] = []")?
  test.contains(organization, "var fresh_tickets: List[Str] = []")?
  test.contains(organization, r"""01-reuse-${reuse_ticket}""")?
  test.contains(organization, "fresh_tickets.len() > 0")?
  test.contains(organization, "reuse_primary_handle = spawn_reuse_phase")?
  test.contains(organization, "ticket_is_reused")?
  test.contains(organization, "runtime.merge_validated_ticket")?
  test.contains(organization, "reeval_handles: List[ProcessHandle] = []")?
  let audit = fs.read_text(fp"${fs.cwd()?}/factory/tools/audit.xsh")?
  test.contains(audit, "organization_throughput")?
  test.contains(audit, "overlap_linked_replays")?
}

proc test_organization_starts_independent_eval_before_primary_wait() [fs, error] {
  let organization = fs.read_text(fp"${fs.cwd()?}/factory/controllers/organization.xsh")?
  let before_primary_wait = organization.split("fresh_primary_ok = wait_child(primary_handle)?").get(0, "")
  test.contains(before_primary_wait, "for eval_id in independent_eval_ids")?
  test.contains(before_primary_wait, "let independent_eval_handle = spawn_child")?
  test.contains(before_primary_wait, "independent_eval_handles = independent_eval_handles.push")?
  test.contains(before_primary_wait, "reuse_primary_handle = spawn_reuse_phase")?
}

proc test_organization_supports_two_discovery_evals() [fs, error] {
  let organization = fs.read_text(fp"${fs.cwd()?}/factory/controllers/organization.xsh")?
  let launcher = fs.read_text(fp"${fs.cwd()?}/run.xsh")?
  test.contains(organization, "request_evals.len() > 1")?
  test.contains(organization, "independent_eval_requested")?
  test.contains(organization, "discovery_phase_number")?
  test.contains(organization, "independent_eval_ids")?
  test.contains(launcher, "next_untried_approved_evals(factory_dir, eval_values.len())")?
  test.contains(launcher, "ticketless organization discovery requires one to")?
  test.contains(organization, "max_concurrent_discovery_evals()")?
}

proc test_ticket_cycles_create_independent_eval_phase_boundary() [fs, error] {
  let organization = fs.read_text(fp"${fs.cwd()?}/factory/controllers/organization.xsh")?
  test.contains(organization, "if selected_ticket != \"\" {")?
  test.contains(organization, r"""fs.mkdir(fp"${phases_dir}/03-eval")?""")?
}

proc test_engineer_guidance_is_run_scoped() [fs, error] {
  let ticket = fs.read_text(fp"${fs.cwd()?}/factory/controllers/ticket.xsh")?
  let assignment = fs.read_text(fp"${fs.cwd()?}/templates/ENGINEER-ASSIGNMENT.md")?
  test.contains(ticket, "let guidance_dir = fp")?
  test.contains(ticket, "lineage_dir = fp")?
  test.contains(ticket, "factory_dir}/runtime/handbook.md")?
  test.contains(ticket, "guidance_dir}/handbook.md")?
  test.contains(ticket, "lineage_dir}/handbook-candidate.md")?
  test.contains(ticket, r"""session_read_path(session, fp"${guidance_dir}/handbook.md")""")?
  test.contains(assignment, "run-scoped copy")?
  test.contains(assignment, "Handbook candidate")?
  test.contains(assignment, "reusable lesson")?
}

proc test_eval_manager_assignment_proves_exact_handbook_read() [fs, error] {
  let assignment = fs.read_text(fp"${fs.cwd()?}/templates/EVAL-MANAGER-ASSIGNMENT.md")?
  test.contains(assignment, "Use the `read` tool, not `bash`, `cat`, or `grep`")?
  test.contains(assignment, "{{RUN_DIR}}/lineage/handbook-approved.md")?
}

proc test_organization_delivery_is_a_success_gate() [fs, error] {
  let organization = fs.read_text(fp"${fs.cwd()?}/factory/controllers/organization.xsh")?
  let runtime = fs.read_text(fp"${fs.cwd()?}/factory/runtime.xsh")?
  let delivery = organization.split("let delivery =").get(1, "").split("let reeval_exit").get(0, "")
  test.contains(organization, "runtime.merge_validated_ticket")?
  test.contains(organization, "var delivery_ok")?
  test.contains(organization, "var delivery_ok = selected_tickets.len() == 0")?
  test.contains(organization, "delivery_ok = delivery_ok and delivery.merged")?
  test.contains(organization, "runtime.reconcile_tickets(factory_dir, xsh_repo, delivered_xsh_commit.trim())")?
  test.contains(runtime, "export proc merge_validated_ticket")?
  test.contains(runtime, "--ff-only")?
  test.contains(runtime, "--no-ff")?
  test.contains(delivery, "runtime.emit_structured_event")?
  test.ok("runtime.emit_event(" not in delivery, "delivery metadata must not advance ticket lifecycle state")?
}

proc test_ticket_cycle_bounds_concurrent_engineers() [fs, error] {
  let ticket = fs.read_text(fp"${fs.cwd()?}/factory/controllers/ticket.xsh")?
  let director = fs.read_text(fp"${fs.cwd()?}/roles/director.md")?
  let organization = fs.read_text(fp"${fs.cwd()?}/factory/controllers/organization.xsh")?
  test.contains(ticket, "max_concurrent_engineers()")?
  test.contains(ticket, r"""at most ${control.max_concurrent_engineers()} engineer tickets""")?
  test.contains(ticket, "remove_run_worktrees")?
  test.contains(ticket, "if ! director_status.ok")?
  test.contains(ticket, "runtime.cleanup_active_run()")?
  test.contains(ticket, "spawn_engineer")?
  test.contains(ticket, "engineer_handles")?
  test.contains(ticket, "controller-dispatching engineer worker")?
  test.contains(ticket, "controller-dispatching engineer worker")?
  let runtime = fs.read_text(fp"${fs.cwd()?}/factory/runtime.xsh")?
  test.contains(runtime, "ticket_worktree_root")?
  test.contains(runtime, ".xsh-factory-worktrees")?
  test.contains(ticket, "ticket_worktree_path(xsh_repo, run_dir, ticket_id)")?
  test.contains(director, "launch each assigned row exactly once")?
  test.contains(organization, "ticket_worker_pass(primary_phase, ticket_id)")?
  test.contains(organization, "remove_run_worktrees")?
  test.contains(organization, "reeval_ticket_ids = reeval_ticket_ids.push(ticket_id)")?
  test.contains(organization, "linked replay failed; branch retained for review")?
}

proc test_eval_mode_has_no_paid_director_review() [fs, error] {
  let evaluator = fs.read_text(fp"${fs.cwd()?}/factory/controllers/eval.xsh")?
  let auditor = fs.read_text(fp"${fs.cwd()?}/factory/tools/audit.xsh")?
  test.ok("20-director-started" not in evaluator)?
  test.ok("director_handle" not in evaluator)?
  test.contains(auditor, "result: \"not-requested\"")?
  test.contains(auditor, "if mode == \"ticket-implementation\"")?
}

proc test_eval_gate_diagnostics_are_persisted() [fs, error] {
  let evaluator = fs.read_text(fp"${fs.cwd()?}/factory/controllers/eval.xsh")?
  test.contains(evaluator, "required-outputs.json")?
  test.contains(evaluator, "write_preflight_failure_report")?
  test.contains(evaluator, "preflight-failure")?
  test.contains(evaluator, "manager_evidence_read")?
  test.contains(evaluator, "designer_handbook_read")?
  test.contains(evaluator, "_post_required_outputs_audit")?
}

proc test_process_run_status_contract_is_executable(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "process-run-status-contract")?
  let fixture = fp"${root}/fixture.xsh"
  fs.write(
    fixture,
    r"""
proc main() [process, error, io] {
  let result = process.run(process.command_argv("true", ["true"]))?
  if ! result.ok { abort(1) }
  print "direct-status-ok"
}
""",
  )?
  let output = fp"${root}/output.txt"
  let status = process.run(
    process.command_argv(
      process.which("xsh")?,
      ["xsh", fixture.display()],
      stdout: output,
      env: {XSH_MODULE_PATH: fs.cwd()?.display()},
    ),
  )?
  test.ok(status.ok, "process.run fixture must execute")?
  test.contains(output.read_text()?, "direct-status-ok")?
}

proc test_package_evaluators_use_direct_process_status(_: TestContext) [fs, error] {
  # Regression for run-1785958228987: process.run returns ProcessStatus
  # directly. Accessing result.status is valid only for time.measure results
  # and caused the package evaluator to abort before writing run.json.
  for eval_id in ["task-findexec", "task-propsort", "task-render", "task-setdiff", "task-trim"] {
    let source = fs.read_text(fp"${fs.cwd()?}/evals/${eval_id}/evaluator.xsh")?
    test.contains(source, "process.run(")?
    test.ok(".status.ok" not in source, f"${eval_id} must use direct process status")?
    test.ok(".status.exit_code" not in source, f"${eval_id} must use direct process status")?
  }
}

proc test_task_trim_restriction_accepts_typed_path_io() [fs, error] {
  let evaluator = fs.read_text(fp"${fs.cwd()?}/evals/task-trim/evaluator.xsh")?
  test.contains(evaluator, "pure source_uses_file_io(source: Str) -> Bool")?
  test.contains(evaluator, "\".read_bytes()\" in source")?
  test.contains(evaluator, "\".write(\" in source")?
  test.contains(evaluator, "source_uses_file_io(source)")?
  test.ok("let restriction_ok = \"fs.\" in source" not in evaluator)?
}

proc test_task_pathparts_restriction_accepts_documented_typed_path_forms() [fs, error] {
  let evaluator = fs.read_text(fp"${fs.cwd()?}/evals/task-pathparts/evaluator.xsh")?
  test.contains(evaluator, "pure source_references_typed_path(source: Str) -> Bool")?
  test.contains(evaluator, "\"Path(\" in code")?
  test.contains(evaluator, r"""fp"${""")?
  test.contains(evaluator, "source_references_typed_path(source)")?
  test.ok("path_referenced = \"Path(\" in source" not in evaluator)?
}

proc test_eval_staging_context_is_run_scoped() [fs, error] {
  let evaluator = fs.read_text(fp"${fs.cwd()?}/factory/controllers/eval.xsh")?
  test.contains(evaluator, r"""let base_context = fp"${run_dir}/base-context""" )?
  test.contains(evaluator, "base_context.display()")?
  test.contains(evaluator, "if shared_base_image_cache_hit")?
  test.contains(evaluator, "shared_base_image_cache_hit or")?
  test.ok(r"""fp"${factory_dir}/evals/.dist""" not in evaluator)?
}

proc test_task_bigfiles_evaluator_is_package_owned() [fs, error] {
  let evaluator = fs.read_text(fp"${fs.cwd()?}/evals/task-bigfiles/evaluator.xsh")?
  test.ok(control.eval_evaluator_package_owned(evaluator))?
  test.contains(evaluator, "run.json")?
  test.contains(evaluator, "task-bigfiles")?
  test.contains(evaluator, "sort -k1,1rn")?
}

proc test_eval_dispatch_is_package_owned() [fs, error] {
  let evaluate = fs.read_text(fp"${fs.cwd()?}/evals/task-bigfiles/evaluate.xsh")?
  let executor = fs.read_text(fp"${fs.cwd()?}/factory/entrypoints/eval-executor.xsh")?
  test.contains(evaluate, "/run/evaluator.xsh")?
  test.ok("factory/tools" not in evaluate)?
  test.contains(executor, "evaluator.xsh")?
  test.contains(executor, "dst=/run/factory,readonly")?
  test.contains(executor, "XSH_MODULE_PATH=/run")?
  test.contains(executor, "use factory.control as control")?
  let ticket_controller = fs.read_text(fp"${fs.cwd()?}/factory/controllers/ticket.xsh")?
  test.contains(ticket_controller, "CTO owns factory changes")?
  test.contains(ticket_controller, "ticket_change_target")?
  test.contains(executor, "identity", "eval_id")?
  test.contains(executor, "identity", "run_id")?
  for eval_id in ["task-ecount", "task-envcfg"] {
    test.ok(fs.exists(fp"${fs.cwd()?}/evals/${eval_id}/evaluator.xsh")?)?
  }
}

proc test_task_grep_evaluator_uses_shared_export_mount() [fs, error] {
  let evaluator = fs.read_text(fp"${fs.cwd()?}/evals/task-grep/evaluator.xsh")?
  test.contains(evaluator, "FACTORY_EXPORT")?
  test.contains(evaluator, "copy_results(work_root, export_root)")?
  test.ok(r"""${session_root}/export""" not in evaluator)?
}

proc test_eval_design_rejects_legacy_evaluator_source() [fs, error] {
  let controller = fs.read_text(fp"${fs.cwd()?}/factory/controllers/design.xsh")?
  test.contains(controller, "eval_evaluator_package_owned")?
  test.contains(controller, "evaluator_source_ok")?
}

proc test_eval_design_stages_and_promotes_complete_package() [fs, error] {
  let controller = fs.read_text(fp"${fs.cwd()?}/factory/controllers/design.xsh")?
  let assignment = fs.read_text(fp"${fs.cwd()?}/templates/EVAL-DESIGNER-ASSIGNMENT.md")?
  let role = fs.read_text(fp"${fs.cwd()?}/roles/eval-designer.md")?
  let review = fs.read_text(fp"${fs.cwd()?}/templates/CTO-EVAL-REVIEW.md")?
  test.contains(controller, "\"evaluator.xsh\"")?
  test.contains(controller, "promote_eval_proposal")?
  test.contains(controller, "84-cto-reviewed")?
  test.contains(controller, "evaluator_check_ok")?
  test.contains(assignment, "new valid `task-*` ID")?
  test.contains(assignment, "approved eval's `EVAL.md`")?
  test.contains(assignment, "State machine")?
  test.contains(assignment, "Write the report")?
  test.contains(assignment, "Do not build a localized evaluator")?
  test.contains(role, "Replace the scaffold's source eval title and ID first")?
  test.contains(role, "Use an approved eval package")?
  test.contains(role, "State machine")?
  test.contains(role, "When the evaluator is valid, stop discovery")?
  test.contains(role, "Do not build a localized evaluator")?
  test.contains(review, "may set `Approved.`")?
  test.contains(review, "may set `Approved.`")?
  test.contains(review, "MISSING_PACKAGE_FILES")?
  test.contains(review, "Checked-in status")?
}

proc test_process_output_is_written_to_event_ledger(ctx: TestContext) [fs, error] {
  let root = test.temp_dir(ctx, name: "process-events")?
  let output = fp"${root}/child.stdout"
  fs.write(
    output,
    """hello
""",
  )?
  runtime.emit_process_output(root, "child-1", "stdout", output, 0)?
  let events = fs.read_text(fp"${root}/events.jsonl")?
  test.contains(events, "process-output")?
  test.contains(events, "child-1:stdout")?
  test.contains(events, "hello\\n")?
}

proc test_cto_handoff_is_staged_for_every_run(ctx: TestContext) [fs, error] {
  let root = test.temp_dir(ctx, name: "cto-handoff")?
  let factory = fs.cwd()?
  runtime.stage_cto_improvement(factory, root)?
  let handoff = fp"${root}/CTO-IMPROVEMENT.md"
  test.ok(fs.exists(handoff)?)?
  test.contains(fs.read_text(handoff)?, "pending-validation")?
  test.contains(fs.read_text(handoff)?, "## Revert condition")?
  test.contains(fs.read_text(handoff)?, "## Revert condition")?
  runtime.stage_cto_productivity_report(factory, root)?
  let productivity = fp"${root}/CTO-PRODUCTIVITY-REPORT.md"
  test.ok(fs.exists(productivity)?)?
  test.contains(fs.read_text(productivity)?, "## Engineer-commit gate")?
}

proc test_eval_executor_is_documented_as_controller_not_role() [fs, error] {
  let contract = fs.read_text(fp"${fs.cwd()?}/FACTORY.md")?
  let guide = fs.read_text(fp"${fs.cwd()?}/AGENTS.md")?
  test.contains(contract, "controller program, not a Pi role")?
  test.contains(contract, "it is not an")?
  test.contains(guide, "controller-owned infrastructure, not a role or employee")?
}

proc test_controllers_have_no_legacy_projection_outputs() [fs, error] {
  for file in [
    "run.xsh",
    "factory/controllers/eval.xsh",
    "factory/controllers/ticket.xsh",
    "factory/controllers/design.xsh",
    "factory/controllers/organization.xsh",
    "factory/tools/audit.xsh",
    "factory/tools/session.xsh",
  ] {
    let source = fs.read_text(fp"${fs.cwd()?}/${file}")?
    test.ok("COST.md" not in source, f"${file} must use report.json")?
    test.ok("AUDIT.md" not in source, f"${file} must use report.json")?
    test.ok("TOOL-ERRORS.md" not in source, f"${file} must use structured tool_errors")?
    test.ok("CURRENT-EVIDENCE.md" not in source, f"${file} must not emit evidence projection")?
  }
}

proc test_canonical_surface_has_no_compatibility_layer() [fs, error] {
  let root = fs.cwd()?
  let launcher = fs.read_text(fp"${root}/run.xsh")?
  test.ok("compat" not in launcher, "the only top-level launcher must be canonical")?
  test.contains(launcher, "use factory.control as control")?
  for file in [
    "factory/controllers/organization.xsh",
    "factory/controllers/ticket.xsh",
    "factory/controllers/eval.xsh",
    "factory/controllers/design.xsh",
    "factory/controllers/reuse.xsh",
    "factory/entrypoints/run-agent.xsh",
    "factory/entrypoints/eval-executor.xsh",
    "factory/tools/audit.xsh",
    "factory/tools/report.xsh",
    "factory/tools/session.xsh",
  ] {
    let source = fs.read_text(fp"${root}/${file}")?
    test.ok("compat" not in source, f"${file} must not use compatibility code")?
  }
}

proc test_clean_factory_supports_age_pruning() [fs, error] {
  let clean = fs.read_text(fp"${fs.cwd()?}/factory/tools/clean-factory.xsh")?
  test.contains(clean, "cutoff_ms")?
  test.contains(clean, r"removed ${removed} run(s) older than")?
  test.contains(clean, "age_days < 1")?
  test.contains(fs.read_text(fp"${fs.cwd()?}/Makefile")?, "clean-factory.xsh 3")?
}

proc test_compressed_session_support_round_trips(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "compressed-session")?
  let session = fp"${root}/session.jsonl"
  let events = fp"${session.display()}.events.jsonl"
  fs.write(
    session,
    """{"type":"message"}
""",
  )?
  fs.write(
    events,
    """{"type":"message_update"}
""",
  )?
  runtime.compress_run_sessions(root)?
  test.ok(! fs.exists(events)?, "streaming provider events must not be retained")?
  test.ok(! fs.exists(session)?, "raw session must be compressed")?
  test.contains(runtime.session_text(session)?, "message")?
}

proc test_compressed_session_rewrite_is_idempotent(ctx: TestContext) [fs, process, error] {
  let root = test.temp_dir(ctx, name: "compressed-session-rewrite")?
  let session = fp"${root}/session.jsonl"
  let report = fp"${root}/report.json"
  fs.write(
    session,
    """{"type":"message"}
""",
  )?
  fs.write(
    report,
    f"""{{
  "raw": "${session.display()}",
  "archive": "${session.display()}.bz2",
  "events": "${session.display()}.events.jsonl",
  "event_archive": "${session.display()}.events.jsonl.bz2",
  "container": "/session/session.jsonl",
  "container_events": "/session/session.jsonl.events.jsonl",
  "container_archive": "/session/session.jsonl.bz2"
}}
""",
  )?
  runtime.compress_run_sessions(root)?
  let first = report.read_text()?
  runtime.compress_run_sessions(root)?
  let second = report.read_text()?
  test.eq(first, second)?
  test.ok(".bz2.bz2" not in second, "archive references must not gain a second suffix")?
  test.contains(second, "session.jsonl.bz2")?
  test.contains(second, "/session/session.jsonl")?
  test.contains(second, "/session/session.jsonl.events.jsonl.bz2")?
}

proc test_compressed_session_support_is_documented() [fs, error] {
  let runtime = fs.read_text(fp"${fs.cwd()?}/factory/runtime.xsh")?
  let report = fs.read_text(fp"${fs.cwd()?}/factory/tools/session.xsh")?
  let budget = fs.read_text(fp"${fs.cwd()?}/factory/tools/budget-watch.xsh")?
  let cleanup = fs.read_text(fp"${fs.cwd()?}/factory/tools/cleanup-run.xsh")?
  test.contains(runtime, "session.jsonl.bz2")?
  test.contains(runtime, "compress_run_sessions")?
  test.contains(report, "runtime.session_text")?
  test.contains(budget, "runtime.session_text")?
  test.contains(cleanup, ".events.jsonl")?
  test.contains(fs.read_text(fp"${fs.cwd()?}/runs/.gitignore")?, "session.jsonl.events.jsonl.bz2")?
}

proc test_pi_session_persistence_is_jsonl_only() [fs, error] {
  let controller = fs.read_text(fp"${fs.cwd()?}/factory/entrypoints/run-agent.xsh")?
  let eval_worker = fs.read_text(fp"${fs.cwd()?}/evals/eval-worker.xsh")?
  test.contains(controller, "--session")?
  test.contains(controller, "--mode", "json")?
  test.contains(controller, ".events.jsonl")?
  test.contains(controller, "fs.remove(provider_events")?
  test.contains(eval_worker, "--session")?
  test.contains(eval_worker, "--mode", "json")?
  test.contains(eval_worker, ".events.jsonl")?
  let executor = fs.read_text(fp"${fs.cwd()?}/factory/entrypoints/eval-executor.xsh")?
  test.contains(executor, "fs.remove")?
  test.ok("--export" not in controller, "run-agent must not create session.html")?
  test.ok("--export" not in eval_worker, "eval worker must not create session.html")?
}

proc test_run_agent_clears_pi_harness_env() [fs, error] {
  # The factory may be launched from inside a standalone-embedded Pi session
  # whose PI_PACKAGE_DIR/PI_STANDALONE_BINARY leak (XSH merges spawn `env`)
  # into every host-side agent launch. The host runner must clear them so host
  # `pi` resolves its own installed package instead of a partial embedded one
  # lacking dist/modes/interactive/theme/dark.json, which crashed agent startup.
  let controller = fs.read_text(fp"${fs.cwd()?}/factory/entrypoints/run-agent.xsh")?
  test.contains(controller, "PI_PACKAGE_DIR: \"\"")?
  test.contains(controller, "PI_STANDALONE_BINARY: \"\"")?
  let worker = fs.read_text(fp"${fs.cwd()?}/evals/eval-worker.xsh")?
  test.ok("PI_STANDALONE_BINARY" not in worker, "Docker worker stays harness-free")?
}

proc test_eval_worker_prompt_matches_task_image() [fs, error] {
  let prompt = fs.read_text(fp"${fs.cwd()?}/roles/eval-worker.md")?
  test.contains(prompt, "The task image is Alpine-based and provides BusyBox `sh`, not `bash`; use `sh`")?
  test.contains(prompt, "avoid bash-only syntax")?
  test.contains(prompt, "`and` and `or`, not shell `&&` and `||`")?
  test.contains(prompt, "xsht lint --fix")?
  test.contains(prompt, "specifically evaluating lint")?
}

proc test_host_agent_dispatch_requires_controller_manifest(ctx: TestContext) [fs, error] {
  let root = test.temp_dir(ctx, name: "host-agent-dispatch")?
  let message = fp"${root}/message.md"
  fs.write(
    message,
    """controller assignment
""",
  )?
  runtime.write_dispatch_record(
    root,
    "eval-manager",
    "task-a",
    message,
    root,
    "eval",
    "task-a",
    "",
    "",
  )?
  let dispatch = json.read(fp"${root}/dispatch/eval-manager-task-a.json")?
  test.eq(schema.value_text(json.get(dispatch, ["role"], "")), "eval-manager")?
  test.eq(schema.value_text(json.get(dispatch, ["worker_id"], "")), "task-a")?
  test.eq(schema.value_text(json.get(dispatch, ["message_file"], "")), message.display())?
  test.eq(schema.value_text(json.get(dispatch, ["mode"], "")), "eval")?
  test.eq(schema.value_text(json.get(dispatch, ["eval_id"], "")), "task-a")?
  let runner = fs.read_text(fp"${fs.cwd()?}/factory/entrypoints/run-agent.xsh")?
  test.contains(runner, "missing controller dispatch record")?
  test.contains(runner, "agent invocation does not match controller dispatch record")?
}

proc test_runtime_registration_and_bound_dispatch_are_durable(ctx: TestContext) [fs, process, env, error] {
  let root = test.temp_dir(ctx, name: "runtime-registration")?
  let factory = fp"${root}/factory"
  let run_dir = fp"${root}/runs/run-1/01-ticket"
  let system_prompt = fp"${factory}/roles/engineer.md"
  let message_file = fp"${run_dir}/messages/task-a.md"
  let workdir = fp"${root}/product/worktree"
  fs.mkdir(fp"${factory}/roles")?
  fs.mkdir(fp"${run_dir}/messages")?
  fs.mkdir(workdir)?
  fs.write(
    system_prompt,
    """engineer prompt
""",
  )?
  fs.write(
    message_file,
    """assignment
""",
  )?
  runtime.register_cycle_controller(run_dir)?
  runtime.register_process(run_dir, "engineer", 42)?
  test.ok(fs.exists(fp"${run_dir}/processes/controller.pids")?)?
  test.eq(fs.read_text(fp"${run_dir}/processes/engineer.pids")?.trim(), "42")?
  runtime.write_dispatch_record(
    run_dir,
    "eval-manager",
    "manager",
    message_file,
    workdir,
    "eval",
    "task-ecount",
    "",
    "",
  )?
  let legacy = json.read(fp"${run_dir}/dispatch/eval-manager-manager.json")?
  test.eq(json.get(legacy, ["worker_id"], ""), "manager")?
  runtime.write_bound_dispatch_record(
    factory,
    run_dir,
    "engineer",
    "task-a",
    system_prompt,
    message_file,
    workdir,
    "ticket-implementation",
    "task-ecount",
    "task-a",
    "assignment-hash",
  )?
  let bound = json.read(fp"${run_dir}/dispatch/engineer-task-a.json")?
  test.eq(json.get(bound, ["schema_version"], 0), 2)?
  test.eq(json.get(bound, ["claim_token"], ""), "assignment-hash")?
  match runtime.write_bound_dispatch_record(
    factory,
    run_dir,
    "engineer",
    "task-a",
    system_prompt,
    message_file,
    workdir,
    "ticket-implementation",
    "task-ecount",
    "task-a",
    "assignment-hash",
  ) {
    Ok(_) => test.fail("bound dispatch record was overwritten")?
    Err(_) => {}
  }

  match runtime.write_bound_dispatch_record(
    factory,
    run_dir,
    "engineer",
    "task-b",
    fp"${factory}/missing.md",
    message_file,
    workdir,
    "ticket-implementation",
    "task-ecount",
    "task-b",
    "",
  ) {
    Ok(_) => test.fail("dispatch with missing prompt was accepted")?
    Err(_) => {}
  }

  runtime.stop_cycle_budget_watch(run_dir)?
  test.contains(fs.read_text(fp"${run_dir}/AGGREGATE-BUDGET-STOP")?, "normal controller shutdown")?
}

proc test_ticket_worktree_is_outside_factory_checkout() [error] {
  let factory = paths.make_factory_root(/srv/factory)?
  let product = paths.make_product_root(/srv/xsh, factory)?
  let worktree = runtime.ticket_worktree_path(
    product.root_path,
    /srv/factory/runs/run-42/phases/01-ticket,
    "task-a",
  )
  test.ok(
    ! paths.within(factory.root_path, worktree)?,
    "engineer worktree must not be inside the factory checkout",
  )?
  test.ok(
    worktree.display().starts_with("/srv/.xsh-factory-worktrees/run-42/"),
    "engineer worktree must use the adjacent product-parent scratch root",
  )?
}

proc test_run_status_inspects_live_and_completed_evidence(ctx: TestContext) [fs, process, env, error] {
  let root = test.temp_dir(ctx, name: "run-status")?
  let factory = fs.cwd()?
  let run_dir = fp"${root}/run-1"
  let phase_dir = fp"${run_dir}/phases/01-ticket"
  let worker_dir = fp"${phase_dir}/workers/engineer/task-a"
  fs.mkdir(worker_dir)?
  fs.mkdir(fp"${run_dir}/processes")?
  json.write(
    fp"${run_dir}/report.json",
    {
      schema_version: 1,
      kind: "run",
      state: "completed",
      result: "pass",
      data: {cost: {cost_usd: 0.12}},
    },
    pretty: true,
  )?
  json.write(
    fp"${phase_dir}/report.json",
    {schema_version: 1, kind: "phase", state: "completed", result: "pass"},
    pretty: true,
  )?
  json.write(
    fp"${worker_dir}/report.json",
    {
      schema_version: 1,
      kind: "worker",
      state: "completed",
      result: "pass",
      usage: {assistant_turns: 7, cost_usd: 0.04, tool_errors: 1},
    },
    pretty: true,
  )?
  fs.write(
    fp"${run_dir}/events.jsonl",
    """{"event_id":"05-adaptive-queue-selected","state":"started","subject":"organization-queue","detail":"open=4; approved=1; engineers=1; discovery_evals=1"}
{"event_id":"95-cycle-validated","state":"validated","subject":"organization","detail":"all required phases passed"}
""",
  )?
  let controller_pid = process.current_pid()?
  let child = spawn process.command_argv("sh", ["sh", "-c", "sleep 10"])?
  fs.write(fp"${run_dir}/processes/controller.pids", f"${controller_pid}\n")?
  fs.write(fp"${run_dir}/processes/phase-worker.pids", f"${controller_pid}\n${child.pid}\n")?
  let output = fp"${root}/status.txt"
  let error_output = fp"${root}/status.err"
  let xsh = process.which("xsh")?
  let status = process.run(
    process.command_argv(
      xsh,
      [
        xsh.display(),
        fp"${factory}/factory/tools/run-status.xsh",
        "--",
        "--run-dir",
        run_dir.display(),
      ],
      cwd: factory,
      env: {FACTORY_DIR: factory.display(), XSH_MODULE_PATH: factory.display()},
      stdout: output,
      stderr: error_output,
    ),
  )?
  test.ok(status.ok, fs.read_text(error_output)?)?
  let report = fs.read_text(output)?
  test.contains(report, "RUN run-1 STATE completed RESULT pass")?
  test.contains(report, "QUEUE open=4; approved=1; engineers=1; discovery_evals=1")?
  test.contains(report, "LAST 95-cycle-validated validated organization")?
  test.contains(report, "ACTIVE 3")?
  test.contains(report, f"processes/controller pid=${controller_pid}")?
  test.contains(report, f"processes/phase-worker pid=${controller_pid}")?
  test.contains(report, f"processes/phase-worker pid=${child.pid}")?
  test.contains(report, "01-ticket completed pass")?
  test.contains(report, "engineer/task-a pass turns=7 cost=0.040000 errors=1")?

  let missing = process.run(
    process.command_argv(
      xsh,
      [
        xsh.display(),
        fp"${factory}/factory/tools/run-status.xsh",
        "--",
        "--run-dir",
        fp"${root}/missing".display(),
      ],
      cwd: factory,
      env: {FACTORY_DIR: factory.display(), XSH_MODULE_PATH: factory.display()},
    ),
  )?
  test.ok(! missing.ok, "run-status must fail closed for a missing run")?
  process.kill(child.pid, signal: "TERM")?
  let _ = wait child?
}

proc test_ticket_snapshot_rejects_existing_ticket_mutation(ctx: TestContext) [fs, error] {
  let root = test.temp_dir(ctx, name: "ticket-snapshot")?
  let tickets = fp"${root}/tickets"
  fs.mkdir(tickets)?
  fs.write(fp"${tickets}/task-a.md", "## Status\nMerged.\n")?
  let snapshot = runtime.ticket_snapshot(root)?
  fs.write(fp"${tickets}/task-a.md", "## Status\nOpen.\n")?
  test.ok(! runtime.ticket_snapshot_unchanged(root, snapshot)?, "existing ticket mutation must fail closed")?
  fs.write(fp"${tickets}/task-b.md", "## Status\nOpen.\n")?
  let refreshed = runtime.ticket_snapshot(root)?
  test.ok(runtime.ticket_snapshot_unchanged(root, refreshed)?, "new ticket identities are allowed")?
}
