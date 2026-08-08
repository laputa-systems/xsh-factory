# CTO factory improvement

## Status

validated

The adaptive queue-pressure change was implemented before this cycle and is
now validated by the run evidence below.

## Change

The change is in `run.xsh` and `factory/controllers/organization.xsh`, with
queue counting in `factory/runtime.xsh` and the engineer cap in
`factory/control.xsh`. The approved-eval fallback is covered by
`tests/tools_test.xsh`; the contract and operator docs are in `FACTORY.md`,
`THROUGHPUT.md`, and the organization request templates. The cycle recorded
`open=7; approved=1; engineers=1; discovery_evals=1`.

## Throughput requirement

Met. The cycle produced and delivered one validated engineer implementation
commit, `95878384b9d6bb66f5631d630dca4d306f95a3a0`, from one admitted ticket.
The linked replay and independent eval both passed, and the commit is reachable
from XSH `HEAD`.

## Provider-health attribution

Provider telemetry was captured for all six workers. No retry or provider-health
failure was indicated; the 15 tool errors are retained as agent tool-use
evidence.

## Baseline metric

The prior cycle, [run-1786159268557](../run-1786159268557/report.json), delivered
one ticket at `$0.132657208` with six workers and 151 assistant turns.

## Target metric

The next cycle must again deliver at least one engineer commit whenever an
approved product ticket is ready, while preserving the queue rule: up to two
engineers with approved work and one independent eval; discovery expansion only
when no approved ticket is ready.

## Validation

Evidence is [report.json](report.json): `result: pass`, all three outcome
dimensions pass, `throughput.admitted_tickets: 1`,
`throughput.fresh_engineer_rows: 1`, and `throughput.delivered_tickets: 1`.
The `05-adaptive-queue-selected` event proves the allocation decision, and
XSH `HEAD` is `9587838`.

## Revert condition

The change is falsified if an approved ticket is present but a cycle dispatches
zero engineer rows, if an admitted row is not delivered, or if adaptive
selection is nondeterministic. The safe inverse is explicit admission while
retaining the existing two-engineer/four-eval bounds, followed by repair of the
failing native regression before paid work.

## Next-cycle disposition

Validated by [report.json](report.json), [CTO-REPORT.md](CTO-REPORT.md), and
the final `95-cycle-validated` event. The cycle also produced
`tickets/task-safepath-003.md` for the residual nested-conditional lowering
defect; it is the next candidate after explicit CTO approval.
