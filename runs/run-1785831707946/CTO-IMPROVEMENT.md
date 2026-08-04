# CTO factory improvement

## Status

pending-validation

## Change

Tightened the eval-designer role and assignment with a hard stop after package
and evaluator syntax are valid. The prompt now forbids building localized
evaluators, negative-control harnesses, custom oracle runners, and historical
package investigations, and requires the report to be written immediately
without claiming unsaved dry-run evidence. Paths: `roles/eval-designer.md`,
`templates/EVAL-DESIGNER-ASSIGNMENT.md`, with native assertions in
`tests/tools_test.xsh`.

## Baseline metric

The two preceding organization cycles spent 45 and 23 designer turns and
failed to produce a valid narrative report. The first designer built an
unsaved host-local dry-run harness; the second abandoned the staged
`task-keyjoin` proposal after 23 turns to design a different task and debug a
candidate. Evidence: `runs/run-1785830554385/phases/02-eval-design/workers/eval-designer/proposal-1/report.json` and
`runs/run-1785831707946/phases/02-eval-design/workers/eval-designer/proposal-1/report.json`.

## Target metric

On the next eval-design admission, the designer reaches a valid
`ready-for-review` report or an honest `not-ready` report within 16 assistant
turns, without inspecting historical runs or creating unsaved dry-run
infrastructure.

## Validation

Run the next bounded eval-design or organization cycle and inspect the
normalized designer report: `result` must be `ready-for-review` for a complete
proposal, or the report must preserve `not-ready` while identifying the exact
remaining gap; `assistant_turns` must be <= 16 and the session must not contain
localized evaluator / custom-runner work.

## Revert condition

If the next two comparable designer sessions still spend more than 16 turns
or fail to produce a substantive report because the hard-stop wording blocks
necessary package work, revert the new prompt restrictions and retain the
prior contract while preserving the evidence.

## Next-cycle disposition

Pending validation by the next CTO pass before another paid cycle.
