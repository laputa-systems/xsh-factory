# CTO factory improvement

## Status

pending-validation

`pending-validation` means the CTO implemented the scoped evaluator-boundary
repair after this cycle exposed it. The next cycle must validate the repaired
package before paid work; it is not a request for another approval.

## Change

`evals/task-grep/evaluator.xsh` now takes an explicit `FACTORY_EXPORT` root,
defaulting to `/export`, for artifact copies. The prior evaluator incorrectly
formed `${session_root}/export`, but the controller mounts the worker directory
at `/session` and `/export` separately. The regression contract is
`tests/tools_test.xsh::test_task_grep_evaluator_uses_shared_export_mount`.

## Throughput requirement

The cycle produced zero engineer implementation commits and admitted zero
tickets. This was an intentional eval-only cycle because all five remaining
Open. tickets had current CTO deferral reasons requiring fresh controlled
evidence. The eval worker produced a correct candidate, but the package
evaluator failed before the result packet was complete.

## Provider-health attribution

Provider telemetry was present for both workers. The eval worker had zero
retries and zero provider errors. The eval manager had one retry after a
`Stream ended without finish_reason` provider error, then completed; that
retry is provider health, not agent efficiency. The worker reports retain
three nonzero tool results in the run accounting.

## Baseline metric

Prior baseline: `runs/run-1785973900575/report.json` passed with one reviewable
engineer commit and a complete linked replay plus independent eval. The current
run `runs/run-1786052381421/report.json` admitted zero tickets, used two workers,
and spent `$0.025501806` with `34` assistant turns.

## Target metric

Next cycle target: the `task-grep` package evaluator must write a passing
`workers/eval-worker/task-grep-1/run.json` and export `grep.xsh` and `review.md`
without an `fs-copy` failure, so the phase reaches evaluator `pass` and the
independent signal can be classified.

## Validation

Run `xsht check evals/task-grep/evaluator.xsh`, `xsht test`, and one controlled
package-owned `task-grep` trial. Require the evaluator manifest result to be
`pass`, the phase report outcome to be evaluator `pass`, and the exported
artifacts to exist in the worker evidence directory.

## Revert condition

Revert only if the next controlled trial shows the evaluator still copying
through `${session_root}/export`, loses the exported artifacts, or the native
regression fails. Restore the previous source only with a replacement fix that
preserves the separate `/session` and `/export` mount contract.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` and link the
passing task-grep report, or mark it `reverted` with the failed validation
evidence, before admitting paid work.
