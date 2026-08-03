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

- `task-envcfg`

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

- Review all open tickets before selection: `yes`
- Select the first two approved tickets after review: `yes`

## Role overrides

Use the defaults codified by `run.xsh` and `run-agent.xsh`. Put any deliberate
environment override in the invocation, using names such as
`FACTORY_EVAL_MANAGER_MODEL` or `FACTORY_ENGINEER_THINKING`.

## Required outputs

- up to two approved ticket implementations and one linked pre-merge replay per
  ticket when tickets are available;
- one independent active eval when a ticket is available, otherwise one active
  eval as the primary phase;
- one eval-design proposal pending review;
- structured worker reports and raw Pi sessions;
- a run-level `report.json` covering every worker;
- a `## North-star impact` section in each narrative role report;
- one `CTO-IMPROVEMENT.md` factory-wide improvement handoff with a measurable
  next-cycle validation or revert condition;
- a `CTO-REPORT.md` briefing generated from the structured reports.
