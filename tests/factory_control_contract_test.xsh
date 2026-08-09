##! Behavior-level coverage for controller parsing and report gates.
use factory.control as control

proc test_control_contracts_reject_ambiguous_reports_and_fill_templates() [error] {
  test.ok(control.source_has_forbidden_subprocess("run echo hi"))?
  test.ok(! control.source_has_forbidden_subprocess("# run echo hi"))?
  test.eq(control.role_prefix("engineer"), "ENGINEER")?
  test.eq(control.default_provider("engineer"), "openrouter")?
  test.eq(control.default_model("engineer"), "openai/gpt-5.6-luna")?
  test.eq(control.default_tools("eval-worker"), "read,write,edit,bash")?
  test.eq(control.clamp_session_limit("engineer", "MAX_TURNS", "999")?, "220")?
  test.eq(control.clamp_session_limit("engineer", "MAX_TURNS", "10")?, "10")?
  test.eq(control.clamp_budget("engineer", "2.00")?, "0.35")?
  test.eq(control.clamp_cycle_budget("2.00")?, "1.00")?
  test.ok(
    "--no-cache" in control.eval_overlay_build_args(
      "base",
      "build",
      "image",
      "linux/amd64",
      /factory/Dockerfile,
      /factory,
      true,
    ),
  )?
  test.ok(control.toolchain_cache_valid(false, true, "key", "key", true))?
  test.ok(control.shared_image_cache_valid(false, true))?
  test.ok(
    control.factory_image_tag(
      "xsh",
      "control",
      "runtime",
      "schema",
      "worker",
      "base",
      "toolchain",
      "make",
      "linux",
      "amd64",
    ) != "",
  )?
  test.ok(control.ecount_oracle_ok(true, "output"))?
  test.eq(control.ecount_classification(false, true, true, true, true, true), "worker_missing_artifact")?
  test.eq(control.ecount_classification(true, true, true, true, true, true), "pass")?
  test.ok(control.valid_eval_id("task-a"))?
  test.ok(! control.valid_eval_id("../escape"))?
  test.eq(
    control.eval_id_from_contract("""# Eval task-a
"""),
    "task-a",
  )?
  test.ok(control.valid_ticket_id("task-a"))?
  test.ok(
    control.ticket_is_accepted("""## Status

Approved.

## Change target

- `product`
"""),
  )?
  test.ok(
    control.eval_is_disabled("""## Status

Disabled.
"""),
  )?
  test.ok(
    control.ticket_is_closed("""## Status

Closed.
"""),
  )?
  test.ok(control.retry_allowed("worker-failed", 1, 2))?
  test.ok(! control.retry_allowed("permanent", 1, 2))?
  test.ok(control.transition_allowed("validated", "ready-for-review"))?
  test.ok(! control.transition_allowed("accepted", "started"))?

  let report = """## Result

ready-for-review

## Branch

factory/task-a

## Commit

abc

## Files changed

one

## Tests

xsht test

## North-star impact

durable

## Remaining risks

none
"""
  test.eq(control.report_section(report, "Branch"), "factory/task-a")?
  test.ok(control.report_contract_ok(report, ["Branch", "Tests"], "ready-for-review"))?
  test.ok(control.engineer_report_contract_ok(report))?
  test.ok(
    control.narrative_report_contract_ok(
  """## Result

A result
""",
  [],
),
  )?
  test.ok(
    ! control.report_contract_ok(
  """## Result

pass
{{missing}}""",
  [],
  "pass",
),
  )?
  test.eq(control.fill_template("Hello {{NAME}}", [{key: "NAME", value: "factory"}]), "Hello factory")?
  test.ok(
    control.engineer_assignment_ok(
  "/run-1",
  "task-a",
  "/run-1/messages/task-a.md",
  "/work/task-a",
  """- Ticket ID: `task-a`
- Dedicated XSH worktree: `/work/task-a`
<!-- CONTROLLER_TICKET_SNAPSHOT_BEGIN -->
ticket
<!-- CONTROLLER_TICKET_SNAPSHOT_END -->
Do not search for open tickets""",
),
  )?
}
