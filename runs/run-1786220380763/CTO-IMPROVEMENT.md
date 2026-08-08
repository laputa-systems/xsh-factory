# CTO factory improvement

## Status

pending-validation

`pending-validation` means the CTO has already implemented this change. It is
not awaiting another approval; the next cycle verifies the named metric or
applies the safe inverse.

## Change

Cycle 30 exposed a non-discriminating linked replay. Ticket
`task-histogram-010` changed `parse_uint_positive` whitespace behavior, but the
linked evaluator had no padded-width fixture and therefore could not validate
the change. The evaluator now adds `hidden_padded_width` with `WIDTH=" 5 "`,
normalizes that argument in the oracle, and documents the contract in
`../../evals/task-histogram/EVAL.md` and
`../../evals/task-histogram/runtime/task.md`. Native contract coverage is in
`../../tests/tools_test.xsh`. The preserved engineer branch will be replayed
against the changed package next cycle.

## Throughput requirement

The cycle produced a fresh engineer commit but delivered zero. This is a
throughput failure because an eligible product ticket existed. The corrective
change is the discriminating evaluator fixture; the next cycle must deliver or
reject the preserved candidate based on evidence.

## Provider-health attribution

Provider telemetry was captured; retry counts were zero and provider-error
attribution was `unknown`. The failure was caused by evaluator coverage, not
provider health.

## Baseline metric

Cycle 30: one fresh engineer row, zero delivered commits, 148 assistant turns,
`$0.104614`; see `report.json` and the fresh manager report.

## Target metric

Next cycle: `fresh_engineer_delivered >= 1`, with the new padded-width case
passing and no root infrastructure failure from retained defer.

## Validation

Run the next organization request through `run.xsh`; verify the linked
`task-histogram` report contains the `hidden_padded_width` case and passes
candidate acceptance, then verify a fresh `86-ticket-*-delivered` event before
the retained event. If acceptance fails again, retain the branch and mark the
ticket rejected/deferred rather than merging untested behavior.

## Revert condition

Revert the evaluator fixture if it changes unrelated histogram semantics, the
oracle and candidate disagree on the documented whitespace contract, or it
allows a non-discriminating manager acceptance. The safe inverse is to restore
the prior nine-case package and reject the follow-up ticket as insufficiently
supported.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted`
after running the named verification and link the evidence before further paid
work.
