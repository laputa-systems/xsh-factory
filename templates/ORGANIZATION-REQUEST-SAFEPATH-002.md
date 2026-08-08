# Organization request — task-safepath-002 throughput cycle

Use this template with `run.xsh`; the controller stores the immutable request
under the selected run directory.

# Cycle request: organization product delivery

## Objective

Run one bounded organization cycle with at least one engineer implementation
commit delivered to XSH `HEAD`. Implement the CTO-approved `task-safepath-002`
compiler defect, run its linked replay, and run one distinct independent eval.
The controller must not infer work from prose or fall back to eval-only work
while this approved ticket is available.

## Bottleneck review

The current assembly-line bottleneck is approval -> reviewable engineer commit
-> passing replay. The previous cycle delivered one commit and closed its
postmortem; this cycle measures whether delivery remains repeatable on a
compiler/lowering defect while preserving the source-isolation and provenance
guards.

## Mode

- `organization`

## Eval admission

- Allow measured eval reuse: `yes`
- The controller selects one independent active eval because an approved ticket
  is ready; it is distinct from the linked `task-safepath` replay. The ID is
  selected deterministically from the next untried approved eval queue.

## Active evals

- Auto.

## Trial plan

- Count: `1`

## New eval proposals

- Count: `0`
- The checked-in eval portfolio is at the coded cap; do not design or promote
  another package in this cycle.

## Approved tickets

- Auto.

## Ticket policy

- Review all open tickets before selection: `yes`
- Select the first two approved tickets after review: one approved ticket is
  admitted in this narrow cycle.
- Admission invariant: `task-safepath-002` was approved before invoking
  `run.xsh`; the other seven Open tickets retain their recorded evidence
  deferrals.
- Quality gate: the ticket contains the required API-surface justification and
  proposes no new public syntax or runtime surface.

## Required outputs

- one fresh engineer implementation row for `task-safepath-002`;
- one independent eval selected by the queue policy and one linked
  `task-safepath` replay;
- structured worker reports and raw Pi sessions;
- a run-level `report.json` with throughput accounting;
- one `CTO-IMPROVEMENT.md` and one `CTO-PRODUCTIVITY-REPORT.md`;
- a generated `CTO-REPORT.md` briefing.

When a ticket is admitted, delivery is mandatory: the exact validated
implementation commit must be reachable from XSH `HEAD`, and the ticket may
be reconciled to `Merged.` only after that proof.
