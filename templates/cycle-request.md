# Cycle request

## Objective

Run the smallest complete organization cycle that proves the requested
factory path and produces evidence toward `NORTH-STAR.md`. Keep the cycle
cheap and preserve all worker evidence; do not create activity or tickets
without a corresponding product hypothesis. When a ticket is admitted, run
its linked re-evaluation and independent active eval, while the independent
eval-design phase runs alongside the primary phase.

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

## Open-ticket work

- Dispatch tickets present at cycle start: `yes`
- Dispatch newly created tickets in this cycle: `no`

## Ticket policy

- Select the first approved ticket: `yes`

## Role overrides

Use the defaults codified by `run.xsh` and `run-agent.xsh`. Put any deliberate
environment override in the invocation, using names such as
`FACTORY_EVAL_MANAGER_MODEL` or `FACTORY_XSH_SWE_THINKING`.

## Required outputs

- one approved ticket implementation and linked pre-merge replay when a ticket
  is available;
- one independent active eval when a ticket is available, otherwise one active
  eval as the primary phase;
- one eval-design proposal pending review;
- worker session reports and extracted thinking transcripts;
- a run-level cost report covering every Pi session;
- a `## North-star impact` section in each narrative role report;
- a concise `RUN.md` result.
