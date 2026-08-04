# CTO factory improvement

## Status

validated

## Change

Make the eval-designer admission boundary explicit before API exploration or
dry-run work. The assignment and role prompt now require the designer to replace
the copied `task-tags`/`Disabled.` scaffold with a new, valid `task-*` ID absent
from `evals/`, set it to `Draft.`, and verify that identity before continuing.
The native test `tests/tools_test.xsh::test_eval_design_stages_and_promotes_complete_package`
asserts that both prompt surfaces carry this rule.

Paths: `templates/EVAL-DESIGNER-ASSIGNMENT.md`, `roles/eval-designer.md`, and
`tests/tools_test.xsh`.

## Baseline metric

This cycle's design phase spent its bounded session with the scaffold still
identified as the retired `task-tags` eval (`Disabled.`), left the designer
report as `not-ready`, and correctly recorded `not-promoted` because
`evals/task-tags` already existed. Evidence:
`runs/run-1785777983535/phases/04-eval-design/CTO-EVAL-REVIEW.md`,
`runs/run-1785777983535/phases/04-eval-design/report.json`, and
`runs/run-1785777983535/phases/04-eval-design/workers/eval-designer/proposal-1/REPORT.md`.

## Target metric

The next organization cycle's eval-design phase must produce a designer report
with `Result` other than `not-ready`, and its materialized `EVAL.md` must have
an ID different from every existing `evals/*` directory. If the package passes
the remaining gates, `CTO-EVAL-REVIEW.md` must record `promoted` at that new
`evals/<id>` path; if it does not, the review must still explain the distinct
gate failure without an ID-collision failure.

## Validation

Run `XSH_MODULE_PATH=. xsht test` and the next standard organization request,
then inspect `phases/04-eval-design/report.json`, the designer `REPORT.md`,
`CTO-EVAL-REVIEW.md`, and the proposal/check-in ID relationship.

## Revert condition

Revert the prompt/test change if a later design run shows a valid new proposal
being rejected because of this instruction, or if an ID-unique proposal still
leaves the designer report at `not-ready` with no other gate evidence. Preserve
that run's evidence before applying the inverse.

## Next-cycle disposition

Validated by the next organization cycle. The designer produced a distinct
`task-setdiff` proposal with a complete `Draft.` package, and the CTO review
promoted it to `evals/task-setdiff` with `Approved.` status. Evidence:
`runs/run-1785781082105/phases/02-eval-design/workers/eval-designer/proposal-1/REPORT.md`
and `runs/run-1785781082105/phases/02-eval-design/CTO-EVAL-REVIEW.md`.
