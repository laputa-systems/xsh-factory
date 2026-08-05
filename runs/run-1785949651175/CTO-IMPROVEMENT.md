# CTO factory improvement

## Status

validated

The executor repair passed the named replay: both selected evaluator paths
started and emitted populated manifests with no duplicate-mount or module-read
startup error.

## Change

The shared evaluator boundary in `eval-executor.xsh` now mounts the package
`evaluator.xsh` once at `/run/evaluator.xsh` and mounts the shared
`factory_control.xsh` separately at `/run/factory_control.xsh`. The native
suite asserts the shared mount is present. The prior run's duplicate mount
failure was preserved in `runs/run-1785947947500/`.

## Throughput requirement

This was an intentional validation cycle with zero engineer commits and zero
admitted tickets. The factory-only infrastructure ticket was not re-dispatched
into an XSH product worktree. This is not counted as product throughput; a
future factory-repository implementation path is required before that ticket
can be admitted again.

## Provider-health attribution

Provider telemetry was present for both workers. Retries were zero; provider
errors and response timing were unknown. The prior startup failures were
controller/evaluator failures, not provider instability.

## Baseline metric

Prior run `runs/run-1785947947500/report.json`: 0 evaluator manifests from two
phases because both hit `Duplicate mount point: /run/evaluator.xsh`. This run
`runs/run-1785949651175/report.json`: 1 independent eval manifest passed all
eight `task-svcstat` cases; the linked replay path was not selected because no
candidate branch existed.

## Target metric

For the next factory-repository change cycle, produce at least one reviewable
factory implementation commit and a passing linked replay. For every eval
cycle, require a populated `run.json` and zero evaluator startup errors.

## Validation

Validated with `XSH_MODULE_PATH=. xsht test` and
`runs/run-1785949651175/phases/01-eval/workers/eval-worker/task-svcstat-1/run.json`:
`result=pass`, `correctness.all_exact=true`, `restrictions.passed=true`, and
`protocol.artifact_present=true`. Both selected evaluator stderr files are
empty.

## Revert condition

If a future evaluator trial reports `Duplicate mount point` or
`parse.module-read`, revert the executor mount change and repair it with a
synthetic Docker-argument test before spending again. If a factory-only ticket
is routed to an XSH worktree, stop admission and restore the no-dispatch gate.

## Next-cycle disposition

Validated by the next-cycle evidence above. The next CTO should choose either a
factory-repository implementation path for the infrastructure ticket or a
separate evidence-backed XSH ticket; it should not manufacture an engineer row
for a factory-only change.
