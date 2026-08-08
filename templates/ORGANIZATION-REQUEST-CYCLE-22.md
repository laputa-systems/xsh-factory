# Cycle request: recovered runtime and fresh engineer delivery

Run one bounded organization cycle after the cycle-21 Docker preflight
interruption. OrbStack is healthy again; no worker or run directory was
created during that interruption.

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
