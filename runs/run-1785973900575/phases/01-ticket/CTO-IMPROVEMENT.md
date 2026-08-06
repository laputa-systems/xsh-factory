# CTO factory improvement

## Status

pending-validation

`pending-validation` means the CTO has already implemented this change. It is
not awaiting another approval; the next cycle verifies the named metric or
applies the safe inverse.

## Change

Describe the concrete factory-wide code, prompt, controller, test, or policy
change and link the exact paths.

## Throughput requirement

State whether the cycle produced at least one reviewable engineer
implementation commit. If not, classify the cycle as a throughput failure and
describe the corrective factory change; a passing eval-only cycle does not
satisfy this requirement when an eligible product ticket existed.

## Provider-health attribution

State whether provider telemetry was captured. Do not treat latency as an agent
regression when retry, provider-error, or response-timing evidence indicates an
external provider-health issue; if telemetry is missing, state `unknown`.
satisfy this requirement when an eligible product ticket existed.

## Baseline metric

State the prior-cycle measurement and evidence path.

## Target metric

State the measurable result expected in the next cycle.

## Validation

State the exact next-cycle command, report field, or invariant that will be
checked.

## Revert condition

State the evidence that falsifies the change and the safe inverse action.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted`
after running the named verification, and link the evidence before admitting
paid work.
