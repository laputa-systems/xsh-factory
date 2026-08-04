# CTO factory improvement

## Status

validated

The named verification passed; the retained guard is not awaiting further
approval.

## Change

Added a branch-existence guard to `factory_runtime.xsh` in
`commit_is_patch_applied`. Reconciliation now returns `false` for a historical
branch name that has been retired instead of invoking `git cherry` on a missing
revision. Added native coverage in `tests/tools_test.xsh` for reconciliation
when no implementation branch exists.

The cycle also merged the fresh `task-envcfg-001` implementation and promoted
the complete `evals/task-pathparts/` package with status `Approved.`. The
handbook candidate from the linked replay was **not** promoted because the
manager's exact handbook-read gate was not evidenced by the session archive.

## Throughput requirement

The cycle produced one new reviewable engineer implementation commit,
`754fcba8d1d15fb3d8c0a03f11fbf2708b463a03`, and the linked evaluator passed all
ten cases. The organization cycle nevertheless failed its infrastructure
contract because the linked replay phase reported `manager_handbook_read: false`.

## Provider-health attribution

Provider telemetry was captured for all seven workers. Retry count was zero and
no provider errors were reported; latency is therefore attributed to agent
work, not provider health.

## Baseline metric

Prior organization cycle `runs/run-1785873121313` produced zero new engineer
commits at $0.094041 and failed its linked replay. This cycle produced one new
engineer commit at $0.211927, but the organization result remained `fail`.
Evidence: `runs/run-1785876949561/report.json` and
`CTO-PRODUCTIVITY-REPORT.md`.

## Target metric

Next organization cycle target: at least one current-HEAD engineer commit, a
passing linked replay phase including `required_outputs.required: true`, and
aggregate cost at or below $0.211927 unless a second reviewable product result
is produced.

## Validation

Run `XSH_MODULE_PATH=. xsht test`, then inspect the next
`CTO-PRODUCTIVITY-REPORT.md`, root `report.json`, and each linked replay's
`required-outputs.json`. Require the reconciliation regression test to pass,
`manager_handbook_read: true`, and `required: true`.

## Revert condition

If reconciliation again fails on a retired branch, revert the guard only after
capturing a reproducer. If the next replay still fails the exact manager read
gate, fix session evidence matching or the manager assignment before admitting
paid work; do not promote the handbook candidate on narrative evidence alone.

## Validation evidence

`XSH_MODULE_PATH=. xsht test` passed all 55 native tests, including
`test_reconciliation_ignores_retired_branch_reference`. The current
`XSH_MODULE_PATH=. xsh run-cto.xsh` inventory completed without a retired-branch
reconciliation error. The guard remains; no revert is warranted.
