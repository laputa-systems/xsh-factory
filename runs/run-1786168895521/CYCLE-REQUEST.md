# Cycle request: post-aggregation-repair organization

Run one bounded organization cycle after the run-evidence aggregation repair.
The controller applies the existing queue-pressure policy, reuses the
approved `task-pathparts-002` branch for its linked replay, and runs one
independent eval alongside product work.

## Bottleneck review

The previous cycle's engineer and evaluator workers passed, but delivery was
blocked by a factory audit that rejected a per-case correctness manifest.
This request validates the repaired audit and live-process introspection while
preserving the one-engineer-delivery gate.

## Mode

- `organization`

## Eval admission

- Allow measured eval reuse: `yes`

## Active evals

- Auto.

## Trial plan

- Count: 1

## New eval proposals

- Count: 0

## Approved tickets

- Auto.

## Ticket policy

- Review all open tickets before selection: yes
- Select the approved ticket after review; do not promote an Open ticket.
- The retained `task-pathparts-002` branch may be reused for linked replay.

## Role overrides

Use the defaults codified by the factory.

## Required outputs

- one engineer implementation or validated retained delivery row;
- one linked replay and one independent eval;
- structured reports, raw sessions, and a run-level `report.json`;
- one CTO improvement handoff and productivity report;
- product, evaluator, infrastructure, and overall cycle outcomes.
