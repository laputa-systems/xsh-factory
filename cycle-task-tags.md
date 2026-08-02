# Cycle request: task-tags seed

## Objective

Run the smallest complete CTO path against the practical task-tags eval. The
controller runs the isolated task-tags executor, then launches the eval-manager
and eval-designer in parallel-safe phases, followed by a director review.
Preserve every session, the evaluator manifest, and a per-worker and per-role
cost report.

This is the low-cost capability seed, not a claim that one passing run proves
XSH quality. The manager must state what the run does and does not teach about
the north-star objective.

## Active evals

- `task-tags`

## Mode

- `organization`

## Trial plan

- Count: `1`

## New eval proposals

- Count: `1`

## Approved tickets

- None.

## Ticket policy

- Do not select an unlisted ticket: `yes`

## Open-ticket work

- Dispatch tickets present at cycle start: `no`
- Dispatch newly created tickets in this cycle: `no`

## Role overrides

Use the defaults codified by `run.xsh` and `run-agent.xsh`.

## Required outputs

- task-tags executor pass;
- director, eval-manager, eval-worker, and eval-designer Pi sessions under one run directory;
- a full thinking transcript for each session;
- the evaluator `run.json` with correctness and timing evidence;
- a Markdown cost report with worker rows, role totals, and run total;
- `## North-star impact` in the director and manager reports;
- `CURRENT-EVIDENCE.md` and `OPEN-TICKETS.md` before manager review;
- `RUN.md` reporting success or preserved partial evidence.
