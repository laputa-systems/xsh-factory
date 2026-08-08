# Cycle request: throughput-repair validation organization

Run one bounded organization cycle after the overlap and report-aggregation
repairs. Admit the evidence-backed `task-bigfiles-003` ticket so the cycle
must exercise engineer delivery, linked replay, independent manager closeout,
and the hard one-commit throughput goal.

## Bottleneck review

The previous cycle delivered one engineer commit but failed its independent
manager closeout because controller-owned ticket reconciliation raced the
manager snapshot. The machinery is repaired and natively tested; this cycle
validates the repair while implementing the focused metadata correctness
ticket.

## Mode

- `organization`

## Eval admission

- Allow measured eval reuse: `yes`

## Active evals

- `task-bigfiles`

## Trial plan

- Count: 1

## New eval proposals

- Count: 0

## Approved tickets

- `task-bigfiles-003`

## Ticket policy

- Review all open tickets before selection: yes
- Dispatch exactly the explicitly approved ticket above.
- `Open.` tickets are never promoted by the controller.

## Role overrides

Use the defaults codified by the factory.

## Required outputs

- one fresh engineer implementation commit;
- one linked replay and one independent eval;
- `ticket_snapshot_unchanged: true` and a completed manager report;
- structured reports, raw sessions, and a run-level `report.json`;
- product, evaluator, infrastructure, and overall cycle outcomes.
