# CTO factory improvement

## Status

validated

## Change

Stage the eval-designer's proposal files and fail-closed narrative report
skeleton before the Pi session, then constrain the designer prompt to
materialize the proposal before dry-run exploration and finish the report
immediately afterward.

Paths: `run-design.xsh`, `templates/EVAL-DESIGNER-REPORT.md`,
`templates/EVAL-DESIGNER-ASSIGNMENT.md`, and `roles/eval-designer.md`.

## Baseline metric

The two preceding design phases failed because the designer reached its bound
without a narrative `REPORT.md`: `runs/run-1785722327478/phases/04-eval-design/report.json`
and `runs/run-1785723986829/phases/04-eval-design/report.json`.

## Target metric

The organization cycle `runs/run-1785728831509` produced a valid
`REPORT.md`, a staged proposal, and a passing phase report within the coded
720-second/64-turn bound, with no `REPORT-MISSING` marker. Evidence:
`runs/run-1785728831509/phases/04-eval-design/report.json` and
`runs/run-1785728831509/phases/04-eval-design/workers/eval-designer/proposal-1/REPORT.md`.

## Validation

Run the next organization cycle and inspect
`phases/04-eval-design/report.json`, the designer worker `report.json`, and
`workers/eval-designer/proposal-1/REPORT.md`. The required report must be
present and valid, and the phase result must be `pass`.

## Revert condition

Not triggered: the designer completed in 41 turns with zero tool errors and
the phase passed. Retain the scaffold/prompt change.

## Next-cycle disposition

Validated by the next organization cycle; retain for future cycles.
