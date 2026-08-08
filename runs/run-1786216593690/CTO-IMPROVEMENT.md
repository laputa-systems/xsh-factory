# CTO factory improvement

## Status

pending-validation

`pending-validation` means the CTO has already implemented this change. It is
not awaiting another approval; the next cycle verifies the named metric or
applies the safe inverse.

## Change

Cycle 28 exposed a closeout classification bug. The organization controller
now emits `86-ticket-<id>-retained-replay-deferred` for a bounded failure on an
already-retained branch, keeps that branch unmerged, and removes only its clean
detached replay worktree. The audit accepts that explicit deferred phase as a
nonblocking retained outcome while preserving the failed phase and required
output evidence. Fresh replay failures still emit `delivery-failed` and fail
product delivery. Implemented in
`../../factory/controllers/organization.xsh` and
`../../factory/tools/audit.xsh`, with regression coverage in
`../../tests/tools_test.xsh`.

## Throughput requirement

The cycle produced one reviewable fresh engineer implementation commit,
`df60bdbf1a722daca096175c9473a79f99f78999`, and delivered it before the
retained replay timeout. The throughput requirement was met even though the
root cycle result was failed by the old classification.

## Provider-health attribution

Provider telemetry was captured in worker reports; retry counts were zero and
provider error attribution was `unknown`. The retained manager timeout is
therefore treated as a bounded closeout bottleneck, not attributed to provider
health.

## Baseline metric

Cycle 27 delivered two commits at `$0.103835` and 142 turns; see
`../run-1786215025081/report.json`. Cycle 28 delivered one fresh commit at
`$0.198814` and 189 turns; see `report.json`.

## Target metric

The next cycle must deliver at least one fresh engineer commit. A retained
timeout must produce the explicit deferred event, preserve the branch, and not
fail the root cycle when fresh delivery, evaluator, and cleanup gates pass.

## Validation

Run the next organization request through `run.xsh`; verify
`data.throughput.fresh_engineer_rows >= 1`, a fresh `86-ticket-*-delivered`
event precedes any retained defer, and the root report does not fail solely on
an explicit retained-deferred phase. Native verification passed with focused
`XSH_MODULE_PATH=. xsht test` coverage and `xsht check` on all changed files.

## Revert condition

Revert the controller/audit change if a fresh replay can be marked deferred,
if a retained deferred phase merges a branch, or if a retained deferred event
can hide a missing/invalid phase report. The safe inverse is to restore the
prior hard delivery and phase gates while retaining the regression fixture.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted`
after running the named verification, and link the evidence before admitting
paid work.
