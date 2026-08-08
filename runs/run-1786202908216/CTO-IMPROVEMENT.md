# CTO factory improvement

## Status

pending-validation

`pending-validation` means the CTO has already implemented this change. It is
not awaiting another approval; the next cycle verifies the named metric or
applies the safe inverse.

## Change

Cycle 23 exposed a second replay bottleneck after the prior acceptance-gate
repair. The CTO expanded `reeval_manager_acceptance_gate` to recognize the
manager's explicit exercised/accepted-for-merge language, added the
template-backed bounded retry at `templates/EVAL-MANAGER-RETRY.md`, and made
completed child registrations disappear from run introspection. POSIX `Z`
processes are also excluded by `factory/tools/run-status.xsh`.

## Throughput requirement

Cycle 23 produced one reviewable engineer implementation commit but delivered
zero; classify it as a throughput failure. The corrective change is the
replay/manager repair above, and the hard target remains at least one delivered
engineer commit in the next cycle.

## Provider-health attribution

Provider telemetry was present with zero reported retries; provider-error
details were not fully available, so latency attribution remains `unknown`.

## Baseline metric

Cycle 22: one retained delivery, zero fresh deliveries; see
`runs/run-1786201137236/report.json` and its productivity report.

## Target metric

Cycle 24: at least one delivered engineer commit, with linked replay acceptance
and manager report gates true.

## Validation

Run the canonical organization request through `run.xsh`; verify
`report.json.data.throughput.delivered_tickets >= 1`,
`delivery_conversion > 0`, and each delivered linked phase has
`candidate_acceptance: true` and `manager_report: true`. Focused native checks
for the machinery already pass: 30 control tests, run-status, and eval-gate
contract tests.

## Revert condition

If the next run again produces a reviewable engineer commit but zero delivery,
or a valid manager report is still rejected, treat the repair as falsified:
retain branches and evidence, stop batching additional replay pressure, and
revert only the specific acceptance/retry change after isolating the failing
fixture.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted`
after running the named verification, and link the evidence before admitting
paid work.
