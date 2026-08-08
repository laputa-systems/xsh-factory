# Cycle request: retained replay plus fresh engineer delivery

Run one bounded organization cycle after `run-1786197177807`. Cycle 17 had
zero delivery: the retained bigfiles replay lost its worker to an external
provider stream failure, and the manager retry was slowed by a stale
controller-owned worktree path. Cycle 18 must exercise the repaired manager
handoff and restore fresh product throughput.

## Bottleneck review

The prior bottleneck was linked replay/merge, while the approved queue had no
fresh row. `task-dupcheck-002` is now CTO-approved from its reproducible
signature-rendering evidence. Keep the retained `task-bigfiles-004` branch in
directed replay and dispatch exactly one fresh engineer row for dupcheck.

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
  row in the same bounded batch.
- Require at least one fresh engineer commit to reach XSH `HEAD` when its
  linked acceptance replay passes; retain any failed branch for the next CTO.

## Required outputs

- at least one fresh engineer implementation commit delivered;
- retained bigfiles replay attempted with the repaired manager assignment;
- independent `task-histogram` eval passes;
- root `report.json` with `fresh_engineer_rows >= 1`,
  `delivered_tickets >= 1`, and `delivery_conversion >= 0.5`;
- manager reports and required outputs preserved for every eval phase;
- terminal lifecycle and `run-status` report the final outcome;
- structured reports, raw sessions, lifecycle ledger, and ticket snapshots
  preserved.
