# CTO factory improvement

## Status

validated

This eval phase validated the existing controller/evidence path; no factory
code change was required.

## Change

The phase used the focused request at
`templates/ORGANIZATION-REQUEST-HISTOGRAM-FOCUSED.md`, ran one
`task-histogram` trial with normal role defaults, and preserved the worker,
evaluator, manager, lineage, and report evidence.

## Throughput requirement

No engineer commit was produced in this eval-only phase. The phase supplied
the evidence needed to approve exactly one product ticket for the next cycle.

## Provider-health attribution

Both worker reports contain provider telemetry with zero retries and provider
errors; the manager report has two nonzero tool results, both documented in
the generated CTO report.

## Baseline metric

Prior cycle: `runs/run-1786125701225/` passed without an approved ticket.

## Target metric

Next cycle: one engineer row for `task-histogram-003`, with a reviewable commit
and complete provenance evidence.

## Validation

Check this phase's `report.json` and evaluator manifest for `pass`, then check
the next ticket phase's engineer report, commit, patch hash, and clean
worktree.

## Revert condition

Any missing session/report/manifest, invalid engineer provenance, or extra
admitted ticket falsifies the transition; revert the approval and repair the
admission gate.

## Next-cycle disposition

The next CTO can proceed with the one-ticket admission after this run is
closed and its evidence committed.
