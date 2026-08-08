# Cycle request: record-diagnostic delivery with bounded retained validation

Run one bounded organization cycle after `runs/run-1786215025081`. Cycle 27
validated the throughput compromise: one fresh and one retained engineer row
both delivered, both linked replays passed, and the fresh delivery event came
first. Preserve that ordering and validation contract while exercising the
newly approved record-literal diagnostic ticket.

## Bottleneck review

Keep correctness, restriction, manager evidence, patch, and provenance gates
hard for fresh delivery. Select the fresh branchless ticket before retained
branches. Retained replay remains required evidence with the shorter manager
closeout bound, but it must not delay a completed fresh delivery. The next
infrastructure observation is repeated isolated XSH image/build work; record
cache/build-state evidence without treating a cache miss as permission to skip
replay.

## Mode

- `organization`

## Eval admission

- Allow measured eval reuse: `yes`
- The controller selects the next untried approved eval according to queue
  pressure.

## Active evals

- Auto.

## Trial plan

- Count: `1`

## New eval proposals

- Count: `0`
- The checked-in eval portfolio is at the coded cap; do not design or promote
  another package in this cycle.

## Approved tickets

- Queue policy: select the fresh `task-histogram-008` row before one retained
  approved branch.

## Ticket policy

- Review every Open ticket before admission: `yes`
- Require the linked `task-histogram` replay to pass all hard gates before
  delivery.
- Require API-surface justification and CTO approval for any new XSH API.
- Preserve the fresh `86-ticket-*-delivered` event before any retained delivery
  event.

## Role overrides

Use adaptive defaults codified by the factory. Keep at least one fresh engineer
row while eligible approved product work exists, and run one independent eval
alongside product work.

## Required outputs

- at least one fresh engineer implementation commit delivered;
- fresh linked replay correctness, restriction, protocol, manager, patch, and
  provenance gates passed;
- retained replay evidence preserved and bounded by the 300-second policy;
- independent eval pass;
- cache/build-state evidence for each eval phase;
- unchanged ticket snapshot, structured reports, raw sessions, patches,
  provenance trailers, and run-level `report.json`;
- product, evaluator, infrastructure, and overall cycle outcomes;
- `CTO-PRODUCTIVITY-REPORT.md` and `CTO-IMPROVEMENT.md` completed.
