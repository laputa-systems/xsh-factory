# CTO factory improvement

## Status

implemented-pending-validation

`pending-validation` means the CTO has already implemented this change. It is
not awaiting another approval; the next cycle verifies the named metric or
applies the safe inverse.

## Change

The cycle validated the explicit replay acceptance gate repair from cycle 12:
`task-bigfiles-002` delivered successfully. A second repair is now implemented
in `factory/controllers/eval.xsh`: when an eval-manager exits without a
complete narrative, the controller preserves attempt-1 report/session files,
dispatches exactly one retry, and promotes a complete retry report/session into
the canonical manager slot. Retry lifecycle evidence uses structured events.
`tests/tools_test.xsh` asserts the retry contract; all 132 native tests pass.

## Throughput requirement

Cycle 13 delivered one retained engineer implementation commit, satisfying the
hard throughput requirement. The root cycle nevertheless failed on evaluator
closeout, so the retry is required before treating the cycle machinery as
healthy.

## Provider-health attribution

Provider telemetry was captured for the worker and manager sessions. The
independent manager ended with a model `stopReason=error`; no aggregate budget
breach occurred. Attribution is an agent/provider completion failure, not a
product or delivery failure.

## Baseline metric

Cycle 12 delivered zero and failed the false-positive acceptance gate. Cycle 13
delivered one (`delivery_conversion=1.0`) but had one incomplete independent
manager report; see this run's `report.json` and `phases/03-eval/required-outputs.json`.

## Target metric

Cycle 14 must deliver at least one fresh engineer commit and have
`manager_report=true` and `required=true` for every eval phase. A retry may be
used once per incomplete manager report and must preserve attempt-1 evidence.

## Validation

Run `templates/ORGANIZATION-REQUEST-CYCLE-14.md`; inspect root throughput,
each phase `required-outputs.json`, and the presence of any
`81-manager-retry-recovered` event before closeout.

## Revert condition

If a retry overwrites the wrong manager evidence, permits a `not-ready` report,
or dispatches more than one retry per phase, revert the retry block and retain
the original fail-closed behavior while adding a synthetic controller test.

## Next-cycle disposition

The next CTO must mark this `validated` or `reverted` after cycle 14 and link
the evidence before admitting cycle 15.
