# CTO factory improvement

## Status

pending-validation

## Change

The ticket controller previously created engineer worktrees under
`runs/<run>/worktrees`, inside the factory checkout. The shared runner rejects
that boundary, so `task-findexec-001` never started. The CTO moved ticket
worktree calculation to the adjacent product-parent scratch root through
`factory/runtime.xsh::ticket_worktree_root` and updated the ticket, reuse, and
organization controllers to use it. Cleanup remains run-scoped and preserves
branches.

## Throughput requirement

Zero reviewable engineer commits were produced: the ticket phase failed before
Pi launch because the worktree was inside the factory checkout. This is a
throughput failure caused by factory admission, not an engineer failure.

## Provider-health attribution

Provider telemetry was present for the three workers that ran; retries were
zero. The engineer had no session, so this failure is infrastructure-only.

## Baseline metric

Run `runs/run-1785962529677/report.json`: one approved ticket, zero engineer
commits, and a failed ticket phase. The director report identifies the
worktree-boundary rejection.

## Target metric

The next organization cycle must produce one engineer worker report, one
non-baseline engineer commit, and one passing linked replay for
`task-findexec-001`, with no worktree-boundary launch failure.

## Validation

Run `XSH_MODULE_PATH=. xsht test`, then run one organization cycle and verify
that the engineer worktree is outside `FACTORY_DIR`, the worker report and
portable patch exist, and the linked replay passes.

## Revert condition

If the next cycle cannot create or clean the adjacent scratch worktree, or if
cleanup removes evidence or branches, revert the placement change and repair
the path/cleanup contract with a focused native test before paid work.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted`
after the named verification and link the evidence before admitting paid work.
