# Cycle request: replay recovery after ramp

## Objective

Validate the repaired ticket-cycle phase boundary and the strengthened
eval-manager handbook-read contract using the retained `task-jsonfilter-001`
branch. Keep `task-pathparts-001` isolated until its restriction failure is
resolved and reviewed.

## Mode

- `organization`

## Eval admission

- Allow measured eval reuse: `no`
- Select the next untried Approved eval: `task-render`

## Active evals

- `task-render`

## Trial plan

- Count: `1`

## New eval proposals

- Count: `0`

## Approved tickets

- `task-jsonfilter-001`

## Ticket policy

- Review all open tickets before selection: `yes`
- Select the first two approved tickets after review: no; admit only
  `task-jsonfilter-001` for recovery.
- Approve eligible Open tickets before engineer dispatch: `required`
- Require the linked replay to pass before delivering the retained engineer
  commit.

## Role overrides

Use the normal role defaults; no reduced-intensity overrides.

## Required outputs

- one retained-branch replay with worker, evaluator, and manager evidence;
- one independent `task-render` discovery evidence packet;
- run/phase reports, CTO briefing, productivity report, and improvement
  handoff.
