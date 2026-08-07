# Cycle request: discovery ramp 03

## Objective

Run one bounded organization discovery cycle over a third distinct eval batch.
Open tickets remain deferred pending their recorded replay gates; do not
dispatch an engineer unless the controller's admission inventory changes.

## Mode

- `organization`

## Eval admission

- Allow measured eval reuse: `no`
- Select exactly the next four deterministic untried Approved evals.

## Active evals

- `task-renamex`
- `task-render`
- `task-revrank`
- `task-safepath`

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
