# Cycle request: replay repair and fresh product pressure

Run one bounded organization cycle after `run-1786202908216`. Cycle 23
produced a valid fresh histogram implementation but delivered zero because the
linked replay manager gate did not recognize explicit exercised/accepted
language and a bounded manager retry left its report skeleton incomplete.
Cycle 24 must validate the replay repair and deliver at least one engineer
implementation commit.

## Bottleneck review

The CTO repaired the candidate acceptance gate, added a concise template-backed
manager retry, and tightened process introspection. Focused native tests pass.
The retained `task-histogram-007` branch is the first delivery candidate;
`task-grep-001` is a newly approved product ticket and provides fresh engineer
work. Review any valid pending implementation branch and let it through when
the controller's report, replay, patch, and provenance gates pass.

## Mode

- `organization`

## Eval admission

- Approved evals: `task-bigfiles`
- Trial count: `1`
- Measured reuse: `yes`

## Ticket admission

- Policy: `approved`
- Approved tickets: `task-histogram-007`, `task-grep-001`

## Role overrides

Use the adaptive defaults codified by the factory. Keep at least one engineer
row while approved product pressure exists; use one independent eval for this
ticket cycle.

## Required outputs

- at least one delivered engineer implementation commit;
- linked replay `manager_report: true` and `candidate_acceptance: true`;
- independent eval pass;
- unchanged pre-existing ticket snapshot, structured reports, raw sessions,
  patches, provenance trailers, and run-level `report.json`;
- product, evaluator, infrastructure, and overall cycle outcomes.

## CTO handoff

Complete `CTO-PRODUCTIVITY-REPORT.md` and `CTO-IMPROVEMENT.md` from the
resulting evidence. Mark the improvement `validated` only if the delivery
target and replay gates hold.
