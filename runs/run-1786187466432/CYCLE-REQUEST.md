# Cycle request: retained bigfiles delivery validation

Run one bounded organization cycle after run-1786185105660. The prior cycle
produced a valid engineer commit and passing linked replay but delivered zero
because organization incorrectly required the linked controller process exit
to be zero even when its phase report passed. Cycle 12 must replay and deliver
the retained `task-bigfiles-002` branch through the repaired report-bound gate.

## Bottleneck review

Cycle 11 had one fresh engineer row, six workers, cost $0.079799, and zero
delivered commits. The linked phase report passed and the manager explicitly
accepted the candidate, but the child controller returned nonzero after a
recoverable image/tool subprocess event. The factory now preserves that exit
status while using the passing phase report as the delivery gate. Audit and
run-status tests also cover the terminal failure projection.

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

- `task-bigfiles-002`

## Ticket policy

- Review all open tickets before selection: `yes`
- Dispatch exactly the explicitly approved retained ticket above.
- Reuse its existing implementation branch; do not dispatch a duplicate
  engineer row.

## Required outputs

- retained engineer implementation commit delivered into XSH HEAD;
- linked replay and one independent eval pass;
- root `report.json` with `delivered_tickets=1` and
  `delivery_conversion=1.0`;
- terminal lifecycle and `run-status` both report pass;
- structured reports, raw sessions, lifecycle ledger, and ticket snapshot
  evidence preserved.
