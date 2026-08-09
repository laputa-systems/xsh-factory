# CTO factory improvement

## Status

pending-validation

`pending-validation` means the CTO has already implemented this change. It is
not awaiting another approval; the next cycle verifies the named metric or
applies the safe inverse.

## Change

Correct the shared `runtime/handbook.md` validation-failure guidance to name
the existing `error.fail("message")?` operation and preserve the distinction
from a nonexistent bare `Error(...)` constructor. Add the package-owned,
ticket-specific `task-envcfg-008` API-reference gate in
`evals/task-envcfg/evaluator.xsh`, document it in `evals/task-envcfg/EVAL.md`,
and protect the contract with
`tests/tools_test.xsh::test_task_envcfg_error_fail_replay_checks_the_api_reference`.
This is reusable factory infrastructure: every employee receives the corrected
handbook, while a product-reference ticket proves its own discovery contract
without contaminating ordinary discovery runs.

## Throughput requirement

This cycle produced zero reviewable engineer implementation commits and is a
throughput failure. No eligible ticket was available at admission. The concrete
corrective outcome is one reviewed, branchless Approved ticket
(`task-envcfg-008`) with a discriminating replay, not a quota-created ticket.

## Provider-health attribution

Provider telemetry was captured for all three preserved worker reports. No
provider retry was recorded; provider-error attribution is `unknown`. The
manager report-completion recovery is therefore treated as controller/role
closeout cost, not a provider or product regression.

## Baseline metric

`runs/run-1786254016688/report.json` records zero approved tickets before CTO
review, zero admitted tickets, zero engineer rows, and zero deliveries. The
baseline product mismatch is reproducible at XSH
`e2a609a94d8f624b8dc7cc1efae62a2691d3cbc8`:
`xsht api api:error.fail` reports `status: missing` despite `docs/SPEC.md` and
`tests/xsh/stdlib/test.xsh` documenting and testing the operation.

## Target metric

In the next eligible organization cycle, one newly dispatched engineer produces
one reviewable commit; its linked replay records
`ticket_replay.error_fail_reference_required: true` and
`ticket_replay.error_fail_reference_passed: true`; and the low-water policy
dispatches exactly one independent supply eval. The supply finding is reviewed
on evidence, with no automatic approval claim.

## Validation

Before admission, run `../xsh/target/debug/xsht test` and inspect the approved
ticket. Run only the documented organization request through `run.xsh`. At
closeout, inspect the linked evaluator `run.json`, root
`report.json:data.throughput`, the supply events, the engineer provenance
event, and the merge/replay outcome. The focused native replay-contract test
and the full factory suite must remain green. The fresh product debug build and
`target/debug/xsht lint --fix` must exit cleanly; current cleanup evidence is
product commit `7b4bee1a1cef74fed832331cd6cc5bb6e324c4ee`.

## Revert condition

If a candidate build resolves the API entry but the entry misstates the
existing runtime contract, or if the ticket-specific probe causes ordinary
task-envcfg discovery to fail or gate unrelated tickets, revert the package
gate and handbook wording, leave the product ticket Open, and replace the
probe with a canonical product API test that matches the actual reference
contract. If the independent supply lane mutates the delivery snapshot or
prevents a passing merge, apply the documented safe inverse: disable that
supply launch until its process/snapshot boundary has a native regression.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` only after the
linked API gate, delivery transaction, and isolated low-water supply lane have
all produced the evidence above; otherwise mark it `reverted` with the failed
boundary and safe inverse before a later paid admission.
