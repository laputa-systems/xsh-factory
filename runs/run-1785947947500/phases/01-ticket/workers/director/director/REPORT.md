# Director report

## Result

fail

## Cycle

Mode: `ticket-implementation`. Controller-selected ticket: `task-dupcheck-001`
(Approved.), active eval `task-dupcheck`, trial plan count 1. Plan: implement
the single approved ticket in one isolated XSH worktree and capture a portable
patch for CTO review. The controller dispatched one engineer row
(`task-dupcheck-001`) concurrently and I reconciled its completed report in
`FACTORY_DIRECTOR_RECONCILE_ONLY=true` mode.

## Children

- `task-dupcheck-001` — session and report **present**, worker execution
  result `pass` (agent process, reporting, and watcher all passed), but **no
  product commit** and **no files changed**. Narrative result remained
  `not-ready`. The engineer correctly identified a repository/scope mismatch:
  the ticket's acceptance criteria are a harness-packaging fix in
  `eval-executor.xsh` (a factory-repository change), while the assigned
  worktree was the XSH product worktree which the contract forbids editing at
  the factory-main level. Evidence path:
  `workers/engineer/task-dupcheck-001/REPORT.md` and `report.json`.

## Required-output status

- Engineer product commit on `factory/task-dupcheck-001/1785947948312`:
  **missing** (worktree clean, `git log` shows only baseline commits).
- Captured portable patch under `patches/`: **missing** (directory empty).
- Engineer narrative `REPORT.md`: **present and valid** (fail-closed
  `not-ready`, correctly stating the block).
- XSH main untouched, ticket status unchanged (`Approved.`), no merge
  performed — all consistent with the contract.
- Overall required output for the ticket (a reviewable product commit) is
  **absent**; cycle is a product fail.

## North-star impact

This cycle produced no XSH product improvement: the dispatched ticket's fix
targets the factory's evaluator-container module provisioning
(`eval-executor.xsh`) — a harness/infrastructure change — but the assignment
supplied only an XSH product worktree and forbade editing the factory main
tree. The engineer correctly stopped rather than forcing a change that could
not affect the isolated evaluator trial.

The durable lesson is about factory dispatch, not XSH ergonomics: tickets
whose proposed change lives in the factory repository (e.g. shared
`factory_control` module provisioning in `eval-executor.xsh`) must be admitted
to a factory-repository worktree or re-scoped to an XSH change; dispatching
them to the product worktree guarantees a blocked, no-commit row. This
reproduces the underlying verified reproducible defect described in the
ticket (all `factory_control`-dependent evals fail at module load) without
advancing it. Uncertainty remains as to whether the harness fix, once applied
in the correct repository, will actually unblock task-dupcheck and validate
the fs/hash composition hypothesis — that requires a re-scoped cycle and a
linked replay, which is out of this cycle's scope.
