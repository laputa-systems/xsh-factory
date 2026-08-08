# Cycle request: discriminating replay with retained delivery

Run one bounded organization cycle after `runs/run-1786220380763`. Cycle 30
correctly held the parser-consistency branch because its linked replay did not
exercise the defining whitespace behavior. The evaluator now has a padded-width
case, and the manager contract separates primary native-test evidence from
replay-owned external behavior.

## Bottleneck review

Deliver the retained `task-histogram-010` engineer implementation through its
repaired ten-case linked replay. The replay remains a hard gate for the exact
candidate behavior and restriction/protocol boundary. Native parser/API tests
remain primary engineer evidence and must not be redundantly demanded from
the evaluator sandbox. The independent eval lane is allocated by queue
pressure; with no Open tickets and one retained row, one independent eval is
appropriate.

## Mode

- `organization`

## Eval admission

- Allow measured eval reuse: `yes`
- Use adaptive independent-eval selection.

## Active evals

- Auto.

## Trial plan

- Count: `1`

## New eval proposals

- Count: `0`
- The checked-in eval portfolio is at the coded cap; do not design or promote
  another package in this cycle.

## Approved tickets

- `task-histogram-010`

## Ticket policy

- Review every Open ticket before admission: `yes`
- Replay the retained branch against all ten `task-histogram` cases,
  including `hidden_padded_width`.
- Require the linked replay's correctness, restriction, protocol, manager, and
  provenance gates before delivery.
- Use the primary engineer report for native parser/API test evidence; do not
  require the replay worker to duplicate the native suite.
- Deliver the retained implementation commit or preserve the branch with an
  explicit bounded defer event.

## Role overrides

Use adaptive defaults codified by the factory. Do not dispatch a duplicate
engineer row for the existing implementation branch.

## Required outputs

- the retained engineer implementation commit delivered, or an explicit
  retained-replay defer with the branch preserved;
- repaired linked replay evidence with the padded-width case visible;
- one independent eval selected by the queue-pressure policy;
- unchanged ticket snapshot, structured reports, raw sessions, patches,
  provenance trailers, and run-level `report.json`;
- product, evaluator, infrastructure, and overall cycle outcomes;
- `CTO-PRODUCTIVITY-REPORT.md` and `CTO-IMPROVEMENT.md` completed.
