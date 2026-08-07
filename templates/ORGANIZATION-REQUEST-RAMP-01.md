# Cycle request: discovery ramp 01

## Objective

Run one bounded organization discovery cycle. All reviewed Open tickets remain
deferred pending their named replay or cross-eval gate, so no engineer ticket
is admitted in this discovery batch.

## Mode

- `organization`

## Eval admission

- Allow measured eval reuse: `no`
- Select exactly the next four deterministic untried Approved evals.

## Active evals

- `task-grep`
- `task-groupsum`
- `task-iniget`
- `task-intsum`

## Trial plan

- Count: `1`

## New eval proposals

- Count: `0`

## Approved tickets

- None.

## Ticket policy

- Review all open tickets before selection: `yes`
- Select the first two approved tickets after review: no eligible tickets in
  this discovery batch.

## Required outputs

- four independent eval phases with structured worker reports and raw sessions;
- a run-level `report.json` covering every worker;
- `CTO-IMPROVEMENT.md`, `CTO-PRODUCTIVITY-REPORT.md`, and `CTO-REPORT.md`.
