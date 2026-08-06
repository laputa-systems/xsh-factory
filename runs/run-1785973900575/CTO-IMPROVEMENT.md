# CTO factory improvement

## Status

validated

## Change

The controller now creates ticket worktrees in the adjacent product-parent
scratch root, canonicalizes worktree and dispatch paths before writing and
checking manifests, and binds the engineer eval identity explicitly. The
focused regression `tests/tools_test.xsh::test_ticket_worktree_is_outside_factory_checkout`
and the full native suite (83/83) pass. End-to-end evidence is
`runs/run-1785973900575/report.json`: the engineer started, produced a commit,
and the organization cycle passed all product, evaluator, and infrastructure
dimensions.

## Throughput requirement

The cycle produced one reviewable engineer implementation commit,
`500a9a6a6dcc82b8ba70be4c2bd3e4afcf5ede50`, after the prior run's zero-commit
worktree-boundary failure.

## Provider-health attribution

Provider telemetry was present for all six workers, with zero retries and no
provider errors. Agent tool errors are retained in the structured reports and
are not attributed to provider health.

## Baseline metric

Prior baseline: `runs/run-1785962529677/report.json` had one admitted ticket,
zero engineer commits, and a worktree-inside-factory launch failure.

## Target metric

Target achieved: one engineer report, one non-baseline commit, a portable
patch, and passing linked replay with the worktree outside `FACTORY_DIR`.

## Validation

Validated by `XSH_MODULE_PATH=. xsht test` (83/83) and the passing organization
report at `runs/run-1785973900575/report.json`; the next cycle should preserve
the canonical-path dispatch invariant.

## Revert condition

Revert only if a future native regression or organization run shows a product
worktree inside the factory checkout, a raw/canonical dispatch mismatch, or
cleanup loss of the branch/evidence; then restore the previous implementation
only alongside a focused boundary repair.

## Next-cycle disposition

The worktree boundary is validated; retain the path regression and use the
passing run as the durable handoff.
