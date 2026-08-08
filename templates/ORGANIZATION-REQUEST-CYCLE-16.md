# Cycle request: directed bigfiles delivery with observable hidden entries

Run one bounded organization cycle after `run-1786193695508`. Cycle 15
correctly retained `task-bigfiles-004` because its linked worker passed the
existing nine cases without exercising the candidate's documented `hidden`
behavior. Cycle 16 must replay and deliver the retained branch after the
package-owned evaluator was strengthened with a dot-prefixed regular file in
the existing `hidden_default` case.

## Bottleneck review

Cycle 15 cost $0.042017 across four workers and 53 turns. The independent eval
passed and its manager report was recovered by the retry path. The linked
manager explicitly recorded `candidate acceptance not exercised`; its worker
used `fs.files(root, stat: true)` without `hidden: true`, while all nine old
fixtures lacked dot entries. The eval now includes `.hidden-note`, preserving
the nine-case count but making the documented acceptance behavior observable.

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
- linked `hidden_default` includes `.hidden-note` and remains byte-exact;
- linked replay `candidate_acceptance=true`, `manager_report=true`, and
  `required=true`;
- root `report.json` with `delivered_tickets >= 1`,
  `delivery_conversion=1.0`, and `fresh_engineer_rows=0`;
- every eval phase has `required=true` and `manager_report=true`;
- terminal lifecycle and `run-status` both report pass;
- structured reports, raw sessions, lifecycle ledger, and ticket snapshot
  evidence preserved.
