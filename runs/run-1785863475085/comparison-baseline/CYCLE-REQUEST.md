# Cycle request: second factory prompt efficiency comparison

## Objective

Run a second matched comparison of the pre-Englishlint factory prompts and the
Englishlint-shortened prompts. Use exact factory revisions `6c5836b` and
`4d41409` as the baseline and current arms. Run one bounded `task-envcfg` trial
per arm with the same product checkout, handbook, evaluator, task, and role
budgets.

Compare correctness, protocol, restrictions, candidate timing, assistant turns,
token buckets, thinking blocks, tool calls, tool errors, wall span, and cost.
Treat correctness and report completeness as gates before interpreting effort.
Report worker and manager metrics separately and do not claim causality from
one additional pair of stochastic trials.

Do not modify XSH, the evaluator, the task, or the approved handbook during the
trials. Do not dispatch an engineer, designer, or new eval proposal. The CTO
has dispositioned the prior handbook candidate as deferred in the ledger.

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

- one complete baseline eval from `6c5836b`;
- one complete current eval from `4d41409`;
- evaluator manifests and structured worker and manager reports for both arms;
- a CTO comparison handoff with deltas from both matched pairs;
- no product merge, handbook promotion, ticket approval, or designer phase.
