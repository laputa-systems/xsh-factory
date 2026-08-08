# CTO factory improvement

## Status

implemented-pending-validation

`pending-validation` means the CTO has already implemented this change. It is
not awaiting another approval; the next cycle verifies the named metric or
applies the safe inverse.

## Change

The task contract in `evals/task-bigfiles/runtime/task.md` now explicitly
requires every regular file, including dot-prefixed directories and dot-
prefixed regular files. `evals/task-bigfiles/EVAL.md` mirrors that contract,
and `tests/tools_test.xsh` asserts the task wording. This follows the
cycle-16 evaluator result instead of modifying the acceptance gate: the
`.hidden-note` fixture remains in the package evaluator, and the manager still
must verify that the worker selected `hidden: true` from the contract.

## Throughput requirement

Cycle 16 delivered zero retained commits and is a throughput failure. Cycle 17
must deliver the retained branch; no duplicate engineer row is authorized.

## Provider-health attribution

Provider telemetry was present for all four workers. There was no aggregate
budget breach or provider retry signal. The failure was reproducible evaluator
correctness on `hidden_default`, not provider health or a controller false
negative.

## Baseline metric

Cycle 16: `retained_rows=1`, `delivered_tickets=0`,
`delivery_conversion=0.0`; both eval workers omitted hidden entries and failed
the strengthened case. See each phase `run.json`.

## Target metric

Cycle 17 must achieve `delivered_tickets >= 1`,
`delivery_conversion=1.0`, linked `candidate_acceptance=true`, and all phase
required-output/manager-report gates true.

## Validation

Run `templates/ORGANIZATION-REQUEST-CYCLE-17.md`; inspect the worker artifact
for `hidden: true`, the `.hidden-note` correctness result, and final commit
provenance.

## Revert condition

If a worker follows the explicit task contract and uses `hidden: true` but the
candidate still fails while the oracle passes, revert the task-contract
addition only after preserving a focused evaluator regression. If a worker
still omits `hidden: true`, keep delivery blocked and repair the worker-facing
contract or handbook evidence.

## Next-cycle disposition

The next CTO must replace this status with `validated` or `reverted` after
cycle 17 and link the evidence before admitting the following cycle.
