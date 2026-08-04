# Cycle request: standard organization

## Objective

Run one bounded organization cycle. Admit at most one explicitly approved
ticket, or automatically select the first approved ticket. If none is
available, run the selected eval. When a ticket is admitted, immediately
re-evaluate its linked eval against the exact clean engineer worktree before merge,
then run the independent `task-ecount` eval against XSH main. Always stage one
small practical eval proposal for user review.

## Mode

- `organization`

## Active evals

- `task-ecount`

## Trial plan

- Count: `1`

## New eval proposals

- Count: `1`
- Difficulty: no harder than ecount; prefer a small practical programming or
  systems-administration task.

## Ticket policy

- Select the first approved ticket: `yes`

## Role overrides

Use the defaults codified by `factory_control.xsh` and `run-agent.xsh`. Put any
deliberate override in the invocation with a role-specific setting.

## Required outputs

- one primary eval or ticket phase;
- one linked candidate re-evaluation when a ticket is admitted;
- one independent `task-ecount` eval when a ticket is admitted;
- one eval-design proposal pending review;
- aggregate cost and per-phase reports under one parent run;
- no worker-selected tickets, evals, merges, or approvals.
