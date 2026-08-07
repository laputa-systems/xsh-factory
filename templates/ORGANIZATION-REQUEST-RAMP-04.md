# Cycle request: pathparts delivery and render discovery

## Objective

Replay the retained `task-pathparts-001` implementation and run one fresh
independent `task-render` eval. Deliver the engineer commit only if the linked
replay clears correctness, restrictions, and manager evidence gates.

## Mode

- `organization`

## Eval admission

- Allow measured eval reuse: `no`

## Active evals

- `task-render`

## Trial plan

- Count: `1`

## New eval proposals

- Count: `0`

## Approved tickets

- `task-pathparts-001`

## Ticket policy

- Review all open tickets before selection: `yes`
- Select the explicitly named approved ticket: `yes`
- Require the linked `task-pathparts` replay to pass before delivery.
- Keep `task-pathparts-002` deferred; it requires a separate lint/restriction
  repair.

## Role overrides

Use the normal role defaults; no reduced-intensity overrides.

## Required outputs

- retained-branch engineer replay and delivery decision;
- one independent `task-render` discovery evidence packet;
- run/phase reports, CTO briefing, productivity report, and improvement
  handoff.
