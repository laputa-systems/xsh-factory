# Organization phase request

## Mode

- `eval`

## Active evals

- `task-render`

## Trial plan

- Count: `1`

## New eval proposals

- Count: `0`

## Approved tickets

- `task-render-001`

## Phase objective

Validate the task-render-001 implementation against the linked task-render eval before merge.

The organization controller owns final delivery for a passing product phase:
the linked replay must pass before the exact engineer provenance commit is
merged into XSH `HEAD`. A delivery check failure is a failed phase outcome and
must retain the implementation branch for review.
