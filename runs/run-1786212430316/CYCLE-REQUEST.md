# Cycle request: repaired acceptance gate with fresh delivery

Run one bounded organization cycle after `runs/run-1786209582303`. Cycle 25
produced one fresh engineer row and passing fresh replay evidence but delivered
zero commits because the manager acceptance wording was not recognized. The
acceptance gate and manager assignment are now repaired and tested.

## Bottleneck review

Keep correctness, restriction, manager evidence, patch, and provenance gates
hard. The controller may recognize an explicit plain-language candidate
acceptance only when rejection or needs-replay language is absent. Select fresh
approved branchless work before retained branches, and wait/merge fresh replay
rows before retained replay rows. At most one retained branch may accompany the
fresh row.

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
- the acceptance-gate regression is exercised by a passing phase report.

## CTO handoff

Complete `CTO-PRODUCTIVITY-REPORT.md` and `CTO-IMPROVEMENT.md`. Mark the
cycle-25 improvement `validated` only when a fresh commit is delivered and the
fresh delivery event precedes any retained replay delivery event without a
quality-gate bypass.
