# CTO factory improvement

## Status

validated

`pending-validation` means the CTO has already implemented this change. It is
not awaiting another approval; the next cycle verifies the named metric or
applies the safe inverse.

## Change

The prior-cycle hardening is validated. `factory/controllers/organization.xsh`
now waits for overlapping eval managers before controller-owned ticket
reconciliation; `factory/tools/audit.xsh` preserves product, evaluator, and
infrastructure outcome dimensions; and `tests/tools_test.xsh` covers both
ordering and aggregation. The read-only inspector remains at
`factory/tools/run-status.xsh`.

## Throughput requirement

Met. This cycle produced and delivered one fresh reviewable engineer commit,
`e4059a21`, for one admitted ticket (`1/1`, conversion `1.0`).

## Provider-health attribution

Captured. All six worker reports contain provider telemetry. The engineer had
one successful retry and the replay worker had one successful retry; neither
caused a budget failure, and the remaining closeout behavior was deterministic.

## Baseline metric

The prior cycle delivered `1/1` but ended with evaluator and infrastructure
failure because of the manager snapshot race
(`runs/run-1786168895521/report.json`). Its repaired machinery is the change
being validated here.

## Target metric

The next target is one fresh engineer delivery with conversion `1.0`, all three
outcome dimensions passing, and cycle cost at or below `$0.15`.

## Validation

After the next explicit organization request, run the canonical `run.xsh` path
and require `report.json` to show `data.throughput.fresh_engineer_rows >= 1`,
`delivered_tickets >= 1`, `delivery_conversion == 1.0`, and
`outcomes.product/evaluator/infrastructure == pass`; run `run-status.xsh` on
the explicit run directory and require no active processes at close.

## Revert condition

If a clean cycle again mutates a manager-visible ticket snapshot, disagrees
between phase and root outcome dimensions, or fails to expose a registered live
process, stop paid admission and repair/revert the affected ordering, audit, or
inspector change before another cycle.

## Next-cycle disposition

Validated by this run: `report.json`, `phases/01-ticket/report.json`,
`phases/02-reeval-task-bigfiles-003/report.json`,
`phases/03-eval/report.json`, and the final
`factory/tools/run-status.xsh -- --run-dir runs/run-1786170696452` output.
