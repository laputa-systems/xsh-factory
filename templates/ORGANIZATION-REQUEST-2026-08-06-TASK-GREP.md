# CTO cycle request: task-grep signal

## Objective

Run one bounded organization cycle. The CTO reviewed every remaining `Open.`
ticket and recorded a concrete deferral reason in each checked-in ticket. No
ticket is admitted because each still requires fresh controlled evidence before
engineer approval.

## Bottleneck review

The current assembly-line constraint is eval signal for the still-open
`task-histogram` observations. The prior cycle validated engineer delivery and
produced one reviewable implementation commit at
`runs/run-1785973900575/report.json`. Select the lexicographically first
untried approved eval, `task-grep`, as a new independent signal; do not reuse a
saturated eval. The next target is a complete evaluator manifest and manager
classification without infrastructure or artifact-boundary failure.

## Mode

- `organization`

## Eval admission

- Allow measured eval reuse: `no`
- The controller must select the lexicographically first untried Approved eval
  when one exists.

## Active evals

- `task-grep`

## Trial plan

- Count: `1`

## New eval proposals

- Count: `0`
- The checked-in eval portfolio is at the coded cap; do not design or promote
  another package in this cycle.

## Approved tickets

No ticket is admitted in this cycle. All remaining `Open.` tickets have a
recorded CTO deferral reason and require fresh controlled evidence before
engineer approval.

## Ticket policy

- Review all open tickets before selection: `yes`
- Select the first two approved tickets after review: `no`
- Admission invariant: approve eligible Open tickets before invoking `run.xsh`;
  do not silently fall back to eval-only work.
- Quality gate: do not dispatch a ticket whose proposed API addition lacks the
  `## API-surface justification` section and CTO approval.

## Required outputs

- structured worker reports and raw Pi sessions;
- a run-level `report.json` covering every worker;
- a `## North-star impact` section in each narrative role report;
- one `CTO-IMPROVEMENT.md` factory-wide improvement handoff with a measurable
  next-cycle validation or revert condition;
- one `CTO-PRODUCTIVITY-REPORT.md` with a critical throughput/efficiency
  comparison against the prior cycle;
- a `CTO-REPORT.md` briefing generated from the structured reports.
