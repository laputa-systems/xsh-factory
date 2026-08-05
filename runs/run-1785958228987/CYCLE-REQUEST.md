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
on the same saturated eval. This request permits measured reuse only to satisfy
the controller's explicit selection gate; `task-findexec` is selected because
it is a fresh approved portfolio member, while the recently saturated
`task-ecount` signal is not reused.

## Mode

- `organization`

## Eval admission

- Allow measured eval reuse: `yes`
- The controller must select the lexicographically first untried Approved eval
  when one exists. Set reuse to `yes` only with a written CTO rationale.

## Active evals

- `task-findexec`

## Trial plan

- Count: `1`

## New eval proposals

- Count: `0`
- The checked-in eval portfolio is at the coded cap; do not design or promote
  another package in this cycle.

## Approved tickets

- None.

## Ticket policy

- Review all open tickets before selection: `yes`
- Select the first two approved tickets after review: `yes`
- Admission invariant: approve eligible Open tickets before invoking `run.xsh`;
  do not silently fall back to eval-only work.
- Quality gate: do not dispatch a ticket whose proposed API addition lacks the
  `## API-surface justification` section and CTO approval.

## Role overrides

Use the defaults codified by `factory/control.xsh` and
`factory/entrypoints/run-agent.xsh`. Put any deliberate override in the
invocation with a role-specific setting.

## Required outputs

- one active eval as the primary phase because no ticket is admitted;
- structured worker reports and raw Pi sessions;
- a run-level `report.json` covering every worker;
- a `## North-star impact` section in each narrative role report;
- one `CTO-IMPROVEMENT.md` factory-wide improvement handoff with a measurable
  next-cycle validation or revert condition;
- one `CTO-PRODUCTIVITY-REPORT.md` with a critical throughput/efficiency
  comparison against the prior cycle;
- a `CTO-REPORT.md` briefing generated from the structured reports.
