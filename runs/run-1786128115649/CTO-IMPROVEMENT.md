# CTO factory improvement

## Status

pending-validation

`pending-validation` means the CTO has already implemented this change. It is
not awaiting another approval; the next cycle verifies the named metric or
applies the safe inverse.

## Change

The organization controller now starts the independent eval process before it
waits for the primary ticket phase in
`factory/controllers/organization.xsh`. The ordering invariant is protected by
`tests/tools_test.xsh::test_organization_starts_independent_eval_before_primary_wait`.
The paid run exposed the prior sequencing defect: the independent eval process
was absent until the primary engineer phase had completed. The event names
alone are not timing evidence because the old controller emitted the start
event only after that wait.

## Throughput requirement

The cycle produced one reviewable engineer implementation commit,
`857154dfe505f0d01053c1b5311f44422070eb34`, plus one new Open product ticket,
`task-dupcheck-002`. This is a throughput improvement over the prior eval-only
cycle.

## Provider-health attribution

Provider telemetry was present for all six workers; retries and provider
errors were zero. Recorded model cost was `$0.187125536` across 210 assistant
turns. The structured run retained 12 worker tool errors for review; no budget
failure or provider-health failure occurred.

## Baseline metric

The prior cycle produced zero engineer commits at `$0.054822762`; evidence:
`runs/run-1786126514242/`.

## Target metric

The next organization cycle must show the independent-eval start event before
primary completion, while preserving one validated engineer/replay path and
the new-ticket review gate. Target at least one additional reviewable product
delivery or an explicit merge/reuse decision for the retained histogram branch.

## Validation

Run `xsht test` and inspect the next run's process/event evidence: the
independent eval process must be launched before the primary process returns,
not merely before the later completion event is written. Then validate the
phase reports, engineer provenance, and independent evaluator manifest.

## Revert condition

If the next run still starts the independent eval after primary completion,
or loses a phase/report/commit provenance artifact, revert the controller
sequencing patch and restore the prior tested path while retaining the run
evidence.

## Next-cycle disposition

The next CTO must mark this handoff `validated` only after the event-order
invariant is observed in a real organization run; otherwise mark it `reverted`
and repair the controller before further paid work.

## Post-close CTO merge

The validated implementation was subsequently fast-forwarded into `../xsh`
`master` at `857154dfe505f0d01053c1b5311f44422070eb34`. Running
`factory/tools/reconcile.xsh` recorded the merge and updated
`tickets/task-histogram-003.md` to `Merged.`.
