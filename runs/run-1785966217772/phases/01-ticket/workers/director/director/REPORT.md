# Director report

## Result

fail

## Cycle

Mode: `ticket-implementation`. Controller-selected plan: implement exactly one
approved ticket, `task-findexec-001` (product target), in one isolated XSH
worktree on branch `factory/task-findexec-001/1785966218990` at base commit
`1cf4ad3d7ee5fde9b3160b11d8073cbd7ce5e7c4`. The controller launched the single
admitted engineer row concurrently and directed the director to reconcile
(`FACTORY_DIRECTOR_RECONCILE_ONLY`). XSH main commit resolved:
`1cf4ad3d7ee5fde9b3160b11d8073cbd7ce5e7c4`.

The engineer row crashed at process launch before Pi ever started. No
implementation was produced and no report was written, so the cycle cannot be
closed as ready.

## Children

One controller-dispatched engineer row was expected:

| Child | Result | Evidence path |
| --- | --- | --- |
| engineer / task-findexec-001 | fail (launch-time crash; no report, no commit) | `phases/01-ticket/engineer-task-findexec-001.stderr`, `worktrees/task-findexec-001.*`, worktree `../.xsh-factory-worktrees/run-1785966217772/task-findexec-001` (HEAD still at base `1cf4ad3`, no implementation commit) |

No engineer `REPORT.md` exists at
`workers/engineer/task-findexec-001/REPORT.md` (staged site is empty); no
implementation branch commit was created; the worktree still tracks only the
base commit. No other child rows were dispatched.

## Required-output status

- Engineer `REPORT.md` with `## Result: ready-for-review` —
  **missing / failed.** The staged fail-closed report location is empty; the
  worker never ran.
- Implemented product change committed on branch
  `factory/task-findexec-001/1785966218990` — **missing.** No commit beyond
  base `1cf4ad3`.
- Native regression coverage and canonical documentation per ticket — **missing.**

Root cause is a factory-infrastructure launch failure: `factory/entrypoints/run-agent.xsh`
line 77, `if role == "engineer" and canonical_paths.within(factory_dir, workdir)?`,
raises `normalized-path: types.DomainError.InvalidFormat` (via `?` propagate)
because the engineer `workdir`/`product_root`
(`/Users/josh/d/laputa-systems/xsh-factory/../.xsh-factory-worktrees/run-1785966217772/task-findexec-001`)
contains a `..` component that the canonical path normalization cannot format.
The engineer process terminated before authoring any artifact. This is a CTO
(controller/launcher) defect, not a product result and not a ticket-selection
or scope issue.

## North-star impact

The XSH `if`/`else` tail-position asymmetry (the durable product hypothesis
this ticket was admitted to fix) is **untested this cycle**: no engineer
evidence was gathered and no product change was made, so the bind-then-tail
workaround remains unaddressed. The cycle contributes no new XSH product
signal.

The durable lesson is factory infrastructure: the launch-time
`canonical_paths.within(factory_dir, workdir)` guard in `run-agent.xsh` is not
robust to an engineer workdir expressed with a `..` segment (the standard
`<factory>/../.xsh-factory-worktrees/...` layout used by the admission/placement
code), and the `?`-propagated `InvalidFormat` aborts the worker before it can
even report an assignment mismatch. This is a clean, reproducible,
infrastructure-only observation for the CTO: normalize (lexically resolve) the
workdir before the `within` check, or catch/propagate `InvalidFormat` as a
guarded `false` plus a clear diagnostic, then re-run the admitted ticket. It is
not a product change and should not reopen or re-dispatch this ticket within
this cycle.
