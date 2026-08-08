# CTO factory improvement

## Status

pending-validation

## Change

This run validated the epoch-unit repair in `factory/tools/session-watch.xsh`
but falsified its initial 60-second manager idle threshold. The evaluator
manager received a controller-prepared packet and remained silent on the
session file for just over 60 seconds while processing it. The first attempt
was terminated at `60010ms >= 60s`; the one allowed recovery attempt then
reached its 180-second wall bound. The manager gate remained fail-closed.

The deterministic policy is now widened to a 120-second idle bound through
`factory/control.xsh`. It remains below the normal 300-second manager wall
bound and the 180-second recovery wall bound, so it allows one slow provider
turn without creating an unbounded second attempt.

## Throughput requirement

This was not a fresh-eligible cycle: one retained product branch was admitted.
It delivered zero commits because manager acceptance could not be proven. The
linked evaluator itself passed correctness, restrictions, and protocol, so the
branch remains a strong delivery candidate for a subsequent bounded replay.

## Provider-health attribution

Provider telemetry was present for the evaluator and two manager attempts.
There were no reported provider retries or provider errors. The manager
latency is an observed closeout duration, not a quality override; the factory
changed only the deterministic idle threshold and retained the wall/turn
ceilings.

## Baseline metric

The epoch conversion passed: idle evidence was approximately 60 seconds,
not the prior 56-year-scale value. However, the 60-second threshold caused
both the normal manager and its bounded recovery path to fail before a
decision. Evidence: the phase's two `SESSION-LIMIT` markers and
`report.json.data.required_outputs`.

## Target metric

On the next replay, the manager must either complete a non-skeleton report and
explicit acceptance within the 120-second idle/300-second wall bounds, or
produce a structured timeout at the new bound while preserving the branch.
The evaluator gates must remain unchanged.

## Validation

Run `xsht test --jobs 1`. In the next organization phase inspect the manager
worker report, `SESSION-LIMIT` markers, `required_outputs`, and exact
acceptance line. A passing evaluator with a complete manager report should
proceed to provenance and retained merge; a timeout must remain non-delivery.

## Revert condition

Revert 120 to 60 only if a completed run demonstrates that managers reliably
complete within 60 seconds without premature termination, or if 120 allows a
provider/harness stall to consume the full wall bound. The safe inverse is the
previous capped value plus the same epoch-millisecond conversion.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted`
after inspecting the next manager closeout evidence.
