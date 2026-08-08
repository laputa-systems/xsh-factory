# CTO factory improvement

## Status

pending-validation

## Change

`factory/control.xsh::ticket_api_surface_gate_ok` now lowercases the
justification before checking for a `semantic` or `capability` claim plus the
required `existing` and `evidence` terms. A native test reads
`tickets/task-dupcheck-002.md` and asserts its admission gate passes.

## Throughput requirement

Cycle 20 produced zero engineer rows because admission failed before paid
work. The next request must deliver one fresh engineer commit.

## Provider-health attribution

No provider or worker telemetry exists: no paid worker was admitted.

## Baseline metric

Cycles 18–20 delivered 0 tickets before paid work due admission contract
defects.

## Target metric

Cycle 21: `fresh_engineer_rows >= 1` and `delivered_tickets >= 1`.

## Validation

Run `templates/ORGANIZATION-REQUEST-CYCLE-21.md`; check root throughput fields
and XSH `HEAD` after the native suite passes.

## Revert condition

If the normalized gate admits a ticket lacking a meaningful capability,
existing-surface, and evidence explanation, restore strict validation and
expand the contract test. Otherwise keep the normalization.

## Next-cycle disposition

Replace `pending-validation` with `validated` or `reverted` after cycle 21.
