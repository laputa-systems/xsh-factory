# Director report

## Result

fail

## Cycle

Mode: `ticket-implementation` (organization phase `01-ticket`). The controller
admitted exactly one approved ticket, `task-findexec-001` (Change target:
`product`), created an isolated worktree on branch
`factory/task-findexec-001/1785962530721` at XSH commit
`1cf4ad3d7ee5fde9b3160b11d8073cbd7ce5e7c4`, and launched the single admitted
engineer row (`engineer-task-findexec-001`) concurrently through the shared
runner. This run is director-reconcile-only
(`FACTORY_DIRECTOR_RECONCILE_ONLY=true`): the controller already dispatched the
engineer and the director reconciles the completed outputs rather than
launching children.

## Children

| Child | Result | Evidence path |
| --- | --- | --- |
| engineer / task-findexec-001 | not-run (launch rejected before Pi) | `runs/run-1785962529677/phases/01-ticket/engineer-task-findexec-001.stderr`; worker dir `workers/engineer/task-findexec-001/` is empty |

The engineer stderr reads: `engineer workdir is inside the factory checkout`.
The controller created the ticket worktree at
`runs/run-1785962529677/phases/01-ticket/worktrees/task-findexec-001`, a path
that canonicalizes as *inside* the factory checkout
(`/Users/josh/d/laputa-systems/xsh-factory`). The shared runner's engineer
boundary guard
(`factory/entrypoints/run-agent.xsh`, `if role == "engineer" and
canonical_paths.within(factory_dir, workdir)? { abort "engineer workdir is
inside the factory checkout" }`) therefore aborted the session before any Pi
turn, claim, or commit occurred. No engineer `REPORT.md`, session, patch, or
implementation commit was produced. The worktree branch remains at the
baseline commit (`1cf4ad3`).

## Required-output status

| Required output | Status |
| --- | --- |
| Engineer session report (`REPORT.md` + `WORKER.md`) | **missing** — worker task dir is empty |
| Engineer `session.jsonl.bz2` | **missing** — no Pi session started |
| Ticket implementation branch commit | **missing** — branch still at baseline `1cf4ad3` |
| Portable patch under `patches/` | **missing** — directory is empty |
| Ticket merge record (`IMPLEMENTATION_BRANCH`/`COMMIT`/run) | **missing** — ticket still `Approved.` with placeholders |
| Director `REPORT.md` | present (this file) |

The phase `report.json` reflects a `fail` outcome (`cycle: fail`,
`product: fail`, `outcomes.product: fail`), and the controller-required product
output is absent. The ticket remains `Approved.` for a future cycle; no merge
record was written.

## North-star impact

This cycle produced no product signal and no engineer output. It surfaced a
bounded **factory orchestration defect** rather than an XSH language or agent
capability result: the controller's ticket admission placed the engineer
worktree under the run directory *inside* the factory checkout, tripping the
runner's own engineer-workdir-must-live-outside-the-checkout guard and causing
the single admitted engineer to be aborted at launch. Every later step (patch,
commit, doc, replay readiness) depended on that worktree and therefore failed
closed.

Uncertainty: this is a single occurrence with no engineer session to inspect,
so it is evidence about the controller's worktree-placement contract, not about
XSH ergonomics or agent fluency. The fix is a controller/dispatch change (place
ticket worktrees outside `FACTORY_DIR`, e.g. a sibling scratch root, so the
canonical worktree path satisfies the runner guard), which is a CTO-owned
factory change, not a product ticket. Until that is corrected, no engineer row
for an admitted product ticket can run and the linked `task-findexec` replay
gate cannot be exercised. Recommended next step: CTO validates worktree
placement and re-dispatches `task-findexec-001` in a subsequent
ticket-implementation cycle.
