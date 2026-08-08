# Cycle request: typed-integer replay and bounded retained validation

Run one bounded organization cycle after `runs/run-1786212430316`. Cycle 26
produced one fresh engineer commit but delivered zero because the
task-histogram evaluator rejected the candidate's valid `parse_uint` surface;
the evaluator contract is now repaired and covered by native tests. Retained
replay managers also have a shorter, explicit closeout bound.

## Bottleneck review

Keep correctness, restriction, manager evidence, patch, and provenance gates
hard for fresh delivery. The task-histogram evaluator must accept either
typed `parse_int` or typed `parse_uint`; do not bypass correctness or
restriction checks. Select fresh approved branchless work before retained
branches, and merge fresh replay rows before retained replay rows. At most one
retained branch may accompany the fresh row; retained validation remains
valuable evidence but must not delay the fresh delivery target beyond its own
hard gate.

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

## Approved tickets

- Queue policy: adaptive; select fresh approved product rows before retained
  branches, with at most one retained replay in the batch.

## Role overrides

Use adaptive defaults codified by the factory. Keep at least one fresh engineer
row while eligible approved product work exists. Run one independent eval for
this ticket cycle.

## Required outputs

- at least one fresh engineer implementation commit delivered;
- the fresh candidate's linked replay passes all hard gates;
- retained replay evidence is preserved even if deferred or failed;
- independent eval pass;
- unchanged ticket snapshot, structured reports, raw sessions, patches,
  provenance trailers, and run-level `report.json`;
- product, evaluator, infrastructure, and overall cycle outcomes;
- the repaired typed-integer restriction gate is exercised by a passing fresh
  replay phase report;
- retained manager closeout is bounded by the 300-second policy.

## CTO handoff

Complete `CTO-PRODUCTIVITY-REPORT.md` and `CTO-IMPROVEMENT.md`. Mark the cycle
26 improvement `validated` only when a fresh commit is delivered, the fresh
replay required outputs pass, the fresh delivery event precedes any retained
replay delivery event, and no quality-gate bypass occurs.
