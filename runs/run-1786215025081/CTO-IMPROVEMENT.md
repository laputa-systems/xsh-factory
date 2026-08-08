# CTO factory improvement

## Status

validated

`validated` means the named factory change met its target in this cycle and is
retained for future cycles.

## Change

Validated the cycle-26 throughput compromise: task-histogram now accepts the
typed `parse_uint` restriction path, and retained replay rows are explicitly
marked so only their manager receives the 300-second closeout ceiling. The
wiring is in `factory/control.xsh`,
`factory/controllers/organization.xsh`, and `factory/controllers/eval.xsh`;
the restriction repair is in `evals/task-histogram/evaluator.xsh`, with native
coverage in `tests/factory_control_test.xsh` and `tests/tools_test.xsh`.

## Throughput requirement

The cycle produced one fresh reviewable engineer implementation and delivered
two engineer commits: `b25b06df` (fresh) and `b9cc3ffc` (retained). The fresh
delivery gate was satisfied before retained replay closeout.

## Provider-health attribution

Provider telemetry was captured. No provider errors or retries explain the
remaining latency; the evidence points to repeated isolated XSH image/build
work.

## Baseline metric

Cycle 26 baseline: 1 fresh row, 0 deliveries, 0 passing replays, `$0.123247`,
and 177 turns in `../run-1786212430316/report.json`.

## Target metric

Cycle 27 result: 2 deliveries, 2 passing replays, 1 retained fast path,
`delivery_conversion=1.0`, `$0.103835`, and 142 turns in `report.json`.

## Validation

The cycle-27 organization request validated the named fields in
`report.json`, the two replay `report.json` files, and ordered `86-ticket-*`
events. The next cycle must preserve those checks while measuring the replay
build/image cache hit and elapsed build evidence.

## Revert condition

Falsify this compromise if a fresh replay is shortened, bypassed, or fails to
produce the required evaluator/provenance evidence, or if retained replay
still exceeds its bounded closeout without a retry marker. Restore the prior
manager ceiling and investigate the specific replay path.

## Next-cycle disposition

Keep this compromise validated. The next pending improvement is safe reuse of
a validated XSH image/build artifact across overlapping replays; revert it if
cache reuse changes the image identity or weakens fresh replay validation.
