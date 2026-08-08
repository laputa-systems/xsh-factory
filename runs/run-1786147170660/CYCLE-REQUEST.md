# Cycle request: trim diagnostic delivery

## Objective

Run one normal-intensity organization cycle with one fresh engineer ticket
and one independent discovery eval. Implement `task-trim-001`, replay its
linked eval before delivery, and overlap the independent `task-uniqcat` eval.

## Bottleneck review

Cycle 1 produced a strong, small diagnostic ticket from `task-trim` while the
retained pathparts branch remained blocked by a known lint/restriction conflict.
This cycle converts the fresh eval signal into an engineer implementation and
keeps the blocked pathparts branch out of admission.

## Mode

- `organization`

## Eval admission

- Allow measured eval reuse: `no`

## Active evals

- `task-uniqcat`

## Trial plan

- Count: `1`

## New eval proposals

- Count: `0`

## Approved tickets

- `task-trim-001`

## Ticket policy

- Review every Open ticket before admission: `yes`
- Select the approved ticket above: `yes`
- Require the linked `task-trim` replay before delivery.
- Require an independent helper-using eval replay before accepting the fix.

## Role overrides

Use the normal role defaults; no reduced-intensity overrides.

## Required outputs

- one validated engineer implementation row with provenance;
- linked `task-trim` replay evidence;
- one independent `task-uniqcat` discovery evidence packet;
- structured phase/run reports and compressed sessions;
- CTO briefing, productivity report, and improvement handoff.
