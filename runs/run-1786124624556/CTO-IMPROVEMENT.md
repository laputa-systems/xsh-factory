# CTO factory improvement

## Status

validated

## Change

The eval controller stages the XSH distribution from the path produced by
`dist-Linux-docker`, `target/<target>/dist`, and the native fixture exercises
that contract with an isolated target. See `factory/controllers/eval.xsh` and
`tests/tools_test.xsh`.

## Throughput requirement

No engineer commit was admitted: all five Open product tickets remain deferred
and there were zero Approved tickets. The eval-only cycle was the bounded
eligible plan, not a skipped approved implementation.

## Provider-health attribution

Telemetry was captured for both worker and manager; provider retries and
provider errors were zero.

## Baseline metric

The prior cycle failed before worker evidence with `missing session` because a
real build was followed by staging of the stale fixture binary. Evidence:
`runs/run-1786123936901/phases/01-eval/xsh-build.state` and `trial-1.stderr`.

## Target metric

The replay must use a real staged arm64 XSH binary and persist one worker
session, worker report, artifact, evaluator manifest, and passing phase report.

## Validation

Validated by `run-1786124624556`: `xsh-build.state` reports `toolchain=cache-hit`,
`evals/.dist/xsh` is an arm64 ELF, worker `report.json` and `run.json` are
present, all 9 evaluator cases are exact, and the phase/run results are
`pass`.

## Revert condition

Another missing session, stale non-XSH staged binary, or a mismatch between
`target/<target>/dist` and the staged image falsifies the repair; isolate
staging per run and revert the path change.

## Next-cycle disposition

No further paid infrastructure cycle is required. Preserve the one-eval/one-
trial cap if a later replay is run for the provisional handbook candidate.
