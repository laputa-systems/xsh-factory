# Cycle request: hello bootstrap

## Objective

Prove the complete factory run path at negligible task cost. The director must
launch the hello eval-manager, which must launch the isolated hello eval-worker
through the executor. Preserve every session and produce a per-worker and
per-role cost report.

## Active evals

- `hello`

## New eval proposals

- Count: `0`

## Open-ticket work

- Dispatch tickets present at cycle start: `no`
- Dispatch newly created tickets in this cycle: `no`

## Role overrides

Use the defaults codified by `run.xsh` and `run-agent.xsh`.

## Required outputs

- hello executor pass;
- director, eval-manager, and eval-worker Pi sessions under one run directory;
- a full thinking transcript for each session;
- a Markdown cost report with worker rows, role totals, and run total;
- `RUN.md` reporting success or preserved partial evidence.
