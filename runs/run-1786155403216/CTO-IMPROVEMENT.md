# CTO factory improvement

## Status

pending-validation

`pending-validation` means the CTO has already implemented this change. It is
not awaiting another approval; the next cycle verifies the named metric or
applies the safe inverse.

## Change

The throughput change is implemented in `factory/controllers/organization.xsh`
and `factory/runtime.xsh`: one organization batch can carry one retained
implementation branch alongside fresh ticket work, reuse validates the retained
branch, and delivery accepts its verified historical merge base without
creating a duplicate engineer row. `evals/task-pathparts/evaluator.xsh` and its
contract now accept the lint-preferred typed-Path spelling. The engineer input
boundary is tightened in `factory/controllers/ticket.xsh`,
`templates/ENGINEER-ASSIGNMENT.md`, and `roles/engineer.md`: engineers receive
run-scoped copies of the North Star and handbook, so a mistaken handbook edit
cannot mutate live factory source during paid work. `tests/tools_test.xsh`
contains the regression and batching contracts.

## Throughput requirement

This cycle produced one candidate engineer branch (`d917d6d` for
`task-trim-002`), but zero validated or delivered product commits. The
organization cycle is therefore a throughput failure: the source-integrity
guard stopped reevaluation after the worker edited the live handbook, and the
candidate's native test also failed. The corrective change is the run-scoped
guidance boundary plus the retained/fresh mixed batch described above.

## Provider-health attribution

Provider telemetry was captured for the engineer: 32 turns, zero retries, and
four tool errors are recorded in the worker report. No provider-health failure
is indicated; the failure was factory-source mutation and a product test
failure.

## Baseline metric

Prior cycle: zero delivered product commits, four workers, 71 assistant turns,
and $0.048677; `task-pathparts-001` passed correctness but failed its
restriction gate. Evidence: `../run-1786151585420/CTO-REPORT.md` and
`../run-1786151585420/report.json`.

## Target metric

Next cycle target: deliver at least one validated product commit, and preferably
both approved tickets (two commits) from the retained-plus-fresh batch, with no
factory-source mutation and all linked replay reports present.

## Validation

Run the documented organization request once. Check `report.json` for a
passing result, product delivery, and phase completion; verify the engineer
commit count and merged XSH `HEAD`, then confirm the run-scoped guidance test
and `xsht test` remain green.

## Revert condition

If the next cycle still reports `factory source changed` with the new guidance
paths, or produces zero validated commits despite a clean worker boundary,
revert the mixed retained/fresh dispatch and historical-merge changes to the
prior single-ticket/reuse path while retaining the guidance snapshot fix. If a
delivered retained branch fails merge-base verification, disable retained
batching until the branch ancestry contract is repaired.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted`
after running the named verification, and link the evidence before admitting
paid work.
