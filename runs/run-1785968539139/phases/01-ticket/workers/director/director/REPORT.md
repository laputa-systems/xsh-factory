# Director report

## Result

fail

The single dispatched engineer row for `task-findexec-001` did not run. The
controller launched it in reconcile-only mode, but the shared runner rejected
the agent invocation before any Pi session started, so there is no engineer
implementation, worker report, or portable patch. The phase `report.json`
records `cycle: fail` and `product: fail`.

## Cycle

Mode `ticket-implementation` (organization phase `01-ticket`). One approved
ticket, `task-findexec-001`, was admitted for implementation in an isolated
worktree. The controller prepared worktree on branch
`factory/task-findexec-001/1785968540693` at XSH commit `1cf4ad3
(controller-selected)` and dispatched one engineer row concurrently;
`FACTORY_DIRECTOR_RECONCILE_ONLY=true` so no child was launched by the
director. The XSH main commit is resolved as `1cf4ad3d7ee5fde9b3160b11d8073cbd7ce5e7c4`.

## Children

- `engineer/task-findexec-001` — **not-ready / never ran**.
  Evidence: `runs/run-1785968539139/phases/01-ticket/engineer-task-findexec-001.stderr`
  reads `agent invocation does not match controller dispatch record for
  engineer/task-findexec-001`; worker dir
  `workers/engineer/task-findexec-001/` is empty (no `REPORT.md` or session);
  `patches/` is empty; the worktree branch has no commits and no diff vs
  `master`. No child output to reconcile.

## Required-output status

- Engineer implementation of `task-findexec-001`: **missing** — no commits,
  no diff on `factory/task-findexec-001/1785968540693`.
- Portable patch per ticket: **missing** — `patches/` is empty.
- Engineer `REPORT.md`: **missing** — worker directory was created but holds
  no report.
- Director `REPORT.md`: **present** (this file).

The fail-closed stub was staged correctly; the child simply never produced
work because the runner rejected it at the dispatch-contract boundary.

## North-star impact

This is factory/infrastructure-only evidence; there is no product signal for
XSH itself. The engineer row failed closed before any product work, but the
failure is durable and reproducible and should feed the next
CTO-owned factory fix.

Root cause observed: the dispatch manifest stores the engineer `workdir` as an
unresolved path
`/Users/josh/d/laputa-systems/xsh-factory/../.xsh-factory-worktrees/run-1785968539139/task-findexec-001`,
while `run-agent.xsh` resolves the configured workdir via `Path(..).resolve()`
and compares `workdir.display()` (canonical
`/Users/josh/d/laputa-systems/.xsh-factory-worktrees/...`) against the raw
manifest string. The two differ, so `dispatch_ok` is false and the runner
aborts with `agent invocation does not match controller dispatch record` for
every attempt. The manifests for `run-1785966217772` and
`run-1785967719321` show the identical unresolved `workdir`, indicating the
same class of failure repeats across runs.

Wider context (not exhaustively re-audited, but present in sibling run
artifacts): `task-findexec-001` engineer launches have failed across multiple
organization runs — `run-1785962529677` failed with `engineer workdir is inside
the factory checkout` and later runs failed with a `runtime traceback ... at
result.propagate`. Together these are consistent, reproducible blocker
evidence that the engineer-side dispatch contract for this ticket (and by
extension the runner's path canonicalization) is not yet reliable. No engineer
has reached the product for `task-findexec-001`.

Uncertainty: I did not modify, reproduce, or re-run the runner or controller;
the reconciliation-mode instruction is to reconcile completed reports, and the
engineer never produced one. The path-canonicalization mismatch is inferred
directly from the manifest string versus the resolved path and matches the
exact abort message, but the precise controller-side writer and a confirmatory
reproduction are left to the CTO. Recommended next replay: emulate a single
engineer dispatch for `task-findexec-001` after the CTO normalizes the
`workdir` stored in the manifest to its resolved form, and confirm the agent
reaches a session.
