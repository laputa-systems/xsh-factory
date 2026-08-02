# Cycle request: task-tags-001 implementation

## Objective

Implement the user-approved XSH ticket in one isolated product worktree. This
cycle is intentionally implementation-only: do not run task-tags, task-ecount,
an eval-manager, or an eval-designer. Leave the completed branch pending user
review and merge.

## Mode

- `ticket-implementation`

## Approved tickets

- `task-tags-001`

## Role overrides

Use the defaults codified by `run.xsh` and `run-agent.xsh`.

## Required outputs

- one dedicated XSH worktree and branch per approved ticket;
- one engineer Pi session, thinking transcript, worker report, and engineer report;
- product tests and canonical documentation appropriate to the ticket;
- a deterministic branch/commit/worktree verification report;
- a run-level cost report and event ledger;
- `DIRECTOR-REPORT.md` with `## North-star impact`;
- `RUN.md` stating that the branch is ready for user review, not merged.
