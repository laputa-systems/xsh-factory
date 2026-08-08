# CTO factory improvement

## Status

pending-validation

`pending-validation` means the CTO has already implemented this change. It is
not awaiting another approval; the next cycle verifies the named metric or
applies the safe inverse.

## Change

The evaluator restriction contract in `evals/task-trim/evaluator.xsh` now
accepts both filesystem-module and typed-Path file I/O, eliminating the
literal-`fs.` false negative. The eval controller was also hardened so each
phase builds from its own `runs/<run>/base-context/.dist` directory instead of
the shared `evals/.dist` staging directory; the regression is covered by
`tests/tools_test.xsh::test_eval_staging_context_is_run_scoped`.

## Throughput requirement

The cycle reused one reviewable implementation commit (`2e244e4`) but produced
zero new engineer rows and delivered zero product commits because the linked
replay failed during controller staging before any worker ran. Classify this
cycle as a delivery/infrastructure failure; the retained branch remains
available for the next verification cycle.

## Provider-health attribution

Provider telemetry was captured for the independent `task-setdiff` worker and
manager; no provider retry or error signal caused the linked failure. The
linked phase had zero paid workers.

## Baseline metric

The prior cycle reached the replay gate but rejected the valid candidate on a
literal `fs.` restriction check (`runs/run-1786147170660/phases/02-reeval-task-trim-001/workers/eval-manager/task-trim/REPORT.md`).
This cycle's independent eval passed, but the linked replay stopped at staging
(`runs/run-1786148605115/phases/02-reeval-task-trim-001/report.json`).

## Target metric

The next organization cycle must produce a linked `task-trim` trial with
`correctness: pass` and `restrictions: pass`, then deliver exact commit
`2e244e4ac8c724c2e4720e8840405f8faaee1fb1` to XSH `HEAD`.

## Validation

Run one new organization request through `run.xsh`; check the linked phase
report and evaluator `run.json`, then verify the final product `HEAD` equals
the candidate commit and `task-trim-001` is `Merged.`.

## Revert condition

If a run-scoped staging cycle still fails before worker admission, or if the
repaired evaluator rejects the valid Path-based candidate, retain the branch,
stop paid work, and revert only the corresponding staging/evaluator change
after preserving the failing evidence.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted`
after running the named verification, and link the evidence before admitting
paid work.
