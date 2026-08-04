# Cycle request: factory prompt efficiency comparison

## Objective

Run one bounded `task-envcfg` trial for the HEAD~1 factory revision and one
matching trial for the current HEAD revision. Compare correctness, protocol,
restrictions, candidate timing, assistant turns, token buckets, thinking
blocks, tool calls, tool errors, wall span, and cost. Treat correctness and
clarity as gates before interpreting lower effort as an improvement.

The HEAD~1 arm is the baseline. The current HEAD arm contains the latest
Englishlint-driven role and briefing edits. Do not modify XSH, the evaluator,
the task, or the approved handbook during either trial. Do not dispatch an
engineer, designer, or new eval proposal.

## Mode

- `eval`

## Active evals

- `task-envcfg`

## Trial plan

- Count: `1`

## New eval proposals

- Count: `0`

## Approved tickets

- None.

## Aggregate budget

- Cap: `$0.50` per comparison arm.

## Required outputs

- one complete HEAD~1 baseline eval with worker and manager evidence;
- one complete current-HEAD eval with worker and manager evidence;
- evaluator manifests and structured reports for both arms;
- a CTO comparison handoff naming the measured deltas and uncertainty;
- no product merge, handbook promotion, ticket approval, or designer phase.
