# Standard organization request template

Use this template with `run.xsh`; the controller stores the immutable request
under the selected run directory. No `cycle-*.md` files are kept at repository
top level.

# Cycle request: standard organization

## Objective

Run one bounded organization cycle. Before invoking `run.xsh`, the CTO
reviews every remaining `Open.` ticket for evidence, duplication, scope,
acceptance criteria, linked-eval availability, and resolved deferral
conditions. Eligible tickets are approved in their checked-in records before
admission. When no ticket passes the gate, record the blocking reason for every
Open ticket and run the selected eval. The controller must not infer work from
prose.

## Bottleneck review

Before invoking `run.xsh`, identify the constrained assembly-line stage:
eval signal, ticket approval, engineer delivery, or replay/merge. Cite the
latest run evidence and choose one corrective action with a measurable target.
After the cycle, compare the result against that target. If eval signal is the
constraint, select a different approved eval rather than repeatedly spending
on the same saturated eval. The prior cycle validated the engineer-delivery
path and produced one reviewable implementation commit. The current constraint
is eval signal for the still-open histogram observations: each requires a fresh
controlled replay before approval. Select the lexicographically first untried
approved eval, `task-grep`, as a new independent signal; do not reuse a
saturated eval.

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

## Role overrides

Use the defaults codified by `factory/control.xsh` and
`factory/entrypoints/run-agent.xsh`. Put any deliberate override in the
invocation with a role-specific setting.

## Required outputs

- one independent active eval plus the linked replay for the admitted ticket;
- structured worker reports and raw Pi sessions;
- a run-level `report.json` covering every worker;
- a `## North-star impact` section in each narrative role report;
- one `CTO-IMPROVEMENT.md` factory-wide improvement handoff with a measurable
  next-cycle validation or revert condition;
- one `CTO-PRODUCTIVITY-REPORT.md` with a critical throughput/efficiency
  comparison against the prior cycle;
- a `CTO-REPORT.md` briefing generated from the structured reports.
