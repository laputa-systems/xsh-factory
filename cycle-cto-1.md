# Cycle request: organization — evaluator repair and duplicate-file implementation

## Objective

Run one bounded organization cycle under the CTO contract. The current
assembly-line bottleneck is approval-to-delivery: `task-dupcheck-001` has a
reproducible evaluator-container module failure, and the shared executor now
mounts `factory_control.xsh` with a native regression assertion. Approve and
implement that infrastructure ticket, then require its linked replay to
produce the eight-case manifest. Run the distinct approved `task-svcstat` eval
as the independent signal phase. Do not create a new eval proposal because the
portfolio is at the coded 30-contract cap.

## Bottleneck review

- Stage: approval -> reviewable engineer commit.
- Evidence: `tickets/task-dupcheck-001.md` records the deterministic
  `parse.module-read` evaluator failure; `eval-executor.xsh` now mounts the
  missing shared module; `tests/tools_test.xsh` asserts that boundary.
- Corrective action: admit one bounded engineer assignment for the repaired
  ticket and require the linked `task-dupcheck` replay before merge review.
- Target: one reviewable engineer commit, a passing linked eight-case
  evaluator manifest, and a passing independent manifest within the aggregate
  cap.

## Mode

- `organization`

## Active evals

- `task-svcstat`

## Trial plan

- Count: `1`

## New eval proposals

- Count: `0`

## Approved tickets

- `task-dupcheck-001`

## Ticket policy

- Review all open tickets before selection: `yes`
- Explicit ticket list: `yes`

## Eval admission

- Allow measured eval reuse: `yes`

## Role overrides

Use the defaults codified by `factory_control.xsh` and `run-agent.xsh`.

## Required outputs

- one bounded engineer implementation for `task-dupcheck-001`;
- one linked `task-dupcheck` replay against the candidate worktree;
- one independent `task-svcstat` eval against XSH main;
- no eval-design phase;
- one `CTO-IMPROVEMENT.md` and `CTO-PRODUCTIVITY-REPORT.md` handoff;
- complete structured reports, narratives, sessions, manifests, and events.
