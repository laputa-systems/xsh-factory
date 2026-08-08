# CTO factory improvement

## Status

pending-validation

`pending-validation` means the CTO has already implemented this change. It is
not awaiting another approval; the next cycle verifies the named metric or
applies the safe inverse.

## Change

The candidate-linked replay gate in `factory/control.xsh` rejects manager
narratives containing `needs-replay`, `not supported`, or `not exercised`.
`factory/controllers/eval.xsh` records this as `candidate_acceptance` and
includes it in required outputs. The manager role and assignment require an
explicit exercised-acceptance decision. Native regression coverage is in
`tests/factory_control_test.xsh`.

## Throughput requirement

Cycle 10 delivered one retained reviewable engineer implementation commit.
A passing eval-only cycle would not satisfy this requirement when eligible
product work existed.

## Provider-health attribution

State whether provider telemetry was captured. Do not treat latency as an agent
regression when retry, provider-error, or response-timing evidence indicates an
external provider-health issue; if telemetry is missing, state `unknown`.
Telemetry was present for all workers. No provider retries or provider errors
were reported; the turn increase is not attributed to provider health.

## Baseline metric

Cycle 10's linked manager produced a mechanically passing report while its
narrative said the ticket acceptance was not exercised. Evidence:
`phases/02-reeval-task-histogram-004/workers/eval-manager/task-histogram/REPORT.md`.

## Target metric

The next candidate-linked replay must have `candidate_acceptance=true`, an
explicit exercised-acceptance statement, and no disqualifying phrase, while
the organization cycle delivers at least one engineer commit.

## Validation

Run `run.xsh templates/ORGANIZATION-REQUEST-CYCLE-11.md`. Check
`phases/02-reeval-task-bigfiles-002/required-outputs.json`, the linked manager
narrative, and root `report.json` throughput/delivery fields.

## Revert condition

If a correctly directed candidate replay is rejected because the manager
narrative mentions a historical phrase outside its decision, narrow the gate to
the manager's acceptance decision section. If an unexercised candidate is
delivered, block delivery and retain the branch.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted`
after running the named verification, and link the evidence before admitting
paid work.
