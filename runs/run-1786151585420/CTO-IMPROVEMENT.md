# CTO factory improvement

## Status

validated

## Change

The source-pinned controller boundary and organization delivery-result fix were
exercised on a second retained-branch cycle. Both phase source pins matched the
run pin `3c8449a66d84e0f27ad104b59d60a0054e355af50871edef1d7818164a7b8bb9`, and
the controller correctly reported a product/evaluator failure when the linked
pathparts restriction gate failed.

## Throughput requirement

One retained implementation was reviewed, but zero product commits were
delivered because `task-pathparts` failed its restriction gate. The independent
`task-trim` eval passed.

## Provider-health attribution

Provider telemetry was captured; no budget breach or infrastructure failure
caused the result. The linked worker's evaluator result was
`restriction_failed` with `path_referenced: false`.

## Baseline metric

The prior cycle delivered one retained engineer commit after the delivery
accounting fix (`runs/run-1786150322831/`).

## Target metric

The next pathparts cycle must deliver one product commit only after correctness
and restriction gates both pass; the controller terminal event must remain
consistent with the structured report.

## Validation

This run validates the negative path in `report.json`: infrastructure passed,
the independent eval passed, and the linked phase failed with a valid evaluator
classification while the branch and product HEAD were preserved.

## Revert condition

If a future cycle reports a controller failure while all phase and delivery
evidence pass, investigate result accounting before any paid retry. If the
pathparts restriction remains false, retain the branch and require a scoped
product/evaluator correction.
