# CTO factory improvement

## Status

pending-validation

`pending-validation` means the CTO has already implemented this change. It is
not awaiting another approval; the next cycle verifies the named metric or
applies the safe inverse.

## Change

The eval-manager assignment now treats the candidate worktree as
controller-owned metadata and directs managers to use the structured phase
report, portable patch, evaluator manifest, artifact, review, and commit
evidence instead of reading a worktree that may have been cleaned. The
eval-manager wall ceiling is reduced from 1800 to 600 seconds. See
`templates/EVAL-MANAGER-ASSIGNMENT.md`, `factory/control.xsh`,
`tests/factory_control_test.xsh`, and `tests/tools_test.xsh`.

## Throughput requirement

Cycle 17 produced zero fresh engineer commits and zero delivered tickets;
classify it as a throughput failure. The next cycle has one fresh approved
product ticket (`task-dupcheck-002`) and one retained replay.

## Provider-health attribution

Provider telemetry was captured. The linked worker report records one fatal
DigitalOcean stream failure with zero provider retries; the manager report
classifies that as external provider health, not agent inefficiency. The
independent worker and manager completed without a provider retry signal.

## Baseline metric

Cycle 16 delivered 0/1 retained rows at $0.066628 and 61 turns. Cycle 17
delivered 0/1 retained rows at $0.046629 and 54 turns. Evidence:
`runs/run-1786197177807/report.json`.

## Target metric

At least one fresh engineer commit delivered, with
`fresh_engineer_rows >= 1`, `delivered_tickets >= 1`, and
`delivery_conversion >= 0.5`; independent `task-histogram` remains passing.

## Validation

Run `templates/ORGANIZATION-REQUEST-CYCLE-18.md`; verify the root
`report.json` throughput fields, linked replay required outputs, and
`git -C ../xsh log -1` after controller-owned delivery. Native validation:
`XSH_MODULE_PATH=. xsht test` (132/132 passed before this handoff).

## Revert condition

If the manager still attempts to read a cleaned worktree, or if a normal
manager closeout hits the 600-second ceiling before producing its report,
restore the prior 1800-second ceiling only after isolating the cause; keep the
metadata-only assignment rule.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted`
after cycle 18 and link the evidence before cycle 19.
