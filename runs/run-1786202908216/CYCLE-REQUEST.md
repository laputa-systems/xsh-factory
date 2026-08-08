# Cycle request: replay the preserved API fix and add a fresh diagnostic ticket

Run one bounded organization cycle after cycle 22's replay-gate repair.

## Mode

- `organization`

## Bottleneck review

- The current bottleneck is commit -> linked replay -> merge. Cycle 22's
  workers passed, but the manager wording gate rejected valid acceptance
  evidence. Cycle 23 must prove the preserved `task-dupcheck-002` commit is
  delivered and must exercise the repaired gate.

## Eval admission

- Allow measured eval reuse: `yes`

## Active evals

- `task-grep`

## Trial plan

- Count: `1`

## New eval proposals

- Count: `0`
- The checked-in portfolio is at the coded cap; do not design or promote a
  package in this cycle.

## Approved tickets

- `task-dupcheck-002`
- `task-histogram-007`

## Ticket policy

- Review all open tickets before selection: `yes`
- Reuse the preserved engineer branch for `task-dupcheck-002` and deliver its
  validated provenance commit `b9cc3ffc6425b365a172c5a897ed9684db235487`.
- Dispatch one fresh engineer for `task-histogram-007`.
- Deliver at least one engineer implementation commit; a passing worker or
  retained replay without product delivery does not satisfy this target.

## Required outputs

- at least one engineer implementation commit delivered;
- both selected linked replays attempted;
- independent `task-grep` eval passes;
- root `report.json` with `delivered_tickets >= 1` and a passing linked phase
  whose required-output gate is true;
- structured reports, raw sessions, lifecycle ledger, ticket snapshots, and
  the next CTO productivity/improvement handoff preserved.
