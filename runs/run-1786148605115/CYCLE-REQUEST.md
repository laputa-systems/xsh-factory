# Cycle request: verify task-trim evaluator repair

## Objective

Run one bounded organization cycle to verify the repaired `task-trim`
restriction contract against the retained engineer implementation. Reuse the
existing `task-trim-001` branch; do not dispatch a duplicate engineer. Require
the linked replay to pass correctness and restrictions before delivery, and
overlap one different approved independent eval.

## Bottleneck review

The prior cycle reached a product-tested engineer commit but delivery stopped
at the replay/merge gate because `task-trim/evaluator.xsh` required a literal
`fs.` spelling and rejected valid typed-Path file I/O. The factory repair now
accepts both filesystem-module and typed-Path read/write surfaces. The target
is a green linked replay and delivery of the retained commit, with the
independent eval providing a separate health signal.

## Mode

- `organization`

## Eval admission

- Allow measured eval reuse: `yes`

## Active evals

- `task-setdiff`

## Trial plan

- Count: `1`

## New eval proposals

- Count: `0`

## Approved tickets

- `task-trim-001`

## Ticket policy

- Review every Open ticket before admission: `yes`
- Reuse the retained implementation branch for `task-trim-001`; do not
  dispatch another engineer.
- Require the linked `task-trim` replay before delivery.
- Require the independent `task-setdiff` eval as a separate pass/fail signal.

## Role overrides

Use the normal role defaults; no reduced-intensity overrides.

## Required outputs

- linked replay evidence using the repaired evaluator;
- independent `task-setdiff` discovery evidence;
- exact delivery decision for the retained engineer commit;
- structured phase/run reports and compressed sessions;
- CTO briefing, productivity report, and improvement handoff.
