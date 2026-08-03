# Cycle request: standard organization

## Objective

Run one bounded organization cycle. Review every remaining `Open.` ticket for
evidence, duplication, scope, and acceptance criteria before selecting work.
Admit at most one explicitly approved ticket, or automatically select the
first approved ticket after that review. If none is available, run the selected eval. When a ticket is admitted, immediately
re-evaluate its linked eval against the exact clean engineer worktree before merge,
then run the independent `task-envcfg` eval against XSH main. Always stage one
small practical eval proposal for user review.

## Mode

- `organization`

## Active evals

- `task-envcfg`

## Trial plan

- Count: `1`

## New eval proposals

- Count: `1`
- Difficulty: no harder than ecount; prefer a small practical programming or
  systems-administration task.

## Ticket policy

- Review all open tickets before selection: `yes`
- Select the first approved ticket after review: `yes`

## Role overrides

Use the defaults codified by `factory_control.xsh` and `run-agent.xsh`. Put any
deliberate override in the invocation with a role-specific setting.

## Required outputs

- one primary eval or ticket phase;
- one linked candidate re-evaluation when a ticket is admitted;
- one independent `task-envcfg` eval when a ticket is admitted, distinct from
  the linked ticket replay;
- one eval-design proposal pending review;
- aggregate cost and per-phase reports under one parent run;
- one `CTO-IMPROVEMENT.md` factory-wide improvement handoff with a next-cycle
  validation or revert condition;
- no worker-selected tickets, evals, merges, or approvals.
