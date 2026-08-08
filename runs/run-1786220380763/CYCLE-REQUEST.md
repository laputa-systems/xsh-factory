# Cycle request: parser-family consistency with bounded retained validation

Run one bounded organization cycle after `runs/run-1786218719345`. Cycle 29
delivered the fresh positive-parser implementation and both linked replays
passed, but a retained stale-base merge was classified as a generic failure.
The controller now defers retained non-merges explicitly while keeping fresh
delivery hard-gated.

## Bottleneck review

Validate the retained-defer merge path while delivering the fresh
`task-histogram-010` parser-consistency fix. Select the fresh branchless ticket
before one retained branch. A retained replay remains required evidence; if it
cannot merge after fresh delivery, emit `retained-replay-deferred`, preserve
the branch, and do not fail root infrastructure solely for that retained row.
Fresh replay, merge, provenance, and cleanup failures remain hard.

## Mode

- `organization`

## Eval admission

- Allow measured eval reuse: `yes`
- Use the adaptive queue and independent-eval selection.

## Active evals

- Auto.

## Trial plan

- Count: `1`

## New eval proposals

- Count: `0`
- The checked-in eval portfolio is at the coded cap; do not design or promote
  another package in this cycle.

## Approved tickets

- Queue policy: select `task-histogram-010` as the fresh branchless row before
  one retained approved branch.

## Ticket policy

- Review every Open ticket before admission: `yes`
- Require the linked `task-histogram` replay to pass all hard gates before
  fresh delivery.
- Preserve the fresh `86-ticket-*-delivered` event before any retained event.
- Treat only explicit retained replay/merge deferral as nonblocking; missing or
  invalid evidence remains fatal.

## Role overrides

Use adaptive defaults codified by the factory. Keep at least one fresh engineer
row while eligible approved product work exists, and run one independent eval
alongside product work.

## Required outputs

- at least one fresh engineer implementation commit delivered;
- fresh linked replay correctness, restriction, protocol, manager, patch, and
  provenance gates passed;
- retained replay evidence preserved and either passed or explicitly recorded
  as `retained-replay-deferred`;
- independent eval pass;
- cache/build-state evidence for each eval phase;
- unchanged ticket snapshot, structured reports, raw sessions, patches,
  provenance trailers, and run-level `report.json`;
- product, evaluator, infrastructure, and overall cycle outcomes;
- `CTO-PRODUCTIVITY-REPORT.md` and `CTO-IMPROVEMENT.md` completed.
