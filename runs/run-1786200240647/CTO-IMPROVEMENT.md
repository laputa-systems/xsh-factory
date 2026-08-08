# CTO factory improvement

## Status

pending-validation

## Change

`factory/control.xsh::ticket_api_surface_gate_ok` now accepts either a
`semantic` or `capability` claim, while retaining the required `existing` and
`evidence` checks. `tests/factory_control_test.xsh` covers both spellings.

## Throughput requirement

Cycle 19 produced zero engineer rows because admission failed before paid
work. The next request uses the same approved tickets after this validator
repair and must deliver one fresh engineer commit.

## Provider-health attribution

No provider or worker telemetry exists: no paid worker was admitted.

## Baseline metric

Cycles 18 and 19 both delivered 0 tickets before paid work due admission
contract defects.

## Target metric

Cycle 20: `fresh_engineer_rows >= 1` and `delivered_tickets >= 1`.

## Validation

Run `templates/ORGANIZATION-REQUEST-CYCLE-20.md`; check root throughput fields
and XSH `HEAD` after 133/133 native tests pass.

## Revert condition

If an API-surface ticket without `semantic` but with a concrete capability,
existing-surface comparison, and evidence is admitted incorrectly, restore the
strict predicate and revise the ticket contract. Otherwise keep the broader
wording acceptance.

## Next-cycle disposition

Replace `pending-validation` with `validated` or `reverted` after cycle 20.
