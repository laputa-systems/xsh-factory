# Cycle request: mixed retained-and-fresh throughput

## Objective

Run one bounded organization cycle using the mixed-batch throughput path. Replay
the retained `task-pathparts-001` implementation and implement `task-trim-002`
concurrently where their inputs are isolated, then run each linked replay before
delivering any product commit.

## Bottleneck review

The previous cycle's correctness evidence was good but delivered zero product
commits because the retained pathparts branch failed a source-text restriction
gate: the worker followed the lint-preferred typed-Path spelling
`fp"${argv[0]}"`, while the evaluator required the lint-conflicting literal
`Path(`. The factory change aligns that package-owned gate and allows one
retained branch to share a bounded batch with one fresh engineer ticket.

Target: deliver two product commits when both linked replays pass; otherwise
retain only the failing branch and preserve the exact evidence split.

## Mode

- `organization`

## Eval admission

- Allow measured eval reuse: `yes`

## Active evals

- `task-histogram`

## Trial plan

- Count: `1`

## New eval proposals

- Count: `0`

## Approved tickets

- `task-pathparts-001`
- `task-trim-002`

## Ticket policy

- Review all open tickets before selection: `yes`
- Select the two approved tickets above; one is a retained branch and one is a fresh engineer row.
- Admission invariant: both tickets are product-targeted, linked to live approved evals, and have explicit CTO review evidence.
- Quality gate: neither ticket adds a builtin, keyword, constructor, type, method, or syntax form.

## Role overrides

Use the defaults codified by `factory/control.xsh` and
`factory/entrypoints/run-agent.xsh`.

## Required outputs

- one independent `task-histogram` eval;
- linked `task-pathparts` and `task-trim` replays;
- isolated retained-branch and fresh-engineer primary evidence;
- structured worker reports, raw sessions, phase reports, and lifecycle events;
- a measurable `CTO-IMPROVEMENT.md` and throughput comparison;
- a generated `CTO-REPORT.md` with product, evaluator, infrastructure, and overall outcomes.
