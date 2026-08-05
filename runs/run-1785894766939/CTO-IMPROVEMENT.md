# CTO factory improvement

## Status

reverted

## Disposition

The previous rotation to `task-dupcheck` was not validated: its evaluator failed before producing a manifest because the container could not resolve `factory_control.xsh`. The safe inverse is to avoid that known-invalid package for this paid cycle and select the approved `task-histogram` package with explicit measured-reuse rationale. The merged `task-colsum-001` product change is retained; only the independent-eval rotation is reverted.

## Evidence

- `runs/run-1785894766939/phases/03-eval/CTO-REPORT.md` — missing evaluator manifest and module-load failure.
- `evals/task-findexec/evaluator.xsh` — legacy/shared dispatcher boundary remains invalid for the next-untried candidate.
- `evals/task-histogram/EVAL.md` — complete, Approved package selected for the safer independent trial.

## Change

The organization path admitted an evidence-backed ticket after the prior eval-only cycle: `task-colsum-001` was explicitly approved, dispatched, and its engineer/replay phases completed. The next-cycle eval rotation was also changed from `task-colsum` to the first live approved untried `task-dupcheck`, exposing a package-owned evaluator harness defect rather than silently reusing a saturated eval.

## Throughput requirement

The cycle produced one reviewable engineer implementation commit, `5f46267067991d5af1d988732e5c2f6f5de5ad04`, on `factory/task-colsum-001/1785894767724`; it was merged fast-forward into XSH `HEAD`. The linked `task-colsum` candidate replay passed all nine cases without the sentinel conversion. The independent `task-dupcheck` eval failed before its manifest because the evaluator container could not resolve `factory_control`.

## Provider-health attribution

Provider telemetry was present for all seven workers. Retries were zero; provider errors were unknown and response timing was unpopulated. The 17 recorded tool errors were agent-side workflow errors or evaluator packaging output, not provider retry evidence.

## Baseline metric

Prior run `runs/run-1785893827191/report.json`: zero engineer commits, 81 turns, and $0.048801. This run `runs/run-1785894766939/report.json`: one merged engineer commit, 225 turns, and $0.233828; product and linked replay passed, while the independent eval failed at the evaluator-container module boundary.

## Target metric

The next organization cycle must preserve at least one merged engineer commit and obtain a valid independent-eval manifest. Target cost is at or below $0.233828 unless a second product result is delivered. The independent evaluator must load its shared module successfully before the trial is counted as valid.

## Validation

Run `XSH_MODULE_PATH=. xsht test`, verify XSH `HEAD` is `5f46267067991d5af1d988732e5c2f6f5de5ad04`, run `XSH_MODULE_PATH=. xsh run-cto.xsh`, and inspect the next independent phase for `run.json` with `required_outputs.required: true`. The next cycle must also prove the prior `task-colsum` merged replay and reconcile `task-colsum-001` to `Merged.`.

## Revert condition

If the next run again has no independent evaluator manifest because `factory_control` is unavailable, repair the evaluator container/module mounting before further paid eval work; do not revert the validated product merge. If the linked replay fails, inspect and safely revert the product commit only if the failure is attributable to this change.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted` after running the named verification and link the evidence before admitting paid work.
