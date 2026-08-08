# Cycle request: retained delivery plus fresh helper-error throughput

Run one bounded organization recovery cycle after run-1786174072800. Deliver
the reviewed retained `task-pathparts-003` commit through the deterministic
reuse path, and dispatch exactly one fresh engineer row for the oldest focused
`task-histogram` helper-effect ticket. The manager closeout timeout repair is
part of this cycle's validation.

## Mode

- `organization`

## Eval admission

- Allow measured eval reuse: `yes`

## Active evals

- `task-histogram`

## Trial plan

- Count: `1`

## New eval proposals

- Count: `0`

## Approved tickets

- `task-pathparts-003`
- `task-histogram-004`

## Ticket policy

- Review all open tickets before selection: `yes`
- Dispatch exactly the two explicitly approved tickets above; reuse the
  existing pathparts branch and dispatch histogram as the sole fresh row.
- `Open.` tickets are never promoted by the controller.

## Role overrides

Use the defaults codified by the factory. The adaptive queue should use the
current open-ticket pressure when allocating the independent eval.

## Required outputs

- one retained engineer commit delivered and one fresh engineer implementation
  commit reviewed;
- linked replay evidence for both approved tickets and one independent eval;
- `ticket_snapshot_unchanged: true` and completed manager reports;
- structured reports, raw sessions, and a run-level `report.json`;
- product, evaluator, infrastructure, and overall cycle outcomes.
