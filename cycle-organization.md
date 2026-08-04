# Cycle request: standard organization

## Objective

Run one bounded organization cycle. Before invoking the controller, the CTO
must review every remaining `Open.` ticket for evidence, duplication, scope,
acceptance criteria, linked-eval availability, and resolved deferral conditions.
The CTO must write `Approved.` into each eligible ticket and record the evidence
in that ticket. Admit up to two explicitly approved tickets, or automatically
select the first two approved tickets after that review. Do not run an eval-only
cycle while an eligible Open ticket remains unapproved; the controller cannot
infer approval from a narrative review. If no ticket is eligible, record the
blocking reason for every Open ticket and run the selected eval. When tickets are admitted, immediately
re-evaluate its linked eval against the exact clean engineer worktree before merge,
then run the independent `task-envcfg` eval against XSH main. Always produce
one small practical eval proposal for immediate CTO review and promotion.

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
- Select the first two approved tickets after review: `yes`
- Admission invariant: approve eligible Open tickets before invoking `run.xsh`; do not silently fall back to eval-only work

## Role overrides

Use the defaults codified by `factory_control.xsh` and `run-agent.xsh`. Put any
deliberate override in the invocation with a role-specific setting.

## Required outputs

- one primary eval or ticket phase;
- at least one engineer implementation whenever an evidence-backed eligible Open ticket exists;
- one linked candidate re-evaluation per admitted ticket;
- one independent `task-envcfg` eval when a ticket is admitted, distinct from
  the linked ticket replay;
- one eval-design proposal pending review;
- aggregate cost and per-phase reports under one parent run;
- one `CTO-IMPROVEMENT.md` factory-wide improvement handoff with a next-cycle
  validation or revert condition;
- no worker-selected tickets, evals, merges, or approvals.
