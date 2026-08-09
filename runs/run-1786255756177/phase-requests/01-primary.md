# Organization phase request

## Mode

- `ticket-implementation`

## Active evals

- `task-envcfg`

## Trial plan

- Count: `1`

## New eval proposals

- Count: `0`

## Approved tickets

- `task-envcfg-008`

## Phase objective

Implement the approved ticket rows `task-envcfg-008` in isolated XSH worktrees; every passing engineer row receives a linked pre-merge replay.

The organization controller owns final delivery for a passing product phase:
the linked replay must pass before the exact engineer provenance commit is
merged into XSH `HEAD`. A delivery check failure is a failed phase outcome and
must retain the implementation branch for review.
