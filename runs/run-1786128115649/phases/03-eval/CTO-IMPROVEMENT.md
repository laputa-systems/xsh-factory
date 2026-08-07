# CTO factory improvement

## Status

validated

This eval phase validated the independent signal and preserved its provisional
handbook/ticket outputs.

## Change

`task-dupcheck` passed all eight cases and produced
`tickets/task-dupcheck-002.md`; its handbook candidate remains deferred in
`runtime/handbook-ledger.md` pending cross-eval replay.

## Throughput requirement

This phase was independent eval work; the organization cycle's engineer commit
is recorded in the primary phase.

## Provider-health attribution

Provider telemetry was present for worker and manager with zero retries and
provider errors.

## Baseline metric

Prior cycle had no independent new-ticket feed; evidence
`runs/run-1786126514242/`.

## Target metric

Next cycle: keep `task-dupcheck-002` Open with its review marker and run the
named cross-eval replay before approval.

## Validation

Check the task-dupcheck worker/evaluator/manager reports and handbook ledger
disposition before admission.

## Revert condition

If the candidate fails its cross-eval replay or the ticket loses its evidence
links, reject the candidate and retain the approved handbook.

## Next-cycle disposition

The candidate remains deferred; no new engineer admission is authorized from
this single eval alone.
