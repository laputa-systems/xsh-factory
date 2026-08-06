# CTO factory improvement

## Status

validated

## Change

The ticket controller now places engineer worktrees in the adjacent
product-parent scratch root, canonicalizes worktree and dispatch paths before
writing/checking manifests, and binds the engineer eval identity explicitly.
The focused regression `tests/tools_test.xsh::test_ticket_worktree_is_outside_factory_checkout`
and the full native suite (83/83) pass.

## Throughput requirement

The validation cycle produced one reviewable engineer implementation commit,
`500a9a6a6dcc82b8ba70be4c2bd3e4afcf5ede50`, after the baseline's zero-commit
worktree-boundary failure.

## Provider-health attribution

Provider telemetry was present for all six workers in the validation cycle;
retries and provider errors were zero. Agent tool errors remain structured and
are not attributed to provider health.

## Baseline metric

`runs/run-1785962529677/report.json`: one admitted ticket, zero engineer
commits, and a worktree-inside-factory launch failure.

## Target metric

One engineer report, one non-baseline commit, a portable patch, and a passing
linked replay with the worktree outside `FACTORY_DIR`.

## Validation

`runs/run-1785973900575/report.json` passed product, evaluator, and
infrastructure outcomes. It contains the engineer report, portable patch,
linked replay, and independent eval. The product worktree was outside the
factory and cleaned while the branch/evidence were preserved.

## Revert condition

Revert only if a future native regression or organization run shows an
in-factory worktree, a raw/canonical dispatch mismatch, or cleanup loss of
branch/evidence; repair the boundary with a focused test before paid work.

## Next-cycle disposition

Validated; retain the path-boundary regression and canonical dispatch checks.
