# CTO factory improvement

## Status

pending-validation

`pending-validation` means the CTO has already implemented this change. It is
not awaiting another approval; the next cycle verifies the named metric or
applies the safe inverse.

## Change

Cycle 29 found the next retained-row edge case. Even with a passing retained
replay, an old branch can conflict when merged after the fresh commit. The
organization controller now classifies any non-merged retained row as
`86-ticket-<id>-retained-replay-deferred`, explains whether the defer was a
bounded replay failure or a stale-base merge conflict, preserves the branch,
and leaves fresh delivery failures hard. Implemented in
`../../factory/controllers/organization.xsh`; audit behavior remains covered by
`../../factory/tools/audit.xsh` and `../../tests/tools_test.xsh`.

## Throughput requirement

The cycle produced and delivered one fresh engineer implementation commit,
`e6d3fd96f9fa654c0d1c9f434f83b6984a60c204`. The throughput requirement was
met; the root failure was retained merge classification, not a missing engineer
commit.

## Provider-health attribution

Provider telemetry was captured. Retry counts were zero and provider-error
attribution remained `unknown`; the failure is a deterministic stale-base Git
conflict, not a provider-health attribution.

## Baseline metric

Cycle 28 delivered one fresh commit at `$0.198814` and 189 turns; see
`../run-1786216593690/report.json`. Cycle 29 delivered one at `$0.171905` and
189 turns; see `report.json` and `data.throughput`.

## Target metric

The next cycle must keep one fresh engineer delivery and turn the retained
stale-base merge into an explicit deferred event without root infrastructure
failure.

## Validation

Run a new organization request through `run.xsh`; verify
`data.throughput.fresh_engineer_rows >= 1`, the fresh delivered event precedes
the retained event, and the retained event ends in
`-retained-replay-deferred` when its branch cannot merge cleanly. Verify the
root `report.json` and final `90-cycle-*` event both preserve pass outcomes for
fresh product/evaluator/infrastructure when only retained work is deferred.

## Revert condition

Revert if a fresh merge conflict is classified as deferred, a retained defer
merges or deletes its branch, or an invalid/missing retained phase is hidden.
The safe inverse is the prior hard `delivery-failed` path.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted`
after running the named verification, and link the evidence before admitting
paid work.
