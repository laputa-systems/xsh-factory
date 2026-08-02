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
- one engineer Pi session, structured worker report, and engineer report;
- product tests and canonical documentation appropriate to the ticket;
- a structured phase report and JSON event ledger;
- a director `REPORT.md` with `## North-star impact`;
- `patches/task-tags-001.diff` stating that the branch is ready for user review, not merged.
