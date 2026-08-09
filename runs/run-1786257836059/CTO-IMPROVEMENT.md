# CTO factory improvement

## Status

pending-validation

## Change

Make every eval-manager admission packet read sequentially. The primary
assignment, bounded-retry template, and role contract now require exactly five
`read` calls one at a time and in order, waiting for each result before the
next call. `tests/tools_test.xsh::test_eval_manager_assignment_proves_exact_handbook_read`
asserts the non-batching rule.

## Throughput requirement

This organization cycle met the engineer throughput requirement: one newly
dispatched engineer committed and delivered `task-envcfg-009` after a passing
linked replay. The independent supply lane nevertheless failed, leaving no
approved queue for the next delivery. This improvement targets the
worker-evidence -> ticket-decision constraint that now limits buffer
maintenance.

## Provider-health attribution

All manager telemetry was captured. The two supply manager attempts each had
zero retries, zero retry delay, and no provider errors; both stopped after one
turn immediately following five parallel reads. The candidate replay recovery
had the same provider-health profile and completed after eight turns. This is
not attributed to provider health.

## Baseline metric

In `run-1786257836059/phases/03-supply-eval`, both
`task-groupsum` manager attempts left `REPORT.md` at `not-ready` with
`required_outputs.manager_report: false`. Their raw sessions show five
admission reads in a single assistant turn and no following draft call.

## Target metric

For the next eval-manager packet of comparable or larger size, the raw session
shows the five required reads issued separately and the next action drafts the
staged report. The phase records `required_outputs.manager_report: true`; a
manager may still conclude that no ticket is warranted.

## Validation

On the next paid supply or discovery eval, inspect the manager raw session,
`required-outputs.json`, and phase `report.json`. Confirm one read per
admission turn, no parallel batch, a draft after the fifth result, and
`manager_report: true`.

## Revert condition

If a sequential-read manager again leaves the report `not-ready`, preserve the
session and replace retry-time free-form drafting with a controller-generated,
structured report draft for manager refinement. Do not add another competing
read-order instruction.

## Next-cycle disposition

The next CTO marks this `validated` only with the named sequential raw-session
evidence and a valid manager report; otherwise mark it `reverted` and apply
the controller-draft fallback before another supply admission.
