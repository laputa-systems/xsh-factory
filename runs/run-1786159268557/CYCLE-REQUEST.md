# Standard organization request template

Use this template with `run.xsh`; the controller stores the immutable request
under the selected run directory. No `cycle-*.md` files are kept at repository
top level.

# Cycle request: standard organization

## Objective

Run one bounded organization cycle. Before invoking `run.xsh`, the CTO
reviewed every remaining `Open.` ticket and approved `task-render-001` in its
checked-in record. The linked replay and independent corroborating eval remain
the delivery gates. The controller must not infer work from prose.

## Bottleneck review

The current assembly-line bottleneck is approval -> reviewable engineer
commit -> linked replay. The Map-construction observation in `task-render-001`
has a passing source trial and corroborating `task-dupcheck` evidence. This
cycle targets one reviewable API-reference implementation commit, one passing
independent corroboration, and one passing linked replay with delivery into
XSH `HEAD`.

## Mode

- `organization`

## Eval admission

- Allow measured eval reuse: `yes`
- `task-dupcheck` is selected deliberately as the named map-building
  corroboration for the approved `task-render-001` ticket.

## Active evals

- `task-dupcheck`

## Trial plan

- Count: `1`

## New eval proposals

- Count: `0`
- The checked-in eval portfolio is at the coded cap; do not design or promote
  another package in this cycle.

## Approved tickets

- `task-render-001`

## Ticket policy

- Review all open tickets before selection: `yes`
- Select the first two approved tickets after review: one approved ticket is
  admitted in this narrow validation cycle.
- Admission invariant: `task-render-001` was approved before invoking `run.xsh`.
- Quality gate: do not dispatch a ticket whose proposed API addition lacks the
  `## API-surface justification` section and CTO approval.

## Role overrides

Use the defaults codified by `factory/control.xsh` and
`factory/entrypoints/run-agent.xsh`. Put any deliberate override in the
invocation with a role-specific setting.

## Required outputs

- one fresh engineer implementation row for `task-render-001`;
- one independent `task-dupcheck` eval and one linked `task-render` replay;
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
