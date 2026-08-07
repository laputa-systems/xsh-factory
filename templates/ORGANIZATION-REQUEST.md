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

The clean-slate checkout has no persisted run evidence, so the current
assembly-line bottleneck is eval signal -> reproducible ticket. The five Open
histogram tickets were reviewed and each remains deferred pending the fresh
controlled or cross-eval replay recorded in its ticket. This cycle therefore
uses the first untried Approved eval, `task-bigfiles`, to restore current
evidence; the target is one evaluator-backed observation that can either
qualify a ticket for the next cycle or falsify the existing hypotheses.

## Mode

- `organization`

## Eval admission

- Allow measured eval reuse: `no`
- The controller must select the lexicographically first untried Approved eval
  when one exists.

## Active evals

- `task-bigfiles`

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
- Select the first two approved tickets after review: no eligible tickets in
  this clean-slate pass.
- Admission invariant: approve eligible Open tickets before invoking `run.xsh`;
  this cycle records explicit deferrals and intentionally runs eval-only.
- Quality gate: do not dispatch a ticket whose proposed API addition lacks the
  `## API-surface justification` section and CTO approval.

## Role overrides

Use the defaults codified by `factory/control.xsh` and
`factory/entrypoints/run-agent.xsh`. Put any deliberate override in the
invocation with a role-specific setting.

## Required outputs

- one independent active eval; no ticket replay because no ticket was admitted;
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
