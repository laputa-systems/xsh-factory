# Cycle request: task-ecount candidate replay

## Objective

Replay the approved task-ecount eval against the exact unmerged
task-ecount-003 implementation branch. The candidate branch is supplied by
the controller invocation; do not dispatch an engineer or modify XSH main.
The eval-manager must compare the candidate result with the task's oracle,
inspect the implementation's reported evidence, and decide whether the ticket
is ready for top-level merge review.

## Mode

- `eval`

## Active evals

- `task-ecount`

## Trial plan

- Count: `1`

## New eval proposals

- Count: `0`

## Approved tickets

- None.

## Required outputs

- one task-ecount eval-manager and eval-worker replay against the supplied
  candidate branch;
- candidate and oracle correctness and timing evidence;
- manager judgment on task-ecount-003 acceptance and any handbook or ticket
  follow-up;
- aggregate cost, provenance, audit, and CTO reports;
- no engineer dispatch, merge, or handbook promotion.
