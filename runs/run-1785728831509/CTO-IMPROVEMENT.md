# CTO factory improvement

## Status

validated

## Change

Persist a deterministic `required-outputs.json` gate ledger from every eval
controller, recording each final requirement and the aggregate `required`
decision. This makes a child exit/report mismatch diagnosable without replaying
paid work. Paths: `run-eval.xsh`, `tests/tools_test.xsh`.

## Baseline metric

This cycle's candidate re-evaluation returned a failed child status even though
its final phase `report.json` was `pass`; the false gate was not recorded. See
`runs/run-1785728831509/reeval.stdout` and
`runs/run-1785728831509/phases/02-reeval/report.json`.

## Target metric

The next cycle emitted one valid `required-outputs.json` per eval phase. The
successful independent phase has every gate true; the failed candidate replay
identifies `trial1_process: false` and `audit: false` without paid replay:
`runs/run-1785731807794/phases/02-reeval/required-outputs.json` and
`runs/run-1785731807794/phases/03-eval/required-outputs.json`.

## Validation

Validation passed by inspection of both phase ledgers. Retain the diagnostic
ledger change.

## Revert condition

Not triggered: both ledgers are valid and the failed replay identifies its
false gates.

## Next-cycle disposition

Validated by `runs/run-1785731807794`; retain for future cycles.
