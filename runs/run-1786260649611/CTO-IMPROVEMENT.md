# CTO factory improvement

## Status

validated

## Change

Extended `factory/tools/eval-trends.xsh` so every row carries its root run,
phase, `tickets_created`, and ticket IDs derived from the durable
`## Source eval and manager` record in ticket files. Added a native fixture in
`tests/tools_test.xsh::test_eval_trends_aggregates_historical_worker_reports`.
Updated the CTO, factory, operator, and loop documentation to make supply
yield an explicit eval-portfolio input.

## Throughput requirement

This cycle produced no reviewable engineer commit because there was no eligible
product ticket. That was intentional admission behavior, but it remains a
throughput miss: the approved branchless buffer is still zero. The improvement
addresses the supply-replenishment decision boundary rather than pretending
the clean eval is delivery.

## Provider-health attribution

Both worker reports captured provider telemetry: zero retries and zero provider
errors. The two manager edit mismatches and one worker shell-probe syntax error
are agent-side recovered noise, not provider-health evidence.

## Baseline metric

Before this change, trend rows used the phase-local worker identity as `run_id`
and contained only effort/provider measurements. They could not show whether a
fresh discovery or linked replay produced a durable ticket. The two latest
valid discovery reports, `task-iniget` and `task-intsum`, each say no ticket,
but that fact was not available in the trend evidence used for portfolio review.

## Target metric

For every ticket with a parseable source-manager record, the corresponding
trend row reports its root run, phase, and exact ticket ID once. A zero-yield
discovery reports `tickets_created: 0`, so lack of replenishment is visible at
the same point as effort and provider health.

## Validation

Validated now: the new fixture first failed against the old output, then passed
with `XSH_MODULE_PATH=. xsht test tests/tools_test.xsh` (82 passed). The live
command `XSH_MODULE_PATH=. xsh factory/tools/eval-trends.xsh -- --format json`
shows 19 attributable ticket-origin phases and `tickets_created: 0` for both
latest discovery rows, `run-1786260192832/task-iniget` and
`run-1786260649611/task-intsum`.

## Revert condition

If a ticket whose `Eval` and `Manager run` fields identify one source appears
under another run or phase, remove the ticket-yield columns and retain only the
root-run/phase correction until the ticket source schema is tightened with a
new native fixture.

## Next-cycle disposition

Keep this improvement validated. No further paid cycle is started from this
closeout. Any future restart must inspect ticket yield before selecting or
retiring evals, and must not convert the empty buffer into a ticket quota.
