# CTO factory improvement

## Status

validated

The organization delivery hardening was validated before and during this
cycle; the native regression suite still passes and this cycle completed with
clean product/infrastructure outcomes.

## Change

`factory/controllers/organization.xsh` now calls
`factory/runtime.xsh::merge_validated_ticket` after each passing linked replay.
The helper verifies the exact provenance commit and branch, delivers it into
XSH `HEAD`, emits a delivery event, and makes delivery part of the product
success gate. `tests/tools_test.xsh` covers one and two independent branches.

## Throughput requirement

Engineer implementation commits: 0. This was not a throughput failure: all
six Open tickets had durable deferral markers and zero were Approved at
admission. The cycle correctly ran eval-only rather than dispatching
unsupported work.

## Provider-health attribution

Provider telemetry was present for both workers; retries and provider errors
were zero. The eval-worker had 13 structured tool errors, all retained in the
run report and manager accounting.

## Baseline metric

Prior organization cycle: one engineer commit, later merged into product
`HEAD`; evidence `runs/run-1786128115649/` and factory commit `5f6dbab`.

## Target metric

On the next organization cycle that admits a product ticket, 100% of passing
engineer rows must emit `86-ticket-*-delivered`, have the exact commit reachable
from product `HEAD`, and reconcile the ticket to `Merged.` before cycle pass.

## Validation

`xsht test` passed 115/115, including
`test_organization_delivery_merges_exact_engineer_commit` for one and two
branches. The current run also passed the infrastructure outcome in
`report.json`.

## Revert condition

If a passing organization cycle lacks a delivery event, leaves its validated
commit unreachable from XSH `HEAD`, or reports pass with an unreconciled
ticket, retain the branch, fail the cycle, and repair or revert the delivery
guard before paid work continues.

## Next-cycle disposition

Keep the hardening in place. The next admitted-ticket organization run is the
live validation of the delivery event and product-HEAD invariant.
