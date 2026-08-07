# Cycle request: paired discovery

## Objective

Run one bounded organization discovery cycle to verify the paired-eval
throughput path. The CTO reviewed every remaining Open ticket; none is yet
eligible for implementation because its recorded replay or cross-eval gate is
still outstanding. Do not dispatch an engineer in this cycle.

## Mode

- `organization`

## Eval admission

- Allow measured eval reuse: `no`
- The controller must select the next two deterministic untried Approved evals
  when no ticket is admitted.

## Active evals

- `task-envcfg`
- `task-findexec`

## Trial plan

- Count: `1`

## New eval proposals

- Count: `0`

## Approved tickets

- None.

## Ticket policy

- Review all open tickets before selection: `yes`
- Select the first two approved tickets after review: no eligible tickets in
  this discovery pass.
- Admission invariant: approve eligible Open tickets before invoking `run.xsh`;
  this cycle records explicit deferrals and intentionally runs eval-only.

## Required outputs

- two independent active eval phases, each with structured worker reports and
  raw Pi sessions;
- a run-level `report.json` covering every worker;
- a `## North-star impact` section in each narrative role report;
- one `CTO-IMPROVEMENT.md` factory-wide improvement handoff;
- one `CTO-PRODUCTIVITY-REPORT.md` with a throughput comparison against the
  prior cycle;
- a `CTO-REPORT.md` briefing generated from the structured reports.
