# Cycle request: retained bigfiles delivery with explicit dot-file scope

Run one bounded organization cycle after `run-1786195596255`. Cycle 16
strengthened the evaluator with `.hidden-note`, but the worker-facing task
text did not say dot-prefixed regular files were in scope. Both trials then
failed `hidden_default` with an artifact that omitted `hidden: true`. Cycle 17
must replay and deliver the retained branch after the task contract repair.

## Bottleneck review

Cycle 16 cost $0.066628 across four workers and 61 turns. The linked and
independent managers both identified the same general hidden-entry gap; the
linked candidate remains unmerged. The task contract now explicitly requires
dot-prefixed directories and regular files, while the evaluator retains the
same nine cases and `.hidden-note` fixture.

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
- Dispatch exactly the explicitly approved retained ticket above.
- Reuse implementation branch `factory/task-bigfiles-004/1786191276307`;
  do not dispatch a duplicate engineer row.

## Required outputs

- at least one retained engineer implementation commit delivered into XSH HEAD;
- linked replay and one independent eval pass;
- both workers satisfy the explicit dot-file task contract;
- linked replay `candidate_acceptance=true`, `manager_report=true`, and
  `required=true`;
- root `report.json` with `delivered_tickets >= 1`,
  `delivery_conversion=1.0`, and `fresh_engineer_rows=0`;
- every eval phase has `required=true` and `manager_report=true`;
- terminal lifecycle and `run-status` both report pass;
- structured reports, raw sessions, lifecycle ledger, and ticket snapshot
  evidence preserved.
