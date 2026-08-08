# Cycle request: fresh-first delivery with retained replay

Run one bounded organization cycle after `run-1786206296254`. Cycle 24
delivered fresh `task-grep-001` despite failing retained replay, but merge
ordering made the cycle unnecessarily long. Cycle 25 must validate the
fresh-first selection/merge policy and deliver at least one fresh engineer
commit while keeping that candidate's linked replay hard-gated.

## Bottleneck review

The factory now selects branchless approved tickets before retained branches,
merges fresh replay-passing rows before retained rows, and bounds only the
manager retry to 180 seconds. `task-histogram-006` was approved from existing
focused evidence; `task-dupcheck-002` and `task-histogram-007` remain retained
branches for replay pressure. Do not bypass a candidate's correctness,
restriction, report, patch, or provenance gate.

## Mode

- `organization`

## Eval admission

- Approved evals: `task-bigfiles`
- Trial count: `1`
- Measured reuse: `yes`

## Approved tickets

- Queue policy: adaptive; select fresh approved product rows before retained
  branches, with at most one retained replay in the batch.

## Role overrides

Use the adaptive defaults codified by the factory. Keep at least one fresh
engineer row while eligible approved product work exists. Run one independent
eval for this ticket cycle.

## Required outputs

- at least one fresh engineer implementation commit delivered;
- the fresh candidate's linked replay passes all hard gates;
- retained replay evidence is preserved even if deferred or failed;
- independent eval pass;
- unchanged ticket snapshot, structured reports, raw sessions, patches,
  provenance trailers, and run-level `report.json`;
- product, evaluator, infrastructure, and overall cycle outcomes.

## CTO handoff

Complete `CTO-PRODUCTIVITY-REPORT.md` and `CTO-IMPROVEMENT.md`. Mark the
cycle-24 improvement `validated` only when the fresh-first invariant and the
one-fresh-delivery target hold without a replay-gate bypass.
