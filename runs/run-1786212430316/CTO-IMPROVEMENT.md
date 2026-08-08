# CTO factory improvement

## Status

pending-validation

`pending-validation` means the CTO has already implemented this change. It is
not awaiting another approval; the next cycle verifies the named metric or
applies the safe inverse.

## Change

Repaired the task-histogram restriction contract to accept either typed
`parse_int` or typed `parse_uint` in
`evals/task-histogram/evaluator.xsh`, and synchronized its EVAL/runtime
documentation. Added native coverage in `tests/tools_test.xsh`.

Added a retained-replay throughput compromise: the organization controller
marks retained rows with `FACTORY_RETAINED_REPLAY`, and the eval controller
applies `control.retained_replay_manager_wall_seconds()` (300 seconds) only to
that manager. Fresh replay retains the normal 600-second manager ceiling and
the hard delivery gate. Wiring is covered by `tests/factory_control_test.xsh`
and `tests/tools_test.xsh`.

## Throughput requirement

Cycle 26 produced one reviewable engineer implementation commit but delivered
zero commits, so it is a throughput failure. The corrective change targets the
replay/merge bottleneck while preserving mandatory fresh validation.

## Provider-health attribution

Provider telemetry was captured in the worker reports. No provider errors or
retry signal explains the failure; the evidence points to the stale evaluator
contract and manager closeout budget.

## Baseline metric

Baseline: cycle 26 had 1 fresh engineer row, 0 deliveries, 2 linked replays,
0 passing replays, cost `$0.123247`, and 177 turns in
`runs/run-1786212430316/report.json`.

## Target metric

Next cycle: `delivered_tickets >= 1`; fresh replay required outputs and phase
report pass; fresh delivery event before retained delivery; retained manager
bounded by 300 seconds.

## Validation

Run the next documented organization request through `run.xsh`. Check
`report.json` throughput, `required-outputs.json`, replay phase reports, and
the ordered `86-ticket-*` events. Re-run the focused native tests before paid
admission.

## Revert condition

If a fresh `parse_uint` replay still fails restriction despite the new contract,
or if a retained manager exceeds the 300-second bound without a durable retry
marker, revert the corresponding evaluator/policy change and retain the
branches for directed review.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted`
after running the named verification, and link the evidence before admitting
paid work.
