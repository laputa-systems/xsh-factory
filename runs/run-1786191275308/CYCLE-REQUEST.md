# Cycle request: fresh hidden-file API documentation delivery

Run one bounded organization cycle after `run-1786189018376`. Cycle 13
delivered the retained `task-bigfiles-002` implementation, but its independent
manager ended before completing the narrative report. Cycle 14 must dispatch a
fresh engineer for the next approved product ticket and validate the
controller-owned manager retry path.

## Bottleneck review

Cycle 13 delivered one ticket with `delivery_conversion=1.0`; product outcome
passed. The remaining failure was evaluator closeout:
`phases/03-eval/required-outputs.json` recorded `manager_report=false` after a
manager `stopReason=error`. The factory now preserves attempt-1 manager
evidence, retries once under a distinct worker identity, and promotes only a
complete retry report.

## Mode

- `organization`

## Eval admission

- Allow measured eval reuse: `yes`

## Active evals

- `task-bigfiles`

## Trial plan

- Count: `1`

## New eval proposals

- Count: `0`

## Approved tickets

- `task-bigfiles-004`

## Ticket policy

- Review all open tickets before selection: `yes`
- Dispatch exactly the explicitly approved fresh ticket above.
- Dispatch one fresh engineer implementation row; do not reuse the merged
  `task-bigfiles-002` branch.

## Required outputs

- at least one fresh engineer implementation commit delivered into XSH HEAD;
- linked replay and one independent eval pass;
- root `report.json` with `fresh_engineer_rows >= 1`,
  `delivered_tickets >= 1`, and `delivery_conversion=1.0`;
- every eval phase has `required=true` and `manager_report=true`;
- any manager recovery emits at most one `81-manager-retry-*` sequence per
  phase and preserves attempt-1 evidence;
- terminal lifecycle and `run-status` both report pass.
