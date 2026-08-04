# CTO factory improvement

## Status

validated

## Change

Validated the previous cycle's factory-wide change making eval dispatch
package-owned and making `events.jsonl` the canonical controller process
ledger. This cycle also preserved the failed eval-design boundary without
promoting its incomplete proposal or inventing an employee narrative.

## Baseline metric

The prior handoff was `pending-validation` in
`runs/run-1785731807794/CTO-IMPROVEMENT.md`. Before the change,
`evaluate_common.xsh` contained eval-specific dispatch branches and completed
child output was scattered across controller log files.

## Target metric

The next organization cycle must pass native checks, run approved evals using
only each package's `evaluator.xsh`, and record paired process-output events in
the canonical ledger for every completed controller child.

## Validation

Evidence in this run:

- `XSH_MODULE_PATH=. xsht test`: 29 passed, 0 failed.
- `phases/02-reeval/report.json`: pass; `task-ecount` package evaluator ran.
- `phases/03-eval/report.json`: pass; `task-envcfg` package evaluator ran.
- `events.jsonl`: paired stdout/stderr `kind: "process-output"` entries for
  `reeval-task-ecount-003`, `independent-eval-task-envcfg`, and `eval-design`.

The organization result remains `fail` because `phases/04-eval-design` did
not produce a complete designer report; that is a separate pending proposal
review issue, not evidence against this factory improvement.

## Revert condition

Revert the package-owned dispatch/event-ledger change only if a future
approved eval cannot run with its package evaluator alone, or a completed
controller child lacks its paired process-output events in `events.jsonl`.

## Next-cycle disposition

Validated. The next CTO may proceed after reviewing the incomplete
`task-probe` proposal and the failed design phase; no handbook promotion or
eval approval is implied.
