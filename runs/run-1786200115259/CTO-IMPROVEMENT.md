# CTO factory improvement

## Status

pending-validation

## Change

Completed the approved dupcheck ticket's API-surface justification with
explicit evidence, and changed `factory/controllers/organization.xsh` to
report API-surface gate failures separately from missing approval. Added a
native contract test in `tests/tools_test.xsh`.

## Throughput requirement

Cycle 18 produced zero engineer rows because admission failed before paid
work. The next request retries with the corrected ticket and must deliver one
fresh engineer commit.

## Provider-health attribution

No provider or worker telemetry exists: no paid worker was admitted.

## Baseline metric

Cycle 17 delivered 0 tickets after 4 workers and 54 turns. Cycle 18 delivered
0 tickets with 0 workers because admission rejected the ticket contract.

## Target metric

Cycle 19: `fresh_engineer_rows >= 1` and `delivered_tickets >= 1`.

## Validation

Run `templates/ORGANIZATION-REQUEST-CYCLE-19.md`; check the root throughput
fields and XSH `HEAD`, after `XSH_MODULE_PATH=. xsht test` passes.

## Revert condition

If the corrected ticket is rejected despite the evidence marker, stop and
repair the ticket/API-surface contract before paid work; do not weaken the
gate.

## Next-cycle disposition

Replace `pending-validation` with `validated` or `reverted` after cycle 19.
