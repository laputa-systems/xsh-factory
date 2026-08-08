# Preflight postmortem

## Result

The organization admission attempt failed before any paid worker or product
worktree was created. The controller created the run evidence directory and
inventory, then rejected `task-render-001` at the accepted-ticket gate.

## Cause

The ticket was marked `Approved.` but its API-surface justification used
capitalized `Semantic` and `Evidence`. The deterministic admission contract
requires the lower-case evidence markers and therefore correctly failed closed.

## Correction

The ticket justification was normalized and a native regression assertion now
checks that the selected approved ticket passes `runtime.accepted_ticket` before
cycle admission. No paid cycle was relaunched after this failed attempt.

## Evidence

- Run directory: `runs/run-1786159068132/`
- Controller output: `selected ticket is missing or not Approved: task-render-001`
- Regression: `tests/factory_control_test.xsh`
- Corrected ticket: `tickets/task-render-001.md`
