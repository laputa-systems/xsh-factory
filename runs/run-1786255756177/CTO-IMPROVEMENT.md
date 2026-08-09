# CTO factory improvement

## Status

pending-validation

## Change

Aligned the final eval-manager recovery prompt in
`templates/EVAL-MANAGER-RETRY.md` with the five mandatory first reads already
required by `roles/eval-manager.md` and
`templates/EVAL-MANAGER-ASSIGNMENT.md`. The retry no longer asks an agent to
read a staged skeleton before its required evidence packet; after all five
admission reads its next call must draft that known report path. The static
contract in `tests/tools_test.xsh::test_eval_gate_diagnostics_are_persisted`
now asserts the five-read sequence, direct draft requirement, and continued
ban on raw/worker investigation before the draft.

## Throughput requirement

One engineer created a reviewable candidate commit, but no ticket merged, so
eligible delivery throughput is zero. The failed replay-manager closeout—not
worker correctness—blocked delivery. This prompt repair targets that specific
commit-to-replay bottleneck.

## Provider-health attribution

Provider telemetry was captured for every worker. The first supply manager
reported one recovered `Stream ended without finish_reason`; the failed replay
manager retry had no provider error but stopped after its initial read batch.
The deterministic contradictory prompt is sufficient evidence for the repair;
provider health is a contributing uncertainty, not the root cause assigned to
the next validation.

## Baseline metric

`run-1786255756177` had one passing linked evaluator but
`phases/02-reeval-task-envcfg-008/report.json` set
`required_outputs.manager_report: false`, making re-evaluation and delivery
fail despite `ticket_replay.error_fail_reference_passed: true`.

## Target metric

On the next candidate-linked replay, the manager completes its first draft
after the required five reads or its one recovery does; the phase records
`required_outputs.manager_report: true` and reaches `result: pass` without a
second evaluator dispatch.

## Validation

Before the next paid admission, retain the passing `xsht test` result. In the
next eligible delivery run, inspect the linked phase `report.json`, its manager
session ordering, and root throughput: `manager_report` must be true,
`reeval_passed` must be one, and `delivered_tickets` must be one.

## Revert condition

If a manager that receives the aligned prompt again leaves its draft
`not-ready`, retain the evidence and replace the recovery's qualitative first
draft with a controller-created structured draft for manager refinement; do
not add more competing prose or additional paid retries.

## Next-cycle disposition

The next CTO marks this `validated` only when the named linked replay completes
with a valid manager report and merged delivery; otherwise mark it `reverted`
and apply the controller-owned draft inverse.
