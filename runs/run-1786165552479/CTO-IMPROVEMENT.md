# CTO factory improvement

## Status

validated

`pending-validation` means the CTO has already implemented this change. It is
not awaiting another approval; the next cycle verifies the named metric or
applies the safe inverse.

## Change

The factory now has a read-only run inspector at
`factory/tools/run-status.xsh`. It reads structured reports, lifecycle events,
adaptive queue allocation, worker metrics, registered process state, and budget
markers in table or JSON form. Native coverage is in
`tests/tools_test.xsh::test_run_status_inspects_live_and_completed_evidence`.
The eval-manager contract and `factory/controllers/eval.xsh` also preserve
pre-existing ticket identities with a controller-side hash snapshot; the
regression is covered by `test_ticket_snapshot_rejects_existing_ticket_mutation`.
The repeated `task-bigfiles` candidate was promoted into the shared handbook
with its ledger disposition before paid admission.

## Throughput requirement

Met. The cycle produced one reviewable engineer implementation commit,
`9bbc473af32e20e7bb3fa9b967a51acd89eb5200`, and delivered it to XSH `HEAD`
after the linked replay passed. The report records one admitted and one
delivered ticket with conversion `1.0`.

## Provider-health attribution

Captured. All six worker reports include provider telemetry; retry counts are
zero and no provider errors were recorded. The cycle's 23 tool errors are
agent/tooling evidence, not provider-health evidence.

## Baseline metric

Cycle 2 delivered one of one admitted tickets at `$0.134731785`, 172 assistant
turns, and six workers (`runs/run-1786163685229/report.json`). Its throughput
gate passed, but ticket status was not yet protected from manager filename
collisions and CTO inspection still relied on manual evidence traversal.

## Target metric

Preserve one engineer delivery per eligible organization cycle with conversion
`1.0`, while reducing paid cost to at most `$0.15` and making the inspector's
active-process section account for every live registered phase/worker process.

## Validation

This cycle validated the machinery with `xsht test` (129 passed before paid
admission), the focused inspector/snapshot tests, and the final inspector run:
`XSH_MODULE_PATH=. xsh factory/tools/run-status.xsh -- --run-dir
runs/run-1786165552479`. The run report confirms `product`, `evaluator`, and
`infrastructure` all pass, and `data.throughput.delivered_tickets == 1`.

## Revert condition

Revert only the new inspector/guard if native tests fail, if it mutates durable
run state, or if it blocks a manager that created only a fresh ticket identity.
If active-process coverage remains incomplete, retain the read-only report and
repair its liveness enumeration before the next paid cycle.

## Next-cycle disposition

Validated in cycle 3. Keep the adaptive delivery gate and cost target for the
next cycle; repair active-process enumeration before relying on that section
for live-run decisions.
