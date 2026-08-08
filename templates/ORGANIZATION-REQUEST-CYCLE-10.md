# Cycle request: retained histogram delivery with bounded manager tools

Run one bounded organization cycle after run-1786180918894. Deliver the
reviewed retained `task-histogram-004` engineer commit through the reuse path.
This cycle validates the manager tool allowlist and the corrected retained-fast
path accounting while continuing the hard one-commit-per-cycle goal.

## Bottleneck review

The previous cycle delivered one retained engineer commit and passed every
outcome gate. Its managers still used shell discovery despite the structured
evidence contract, and the audit omitted a retained row when reuse occupied
the `01-ticket` primary phase. The factory now restricts eval-manager tools to
`read,write,edit` and counts any direct phase report marked `fast_path`.

## Mode

- `organization`

## Eval admission

- Allow measured eval reuse: `yes`

## Active evals

- `task-histogram`

## Trial plan

- Count: `1`

## New eval proposals

- Count: `0`

## Approved tickets

- `task-histogram-004`

## Ticket policy

- Review all open tickets before selection: `yes`
- Reuse the existing `task-histogram-004` implementation branch; do not
  dispatch a duplicate engineer row.
- `Open.` tickets are never promoted by the controller.

## Role overrides

Use the defaults codified by the factory. The adaptive queue should use the
current open-ticket pressure when allocating the independent eval.

## Required outputs

- one retained engineer commit delivered;
- linked replay and one independent eval both pass;
- linked replay `manager_report`, `candidate_handbook`, and `handbook_lineage`
  are all true;
- eval-manager worker reports contain no shell-tool rows (`bash`, `ls`, `find`,
  or `grep`), and the retained throughput projection reports one row;
- `ticket_snapshot_unchanged: true`, structured reports, raw sessions, and a
  run-level `report.json`;
- product, evaluator, infrastructure, and overall cycle outcomes.
