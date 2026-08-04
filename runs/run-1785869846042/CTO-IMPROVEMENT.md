# CTO factory improvement

## Status

pending-validation

`pending-validation` means the CTO has already implemented this change. It is
not awaiting another approval; the next cycle verifies the named metric or
applies the safe inverse.

## Change

The eval-manager contract now tells managers to use the controller-supplied
absolute handbook lineage path directly, and the native contract test asserts
that this instruction remains present:

- `roles/eval-manager.md`
- `templates/EVAL-MANAGER-ASSIGNMENT.md`
- `tests/factory_control_test.xsh`

This removes avoidable relative-path reconstruction when managers verify the
approved handbook snapshot.

## Baseline metric

The current organization cycle's `task-envcfg` manager produced one tool error
from reconstructing the supplied lineage path from its worker directory:
`runs/run-1785869846042/phases/01-eval/workers/eval-manager/task-envcfg/report.json`
(turn 5, `No such file or directory`). The worker and manager phase had one
manager-side path error among four total cycle tool errors; the eval still
passed.

## Target metric

In the next organization or eval cycle that dispatches an eval-manager, the
manager's structured `tool_errors` must contain zero path-construction failures
for `handbook-approved.md`, while the phase remains report-complete and the
eval correctness result remains `pass`.

## Validation

Run `XSH_MODULE_PATH=. xsht test` and inspect the next manager
`report.json`/`REPORT.md`. Confirm the assignment contains the absolute-path
instruction and that no current tool error reports a missing or incorrectly
constructed `lineage/handbook-approved.md` path.

## Revert condition

If a subsequent manager session still reports a lineage-path construction
failure despite the instruction, or if the wording causes a report-completeness
or correctness regression, revert the three scoped changes and retain the
native test only if it remains independently useful.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted`
after running the named verification, and link the evidence before admitting
paid work.
