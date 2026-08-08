# Cycle request: pathparts replay throughput

## Objective

Run one normal-intensity organization cycle. Reuse the approved retained
`task-pathparts-001` implementation branch, run its linked replay before
delivery, and overlap one independent fresh `task-trim` eval.

## Bottleneck review

The retained pathparts branch is an existing engineer implementation awaiting
replay after its earlier restriction failure. This cycle measures whether it
can be delivered without another implementation row; a failed replay must
retain the branch and produce evidence for the next CTO decision.

## Mode

- `organization`

## Eval admission

- Allow measured eval reuse: `no`

## Active evals

- `task-trim`

## Trial plan

- Count: `1`

## New eval proposals

- Count: `0`

## Approved tickets

- `task-pathparts-001`

## Ticket policy

- Review every Open ticket before admission: `yes`
- Select the approved ticket above: `yes`
- Require the linked `task-pathparts` replay before delivery.
- Preserve the branch if replay or delivery fails.

## Role overrides

Use the normal role defaults; no reduced-intensity overrides.

## Required outputs

- linked `task-pathparts` replay evidence;
- one independent `task-trim` discovery evidence packet;
- structured phase/run reports and compressed sessions;
- CTO briefing, productivity report, and improvement handoff.
