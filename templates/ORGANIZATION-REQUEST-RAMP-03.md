# Cycle request: discovery ramp 03 with delivery

## Objective

Run the final cycle of the ramp with two approved product tickets in parallel
with their linked replays and one fresh independent discovery eval. Preserve
the evaluator false-negative signal from `task-propsort` as evidence, not a
product ticket.

## Bottleneck review

The current throughput bottleneck is the shared `runs/eval-build.lock`: four
eval controllers overlap, but each phase rebuilds the product image before its
worker can start. This cycle measures delivery and signal while preserving the
same bounded aggregate budget; a shared-build/cache change is the next
infrastructure action after the ramp evidence closes.

## Mode

- `organization`

## Eval admission

- Allow measured eval reuse: `no`
- Select the next untried Approved eval: `task-renamex`

## Active evals

- `task-renamex`

## Trial plan

- Count: `1`

## New eval proposals

- Count: `0`
- The checked-in eval portfolio is at the coded cap; do not design or promote
  another package in this cycle.

## Approved tickets

- `task-jsonfilter-001`
- `task-pathparts-001`

## Ticket policy

- Review all open tickets before selection: `yes`
- Select the first two approved tickets after review: `yes`
- Approve eligible Open tickets before engineer dispatch: `required`
- Require each linked replay to pass before its engineer commit is delivered.
- Require API-surface justification and CTO approval for any new XSH API
  proposal.

## Role overrides

Use the normal role defaults; no reduced-intensity overrides.

## Required outputs

- two validated engineer implementation rows and amended commit provenance;
- linked `task-jsonfilter` and `task-pathparts` replay evidence;
- one independent `task-renamex` discovery evidence packet;
- run/phase reports, CTO briefing, productivity report, and improvement
  handoff.
