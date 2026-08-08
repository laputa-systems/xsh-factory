# CTO factory improvement

## Status

implemented-pending-validation

`pending-validation` means the CTO has already implemented this change. It is
not awaiting another approval; the next cycle verifies the named metric or
applies the safe inverse.

## Change

The CTO repaired `factory/control.xsh::reeval_manager_acceptance_gate` to
recognize the explicit manager wording used in this run:
`Controller decision in conference: retain/accept the candidate branch`.
The change is covered by `tests/factory_control_test.xsh`. The gate remains
fail-closed for explicit rejection, needs-replay, and unexercised-acceptance
wording. The manager retry machinery from the prior cycle remains intact; this
run did not need to exercise it because both manager reports completed.

## Throughput requirement

Cycle 14 produced one reviewable fresh engineer commit but delivered zero, so
it is a throughput failure despite passing evaluator work. The corrective
action is a retained-branch delivery cycle, with no duplicate engineer row,
so the next paid cycle converts the already-completed product work into XSH
HEAD.

## Provider-health attribution

Provider telemetry was present in all six worker reports. There was no budget
breach and no provider retry/error signal. The failure is attributed to the
deterministic acceptance parser, not provider health.

## Baseline metric

Cycle 14: `fresh_engineer_rows=1`, `delivered_tickets=0`,
`delivery_conversion=0.0`; linked replay evaluator and manager work were
otherwise successful. See [report.json](report.json) and the linked
`required-outputs.json`.

## Target metric

Cycle 15 must deliver at least one engineer implementation commit and reach
`delivered_tickets >= 1`, `delivery_conversion=1.0`,
`candidate_acceptance=true`, and `manager_report=true` for the linked phase.

## Validation

Run `templates/ORGANIZATION-REQUEST-CYCLE-15.md`; inspect root throughput,
linked required outputs, the acceptance event, and the final XSH HEAD
provenance.

## Revert condition

If a report containing the exact explicit `retain/accept` decision is still
rejected, stop delivery, retain the branch, and extend the parser regression
fixture before another paid cycle. Do not weaken the gate to generic mentions
of acceptance options.

## Next-cycle disposition

The next CTO must replace this status with `validated` or `reverted` after
cycle 15 and link the evidence before admitting the following cycle.
