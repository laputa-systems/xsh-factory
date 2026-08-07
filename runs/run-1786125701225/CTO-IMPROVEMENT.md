# CTO factory improvement

## Status

validated

## Change

Restored a normal-intensity organization request in
`templates/ORGANIZATION-REQUEST-NORMAL.md` with default role settings and the
next untried eval, `task-colsum`. Dispositioned the prior single-trial
handbook candidate in `runtime/handbook-ledger.md` as deferred, so unresolved
lineage cannot block or silently influence admission.

## Throughput requirement

No engineer commit was admitted because all five Open histogram tickets still
require focused replay evidence and there were zero Approved tickets. This was
an explicit admission gate, not inferred work.

## Provider-health attribution

Worker and manager telemetry were present with zero provider retries or errors.

## Baseline metric

Before this cycle, paid admission was blocked by one undispositioned handbook
candidate. The prior passing eval used 29 worker turns and 25 manager turns.

## Target metric

Normal requests must pass handbook disposition and admission checks, run the
next untried eval with default settings, and preserve complete evidence for the
next ticket approval review.

## Validation

`run-1786125701225` passed after the ledger disposition: one `task-colsum`
trial, 9/9 exact cases, worker artifact/report/review, evaluator manifest, and
phase/run results all passed.

## Revert condition

If normal admission accepts an unresolved candidate, selects a previously
tried eval, or loses the worker/evaluator evidence packet, revert the request
or ledger change and repair the admission gate before paying again.

## Next-cycle disposition

To obtain engineer commits, first run the focused `task-histogram` replay named
by the five ticket deferrals; approve only tickets whose gates pass.
