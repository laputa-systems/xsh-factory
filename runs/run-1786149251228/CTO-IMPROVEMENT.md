# CTO factory improvement

## Status

pending-validation

## Change

The `task-trim` evaluator accepts both filesystem-module and typed-Path I/O in
`evals/task-trim/evaluator.xsh`. Eval base-image staging is isolated under
`runs/<run>/base-context/.dist` in `factory/controllers/eval.xsh`, and retained
branch replays now skip local binary copying when the exact shared base-image
cache is valid. Native coverage is in `tests/tools_test.xsh`.

## Throughput requirement

This cycle reused one reviewable engineer implementation commit
(`2e244e4ac8c724c2e4720e8840405f8faaee1fb1`) but delivered zero product
commits: the linked replay still used the pre-fix controller process and
failed before worker admission. The final cache-hit fix is ready for the next
paid attempt.

## Provider-health attribution

Provider telemetry was captured for the independent `task-setdiff` workers;
no provider retry or error signal caused the linked failure. The linked phase
had zero paid workers.

## Baseline metric

The prior cycle reached the replay gate but rejected the valid candidate on a
literal `fs.` restriction check. This cycle passed the independent eval but
the linked replay stopped at cached-base-image staging.

## Target metric

The next organization cycle must produce a linked `task-trim` trial with
`correctness: pass` and `restrictions: pass`, then deliver exact commit
`2e244e4ac8c724c2e4720e8840405f8faaee1fb1` to XSH `HEAD`.

## Validation

Run one new organization request through `run.xsh`; check the linked phase
report and evaluator `run.json`, then verify final product `HEAD` equals the
candidate commit and `task-trim-001` is `Merged.`.

## Revert condition

If a run-scoped staging cycle still fails before worker admission, or if the
repaired evaluator rejects the valid Path-based candidate, retain the branch,
stop paid work, and revert only the corresponding staging/evaluator change
after preserving the failing evidence.
