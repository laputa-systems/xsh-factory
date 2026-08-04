# CTO factory improvement

## Status

validated

## Change

Make eval dispatch package-owned and make `events.jsonl` the canonical cycle
ledger. `evaluate_common.xsh` now dispatches only the mounted package
`evaluator.xsh`; controller process stdout/stderr is appended as
`kind: "process-output"` events. Paths: `evaluate_common.xsh`,
`eval-executor.xsh`, `evals/*/evaluator.xsh`, `factory_runtime.xsh`, and the
controller files that emit process events.

## Baseline metric

Before this change, `evaluate_common.xsh` contained three eval-specific
branches and the cycle required scattered controller stdout/stderr files.
The failed cycle `runs/run-1785731807794` required separate inspection of
`reeval.stdout`, `designer.stdout`, manager logs, and phase reports.

## Target metric

The next cycle must pass native checks with zero eval-name branches in
`evaluate_common.xsh`, and its cycle `events.jsonl` must contain process-output
events for every controller child that completes. A new eval package must be
admitted by adding its evaluator script without editing the generic common
dispatcher.

## Validation

Run the next organization cycle. Check `xsht test`, the generic dispatch
contract, and `events.jsonl` for `kind: "process-output"` entries covering
eval workers, managers, designer, and child phases.

## Revert condition

If an approved eval cannot run with only its package `evaluator.xsh`, or if
completed child output is absent from the canonical event ledger, revert the
generic dispatch/event changes and restore the prior implementation after
preserving the failing evidence.

## Next-cycle disposition

Validated by `runs/run-1785733794880`: `XSH_MODULE_PATH=. xsht test` passed
29/29; `task-ecount` and `task-envcfg` both completed through their
package-owned `evaluator.xsh`; and `events.jsonl` contains paired
`kind: "process-output"` entries for `reeval-task-ecount-003`,
`independent-eval-task-envcfg`, and `eval-design`. No revert is required.
