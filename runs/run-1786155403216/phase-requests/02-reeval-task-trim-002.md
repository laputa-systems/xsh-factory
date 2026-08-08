# Organization phase request

## Mode

- `eval`

## Active evals

- `task-trim`

## Trial plan

- Count: `1`

## New eval proposals

- Count: `0`

## Approved tickets

- `task-trim-002`

## Phase objective

Validate the task-trim-002 implementation against the linked task-trim eval before merge.

The organization controller owns final delivery for a passing product phase:
the linked replay must pass before the exact engineer provenance commit is
merged into XSH `HEAD`. A delivery check failure is a failed phase outcome and
must retain the implementation branch for review.
