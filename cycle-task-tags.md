# Cycle request: task-tags seed

## Objective

Run the smallest complete factory path against the practical task-tags eval.
The director must launch the task-tags eval-manager, which must launch the
isolated task-tags eval-worker through the executor. Preserve every session,
the evaluator manifest, and a per-worker and per-role cost report.

This is the low-cost capability seed, not a claim that one passing run proves
XSH quality. The manager must state what the run does and does not teach about
the north-star objective.

## Active evals

- `task-tags`

## New eval proposals

- Count: `0`

## Open-ticket work

- Dispatch tickets present at cycle start: `no`
- Dispatch newly created tickets in this cycle: `no`

## Role overrides

Use the defaults codified by `run.xsh` and `run-agent.xsh`.

## Required outputs

- task-tags executor pass;
- director, eval-manager, and eval-worker Pi sessions under one run directory;
- a full thinking transcript for each session;
- the evaluator `run.json` with correctness and timing evidence;
- a Markdown cost report with worker rows, role totals, and run total;
- `## North-star impact` in the director and manager reports;
- `RUN.md` reporting success or preserved partial evidence.
