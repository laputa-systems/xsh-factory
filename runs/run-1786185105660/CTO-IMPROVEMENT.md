# CTO factory improvement

## Status

pending-validation

`pending-validation` means the CTO has already implemented this change. It is
not awaiting another approval; the next cycle verifies the named metric or
applies the safe inverse.

## Change

`factory/controllers/organization.xsh` now treats a passing linked phase report
as the delivery gate even when the child controller exits nonzero, while
retaining that exit in process evidence. `factory/tools/audit.xsh` forces a
product failure for any delivery-failed event. `factory/tools/run-status.xsh`
derives its terminal result from the lifecycle event. Regression coverage is
in `tests/tools_test.xsh`.

## Throughput requirement

Cycle 11 produced one reviewable engineer implementation commit but delivered
zero. This is a throughput failure because eligible product work existed; the
retained branch is the next-cycle delivery input.

## Provider-health attribution

State whether provider telemetry was captured. Do not treat latency as an agent
regression when retry, provider-error, or response-timing evidence indicates an
external provider-health issue; if telemetry is missing, state `unknown`.
Telemetry was present. Retry counts were zero and no provider errors were
reported; the failure is attributed to controller/process evidence handling,
not provider health.

## Baseline metric

Cycle 11 had `fresh_engineer_rows=1`, `delivered_tickets=0`, and
`delivery_conversion=0.0` in `report.json`; the engineer branch commit was
`0fb5c82`. The linked phase report passed, but the organization event recorded
`86-ticket-task-bigfiles-002-delivery-failed` after a nonzero child status.

## Target metric

Cycle 12 must deliver the retained branch with `delivered_tickets=1`,
`delivery_conversion=1.0`, product/evaluator/infrastructure outcomes passing,
and a terminal `run-status` result of `pass`.

## Validation

Run `run.xsh templates/ORGANIZATION-REQUEST-CYCLE-12.md`. Check root
`report.json`, `events.jsonl`, the delivery event, and
`factory/tools/run-status.xsh -- --run-dir RUN_DIR`.

## Revert condition

If a passing phase report still cannot merge the retained branch, preserve the
branch and investigate `merge_validated_ticket` or branch identity. If a
failing phase report is delivered, immediately restore the process-and-report
conjunction and block delivery.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted`
after running the named verification, and link the evidence before admitting
paid work.
