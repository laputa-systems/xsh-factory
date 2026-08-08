# Cycle request: fresh bigfiles API-reference delivery

Run one bounded organization cycle after run-1786183310798. The adaptive queue
has no retained approved branches and six open product observations, so approve
and dispatch exactly one fresh `task-bigfiles-002` engineer row. The linked
replay must exercise the documented command-word `sort-by` spelling before the
commit can be delivered.

## Bottleneck review

Cycle 10 delivered one retained commit and validated manager tool restriction
and retained-row accounting. Its linked manager also exposed a quality gap:
the controller previously delivered candidate fixes even when the manager said
acceptance was not exercised. Candidate-linked delivery now fails closed on
`needs-replay`, `not supported`, and `not exercised` evidence.

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
- Dispatch exactly the explicitly approved fresh ticket above.
- `Open.` tickets are never promoted by the controller.

## Role overrides

Use the defaults codified by the factory. The adaptive queue should use the
current open-ticket pressure when allocating the independent eval.

## Required outputs

- one fresh engineer implementation commit reviewed;
- linked replay and one independent eval both pass;
- linked manager candidate acceptance is explicit and exercised, with no
  `needs-replay`, `not supported`, or `not exercised` finding;
- `ticket_snapshot_unchanged: true`, structured reports, raw sessions, and a
  run-level `report.json`;
- product, evaluator, infrastructure, and overall cycle outcomes.
