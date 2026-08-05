# Cycle request: organization — task-ecount-008 multi-trial replay

## Objective

Run one bounded organization cycle. Review every remaining `Open.` ticket for
evidence, duplication, scope, and acceptance criteria before selecting work.
`task-ecount-008` is the single `Approved.` ticket and already has an unmerged
implementation branch, so the controller reuses that exact branch for a stable
**two-trial** linked re-evaluation instead of dispatching another engineer;
this resolves the prior single-sample timing-gate noise (ratio `1.221`,
outside `0.90..1.10`) before the CTO merge decision. Run the independent
`task-envcfg` eval against XSH main. No new eval-design phase this cycle: the
prior run already promoted and approved `task-render`, and the factory eval
count is near the coded cap (18/20), so a fresh proposal would be redundant
spend.

## Mode

- `organization`

## Active evals

- `task-envcfg`

## Trial plan

- Count: `2`

## New eval proposals

- Count: `0`

## Approved tickets

- Auto-select the first approved ticket after review (`task-ecount-008`).

## Ticket policy

- Review all open tickets before selection: `yes`
- Select the first two approved tickets after review: `yes`

## Role overrides

Use the defaults codified by `the shared factory control module` and `factory/entrypoints/run-agent.xsh`. Put any
deliberate override in the invocation with a role-specific setting.

## Required outputs

- one primary phase that reuses the existing `task-ecount-008` implementation
  branch (no duplicate engineer dispatch);
- one two-trial linked candidate re-evaluation of `task-ecount-008` against
  that branch;
- one independent `task-envcfg` eval when a ticket is admitted, distinct from
  the linked ticket replay;
- no eval-design phase (a proposal was already promoted and approved as
  `task-render` in the preceding run; eval count is near the coded cap);
- aggregate cost and per-phase reports under one parent run;
- one `CTO-IMPROVEMENT.md` factory-wide improvement handoff with a next-cycle
  validation or revert condition;
- no worker-selected tickets, evals, merges, or approvals.
