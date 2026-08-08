# CTO factory improvement

## Status

pending-validation

`pending-validation` means the CTO has already implemented this change. It is
not awaiting another approval; the next cycle verifies the named metric or
applies the safe inverse.

## Change

`factory/controllers/organization.xsh` now delays controller-owned ticket
reconciliation until overlapping independent evals finish, eliminating the
race that made the eval manager's immutable ticket snapshot reject a valid
delivery. `factory/tools/audit.xsh` now composes the direct phase outcome
dimensions instead of turning an evaluator/infrastructure failure into a
product failure. `tests/tools_test.xsh` covers both ordering and aggregation.

## Throughput requirement

State whether the cycle produced at least one reviewable engineer
implementation commit. If not, classify the cycle as a throughput failure and
describe the corrective factory change; a passing eval-only cycle does not
satisfy this requirement when an eligible product ticket existed.

Yes: one reviewable commit, `a652116`, was delivered for the one admitted
ticket. The hard throughput goal was met even though the overall cycle failed
its independent-eval closeout gate.

## Provider-health attribution

State whether provider telemetry was captured. Do not treat latency as an agent
regression when retry, provider-error, or response-timing evidence indicates an
external provider-health issue; if telemetry is missing, state `unknown`.
satisfy this requirement when an eligible product ticket existed.

Provider telemetry was captured for all four workers. There were no budget
failures or unknown costs; the failure was deterministic controller overlap,
not provider health.

## Baseline metric

State the prior-cycle measurement and evidence path.

Cycle 3 delivered 1/1 ticket at `$0.157814` and 162 turns
(`runs/run-1786165552479`). The failed cycle immediately before this one
delivered 0/1 because the audit rejected a per-case correctness manifest
(`runs/run-1786167293099`). This cycle delivered 1/1 at `$0.054617` but
exposed the ticket-reconciliation race (`runs/run-1786168895521`).

## Target metric

State the measurable result expected in the next cycle.

At least one delivered engineer commit, `delivery_conversion: 1.0`, and a
passing independent-eval closeout with `ticket_snapshot_unchanged: true`,
`manager_report: true`, and all root outcome dimensions `pass`.

## Validation

State the exact next-cycle command, report field, or invariant that will be
checked.

Run `run.xsh` through the next explicitly requested organization cycle, then
inspect `report.json`, `phases/03-eval/required-outputs.json`, and
`run-status.xsh`. The ordering regression must show no
`81-ticket-state-mutated` event caused by the primary delivery.

## Revert condition

State the evidence that falsifies the change and the safe inverse action.

If a clean next cycle still reports a controller-owned ticket mutation during
the manager window, or root outcome dimensions disagree with the child phase
reports, revert the ordering/aggregation changes and stop paid admission for
another deterministic investigation.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted`
after running the named verification, and link the evidence before admitting
paid work.

The current run is the baseline evidence; validation belongs to the next
explicitly requested paid cycle.
