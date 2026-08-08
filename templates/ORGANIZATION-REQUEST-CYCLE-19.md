# Cycle request: corrected admission and fresh engineer delivery

Run one bounded organization cycle after `run-1786200115259`. Cycle 18 stopped
before paid work because the newly approved dupcheck ticket failed its own
API-surface evidence gate; that contract and diagnostic are now repaired.

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

- `task-bigfiles-004`
- `task-dupcheck-002`

## Ticket policy

- Review all open tickets before selection: `yes`
- Replay the retained bigfiles branch and dispatch one fresh dupcheck engineer
  row.
- Deliver at least one fresh engineer commit when its linked replay passes.

## Required outputs

- at least one fresh engineer implementation commit delivered;
- retained bigfiles replay attempted;
- independent `task-histogram` eval passes;
- root `report.json` with `fresh_engineer_rows >= 1` and
  `delivered_tickets >= 1`;
- structured reports, raw sessions, lifecycle ledger, and ticket snapshots
  preserved.
