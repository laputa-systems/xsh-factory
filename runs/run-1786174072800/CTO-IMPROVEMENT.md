# CTO factory improvement

## Status

pending-validation

`pending-validation` means the CTO has already implemented this change. It is
not awaiting another approval; the next cycle verifies the named metric or
applies the safe inverse.

## Change

Raised the eval-manager wall-clock ceiling from 900 to 1,200 seconds in
`factory/control.xsh`. Tightened `templates/EVAL-MANAGER-ASSIGNMENT.md` so
structured evidence is the default and raw session JSONL is consulted only for
discrepancies; the report must be drafted as soon as structured evidence is
available. The prompt contract and limit are covered by
`tests/factory_control_test.xsh`.

## Throughput requirement

The cycle produced one reviewable but zero delivered engineer commits. This is
a throughput failure because an eligible approved ticket existed; the
preserved commit is `f697fa2453f676f686c685171f5a8a9d514f871e`.

## Provider-health attribution

Telemetry was captured. The independent eval had one successful provider retry;
the replay manager had no provider error but exceeded the role wall-clock
ceiling, so this failure is classified as closeout/session-budget pressure,
not an agent regression.

## Baseline metric

Prior cycle: 1 delivered commit, $0.172625, 144 turns, pass at
`runs/run-1786170696452/report.json`.

## Target metric

Next cycle: at least 1 delivered engineer commit, a valid manager report, and
all three outcome dimensions pass.

## Validation

Validate `throughput.delivered_tickets >= 1`, retained delivery evidence,
`required-outputs.json` manager_report=true, and root
`outcomes.infrastructure=pass` in the next `report.json`.

## Revert condition

If a manager still reaches its limit or if the longer ceiling materially
increases cycle cost without a completed report, tighten the assignment further
and revert the ceiling change to 900 seconds.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted`
after running the named verification, and link the evidence before admitting
paid work.
