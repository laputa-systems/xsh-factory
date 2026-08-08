# CTO factory improvement

## Status

validated

Validated before cycle-23 admission: `factory/control.xsh` and
`factory/tools/run-status.xsh` check successfully; all 30
`tests/factory_control_test.xsh` tests pass; and
`tests/tools_test.xsh::test_run_status_inspects_live_and_completed_evidence`
passes exactly. The acceptance wording and zombie-process regressions are
therefore active for the next cycle.

## Change

Two deterministic throughput repairs were implemented before cycle close:

- `factory/control.xsh::reeval_manager_acceptance_gate` now accepts the
  manager wording “candidate acceptance surface exercised,” while retaining
  explicit rejection markers. The regression is covered in
  `tests/factory_control_test.xsh`.
- `factory/tools/run-status.xsh` now filters `status == "zombie"` and exposes
  process status, runtime age, and command in live rows. The regression is
  covered in `tests/tools_test.xsh`.

The unresolved handbook candidate from the engineer is explicitly deferred in
`runtime/handbook-ledger.md` until cross-eval evidence exists.

## Throughput requirement

Failure. One reviewable engineer commit was produced, but zero fresh engineer
commits were delivered. One retained product commit was delivered. The next
cycle must deliver the preserved engineer commit.

## Provider-health attribution

Telemetry was captured for all eight workers. There were no provider retries,
provider failures, or budget failures; this was a deterministic factory gate
failure, not provider health.

## Baseline metric

Cycle 22: `fresh_engineer_rows=1`, `delivered_tickets=1` (retained only), and
fresh engineer deliveries `0`, in `report.json` and
`CTO-PRODUCTIVITY-REPORT.md`.

## Target metric

Cycle 23: at least one delivered engineer implementation commit and
`required_outputs.required == true` for its linked replay.

## Validation

Run the focused native checks before admission:

    XSH_MODULE_PATH=. xsht test tests/factory_control_test.xsh
    XSH_MODULE_PATH=. xsht test 'tests/tools_test.xsh::test_run_status_inspects_live_and_completed_evidence' --exact

Then verify cycle 23 `report.json` records the reused branch’s delivery and a
passing linked phase.

## Revert condition

If the acceptance wording test fails, or a passing manager report using the
documented wording is still marked `required_outputs.manager_report=false`,
revert only the acceptance-gate relaxation and repair the report contract with
a narrower evidence-backed predicate. If run-status reports a known zombie as
active, revert the introspection change and preserve the failing test.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted`
after the focused checks and cycle-23 evidence are recorded.
