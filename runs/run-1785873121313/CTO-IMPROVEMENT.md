# CTO factory improvement

## Status

pending-validation

`pending-validation` means the CTO has already implemented this change. It is
not awaiting another approval; the next cycle verifies the named metric or
applies the safe inverse.

## Change

The prior throughput guardrails were insufficient: the cycle admitted and
reused a stale implementation branch, produced no new engineer commit, and
failed its linked replay. The corrective factory change is the mandatory
productivity report and explicit stale-branch warning in
`runs/run-1785873121313/CTO-PRODUCTIVITY-REPORT.md`.

## Throughput requirement

This cycle produced one reused reviewable commit (`91e0eaa`) but zero new
engineer dispatches, zero new engineer commits, and zero XSH-main product
commits. Classify the cycle as a throughput failure. The ticket was returned to
`Open.` because the branch did not include the API-registration dependency.

## Baseline metric

Prior cycle `runs/run-1785869846042`: 0 engineer commits, 55 turns,
$0.036831, cycle pass. This cycle: 0 new engineer commits, 120 turns,
$0.094041, cycle fail. Evidence: `CTO-PRODUCTIVITY-REPORT.md` and
`report.json`.

## Target metric

The next organization cycle must produce at least one new engineer commit,
pass its linked replay, and land or present a reviewable current-HEAD product
change without reusing a stale dependency-incomplete branch.

## Validation

Inspect the next run's `CTO-PRODUCTIVITY-REPORT.md` and
`phases/01-ticket/report.json`: require `new engineer commits >= 1`, a passing
linked replay, and no stale-branch dependency mismatch. Also verify the run's
product outcome is `pass`.

## Revert condition

If the next cycle again reports zero new engineer commits, a reused stale branch,
or a failed linked replay caused by an omitted dependency, treat this change as
ineffective and require a controller-level branch-admission fix before another
paid cycle.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted`
after running the named verification, and link the evidence before admitting
paid work.
