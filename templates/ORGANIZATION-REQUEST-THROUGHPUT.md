# Throughput organization request

## Objective

Run one normal-intensity organization cycle that overlaps product delivery
with fresh ticket discovery. Dispatch the approved histogram implementation
while an independent `task-dupcheck` eval searches for the next evidence-backed
product observations. Review every Open ticket before admission; approve no
additional ticket without its own evidence and quality gate.

## Bottleneck review

The previous cycle restored the feed by approving `task-histogram-003`, but it
was eval-only because approval happened during closeout. This cycle moves the
bottleneck to concurrent delivery plus signal generation: one engineer should
implement the approved diagnostic ticket while the independent eval-manager
classifies new observations and may create durable product tickets. The next
untried Approved eval is `task-dupcheck`, so it is the independent signal.

## Mode

- `organization`

## Eval admission

- Allow measured eval reuse: `no`
- Select the next untried Approved eval: `task-dupcheck`

## Active evals

- `task-dupcheck`

## Trial plan

- Count: `1`

## New eval proposals

- Count: `0`
- The checked-in eval portfolio is at the coded cap of 30.

## Approved tickets

- `task-histogram-003`

## Ticket policy

- Review all open tickets before selection: `yes`
- Select the first two approved tickets after review: `yes`
- Approve eligible Open tickets before engineer dispatch: `required`
- Do not approve the remaining histogram tickets unless their named focused
  or cross-eval evidence gates are satisfied.
- Require API-surface justification and CTO approval for any new XSH API
  proposal.

## Role overrides

Use the normal role defaults; no reduced-intensity overrides.

## Required outputs

- one validated engineer implementation row for `task-histogram-003`;
- one independent `task-dupcheck` worker/evaluator evidence packet;
- manager classification and any new durable product tickets;
- run/phase reports, CTO briefing, productivity report, and improvement
  handoff;
- amended engineer commit provenance and portable patch evidence.
