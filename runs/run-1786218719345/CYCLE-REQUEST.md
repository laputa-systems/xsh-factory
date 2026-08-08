# Cycle request: positive-bound implementation with nonblocking retained validation

Run one bounded organization cycle after `runs/run-1786216593690`. Cycle 28
delivered one fresh engineer commit, but its root result failed because a
retained replay manager timeout was classified as a generic delivery failure.
The factory now records retained timeout/defer evidence explicitly while
keeping fresh implementation, replay, merge, and provenance gates hard.

## Bottleneck review

The next constraint is commit-to-replay closeout. Select the fresh branchless
approved ticket before one retained branch. The fresh `task-histogram-009`
implementation must pass its linked replay and merge gates. A retained replay
is still dispatched and its evidence is preserved, but an explicit bounded
`retained-replay-deferred` outcome must not block fresh delivery or root
infrastructure success when the detached worktree is clean. Missing or
invalid phase evidence remains fatal.

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

- Queue policy: select `task-histogram-009` as the fresh branchless row before
  one retained approved branch.

## Ticket policy

- Review every Open ticket before admission: `yes`
- Require the linked `task-histogram` replay to pass all hard gates before
  fresh delivery.
- Require API-surface justification and CTO approval for the additive parser
  surface.
- Preserve the fresh `86-ticket-*-delivered` event before any retained event.

## Role overrides

Use adaptive defaults codified by the factory. Keep at least one fresh engineer
row while eligible approved product work exists, and run one independent eval
alongside product work.

## Required outputs

- at least one fresh engineer implementation commit delivered;
- fresh linked replay correctness, restriction, protocol, manager, patch, and
  provenance gates passed;
- retained replay evidence preserved and either passed or explicitly recorded
  as `retained-replay-deferred` within the 300-second policy;
- independent eval pass;
- cache/build-state evidence for each eval phase;
- unchanged ticket snapshot, structured reports, raw sessions, patches,
  provenance trailers, and run-level `report.json`;
- product, evaluator, infrastructure, and overall cycle outcomes;
- `CTO-PRODUCTIVITY-REPORT.md` and `CTO-IMPROVEMENT.md` completed.
