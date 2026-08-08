# Standard organization request template

Use this template with `run.xsh`; the controller stores the immutable request
under the selected run directory. No `cycle-*.md` files are kept at repository
top level.

# Cycle request: standard organization

## Objective

Run one bounded organization cycle. The controller applies the queue-pressure
policy after deterministic CTO inventory: it dispatches up to two already
approved product tickets when the ready queue supports them, keeps one
independent eval alongside product work, and runs up to four discovery evals
when no approved ticket is ready. It never promotes an `Open.` ticket.

## Bottleneck review

The current assembly-line bottleneck is approval -> reviewable engineer commit
-> linked replay. Product delivery is the hard goal whenever an approved ticket
is available; discovery expands only when the ready queue is empty.

## Mode

- `organization`

## Eval admission

- Allow measured eval reuse: `yes`
- The controller selects the next untried approved evals according to queue
  pressure.

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
- Select the first two approved tickets after review when available.
- Admission invariant: every selected ticket was already `Approved.` before
  invoking `run.xsh`; `Open.` tickets are never promoted by the controller.
- Quality gate: do not dispatch a ticket whose proposed API addition lacks the
  `## API-surface justification` section and CTO approval.

## Role overrides

Use the defaults codified by `factory/control.xsh` and
`factory/entrypoints/run-agent.xsh`. Put any deliberate override in the
invocation with a role-specific setting.

## Required outputs

- one engineer implementation row for every selected approved ticket;
- one independent eval alongside product work, or the adaptive discovery batch
  when no approved ticket is ready;
- structured worker reports and raw Pi sessions;
- a run-level `report.json` covering every worker;
- a `## North-star impact` section in each narrative role report;
- one `CTO-IMPROVEMENT.md` factory-wide improvement handoff with a measurable
  next-cycle validation or revert condition;
- one `CTO-PRODUCTIVITY-REPORT.md` with a critical throughput/efficiency
  comparison against the prior cycle;
- a `CTO-REPORT.md` briefing generated from the structured reports.

When a ticket is admitted, the organization controller also owns final product
delivery after the linked replay: the exact validated implementation commit
must be reachable from XSH `HEAD`, and the linked ticket must be reconciled to
`Merged.`. A delivery failure fails the cycle and retains the branch.
