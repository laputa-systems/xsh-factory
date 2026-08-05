# Cycle request: organization — replay the repaired evaluator boundary

## Objective

Run one bounded organization cycle to validate the shared evaluator-container
repair exposed by `run-1785947947500`. The prior cycle's engineer assignment
was correctly blocked because the approved ticket was a factory-repository
change, not an XSH product change; the cycle nevertheless produced the exact
new failure signal: every evaluator hit a duplicate `/run/evaluator.xsh`
mount. That duplicate is now removed, while the shared `factory_control.xsh`
mount remains. Reuse the existing `task-dupcheck-001` implementation branch
only if the controller finds one; otherwise do not dispatch a duplicate
engineer. Run the linked `task-dupcheck` replay and the distinct independent
`task-svcstat` eval. Do not create a design proposal at the 30-contract cap.

## Bottleneck review

- Stage: commit/replay -> passing evaluator manifest.
- Evidence: `runs/run-1785947947500/phases/02-reeval-task-dupcheck-001/workers/eval-worker/task-dupcheck-1/evaluator.stderr` and the matching `task-svcstat` stderr both report `Duplicate mount point: /run/evaluator.xsh`.
- Corrective action: remove the duplicate mount, preserve the shared-module
  mount, and run two evaluator paths without spending an unnecessary second
  engineer row.
- Target: both linked and independent evaluator phases emit populated
  `run.json` manifests; the cycle must not repeat the duplicate-mount failure.

## Mode

- `organization`

## Active evals

- `task-svcstat`

## Trial plan

- Count: `1`

## New eval proposals

- Count: `0`

## Approved tickets

- None.

## Ticket policy

- Review all open tickets before selection: `yes`
- No ticket dispatch: the prior cycle's infrastructure ticket is already
  represented by the factory change under validation.

## Eval admission

- Allow measured eval reuse: `yes`

## Required outputs

- one linked `task-dupcheck` replay if the existing candidate branch is
  available; otherwise a durable explicit no-replay reason;
- one independent `task-svcstat` eval against XSH main;
- no engineer or eval-design dispatch;
- complete structured reports, narratives, sessions, manifests, and events;
- one `CTO-IMPROVEMENT.md` and `CTO-PRODUCTIVITY-REPORT.md` handoff.
