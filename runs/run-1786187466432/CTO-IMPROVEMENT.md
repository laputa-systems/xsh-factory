# CTO factory improvement

## Status

implemented-pending-validation

`pending-validation` means the CTO has already implemented this change. It is
not awaiting another approval; the next cycle verifies the named metric or
applies the safe inverse.

## Change

Repaired the candidate-replay acceptance predicate in
`factory/control.xsh::reeval_manager_acceptance_gate`. It now recognizes an
explicit acceptance decision or exercised-acceptance statement and ignores
documentation prose that merely lists possible decisions. It still rejects
explicit `reject`, `needs-replay`, unsupported, and unexercised decisions.
Regression cases are in `tests/factory_control_test.xsh`; all 132 native tests
pass.

## Throughput requirement

Cycle 12 produced no fresh or delivered engineer commit, so it is a throughput
failure. The corrective change is the explicit acceptance gate repair above.

## Provider-health attribution

Provider telemetry was captured for all four workers; retry counts were zero
and no provider errors were reported. The failure is attributable to factory
gating, not provider health.

## Baseline metric

Cycle 11 delivered zero tickets after producing one fresh engineer commit;
see `../run-1786185105660/CTO-PRODUCTIVITY-REPORT.md` and its root report.
Cycle 12 again delivered zero, with the false-positive gate recorded in its
linked required outputs.

## Target metric

Cycle 13 must deliver at least one engineer commit and record
`delivery_conversion == 1`; the retained `task-bigfiles-002` candidate is the
first validation target.

## Validation

Run `templates/ORGANIZATION-REQUEST-CYCLE-13.md`, then verify the root
`report.json`, absence of `86-ticket-*-delivery-failed`, and
`delivered_tickets >= 1` before closeout.

## Revert condition

If an explicitly accepted replay still fails the gate, or if generic prose can
still deliver an explicitly rejected candidate, revert this predicate to the
prior fail-closed form and add the exact counterexample to the native test
before another paid cycle.

## Next-cycle disposition

The next CTO must replace this status with `validated` or `reverted` after the
cycle 13 delivery check and link the evidence before admitting cycle 14.
