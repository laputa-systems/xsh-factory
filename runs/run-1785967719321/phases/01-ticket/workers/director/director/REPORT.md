# Director report

## Result

fail

## Cycle

Mode: `ticket-implementation`. Controller-selected approved ticket:
`task-findexec-001` (product change target — make `if`/`else` a first-class
expression accepted as a stream-block tail). Controller plan: create one
isolated worktree on branch `factory/task-findexec-001/1785967720675` and
dispatch one engineer row concurrently; the director reconciles only
(`FACTORY_DIRECTOR_RECONCILE_ONLY=true`), so the director did not launch or
re-launch any child.

## Children

| child | result | evidence path |
| --- | --- | --- |
| engineer / task-findexec-001 | fail (crashed before Pi; never claimed or produced a report) | `engineer-task-findexec-001.stderr`, `workers/engineer/task-findexec-001/` |

The single dispatched engineer crashed inside the shared runner before Pi
began. `engineer-task-findexec-001.stderr` shows a runtime traceback in
`run-agent.xsh` at line 77:

```text
error: normalized-path: types.DomainError.InvalidFormat
call path:
  1. proc main at factory/entrypoints/run-agent.xsh:1:1-1:1
  2. pure paths.within at factory/entrypoints/run-agent.xsh:77:29-77:73
```

Line 77 is the engineer workdir boundary check
(`canonical_paths.within(factory_dir, workdir)`). The controller-authored
dispatch manifest stores `workdir` and `product_root` with traversal syntax:
`/Users/josh/d/laputa-systems/xsh-factory/../.xsh-factory-worktrees/run-1785967719321/task-findexec-001`.
`factory/paths.xsh` `canonical_absolute` rejects any path containing
`/../` (kind `normalized-path`) as an `InvalidFormat`, so the runner aborted
before reaching the engineer dispatch-claim or report step. No engineer
`REPORT.md`, `WORKER.md`, or session was created; the worker directory
`workers/engineer/task-findexec-001/` is empty.

The worktree itself exists and is on the expected branch
`factory/task-findexec-001/1785967720675`, but it is unchanged at the base
XSH commit `1cf4ad3` (git status clean, log head still `1cf4ad3 native lint`).
The controller-staged fail-closed slots for the engineer report and the
`patches/` output were never filled.

## Required-output status

Required outputs for this ticket-implementation cycle and their status:

| required output | present | valid |
| --- | --- | --- |
| Engineer `REPORT.md` (`workers/engineer/task-findexec-001/REPORT.md`) | missing | no |
| Engineer session / claim | missing | no |
| Implementation commit on `factory/task-findexec-001/1785967720675` | missing (worktree at base `1cf4ad3`) | no |
| Portable patch (`patches/`) | missing | no |

The failure is infrastructure/controller-orchestration, not a ticket or
product outcome. The ticket was never implemented and its status was not
touched (remains `Approved.`).

## North-star impact

This cycle produced no product signal: the approved `task-findexec-001` work
(turning `if`/`else` into a first-class tail expression) was never attempted
because the engineer never reached Pi. The durable, actionable evidence is a
reproducible factory defect: the controller writes `workdir`/`product_root`
into the dispatch manifest using `/../` traversal syntax, while
`factory/paths.xsh::canonical_absolute` rejects exactly that syntax with
`normalized-path: InvalidFormat`. The boundary check at `run-agent.xsh:77` is
therefore never satisfiable for an engineer whose worktree lies outside the
factory checkout via a parent-relative path, so no engineer row can start.

This is a factory-infrastructure (not product) issue and is CTO-owned to
repair; a fix should normalize the controller-computed workdir/product_root to
a traversal-free canonical form before writing the dispatch manifest (or make
the runner's containment check resolve the real path consistently). This is
uncertainty-reducing rather than product-improving: it does not teach anything
about XSH ergonomics, learnability, or correctness, and it must not be
misread as evidence about the proposed `if`/`else` change. Until the launcher
path-normalization mismatch is fixed, ticket-implementation cycles fail closed
before any engineer work, so no north-star claim about agent efficiency or
product quality can be drawn from this run.
