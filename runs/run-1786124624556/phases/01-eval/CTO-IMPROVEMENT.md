# CTO factory improvement

## Status

validated

## Change

The eval controller now stages from `target/<target>/dist`, which matches the
cross-build Make target; the fixture tests that path with an isolated target.

## Throughput requirement

No engineer commit was admitted because there were zero Approved tickets; all
five Open histogram tickets remain deferred.

## Provider-health attribution

Worker and manager provider telemetry was captured with zero retries and zero
provider errors.

## Baseline metric

The prior cycle had a real build but no worker session because it staged a
1,041-byte shell double from the former path.

## Target metric

One replay must produce a real worker session, artifact, report, evaluator
manifest, and passing correctness/restriction result.

## Validation

`run-1786124624556` is the proof: the worker and evaluator both passed, the
manifest is present, and all 9 cases are byte-exact on `linux/arm64`.

## Revert condition

Any missing worker session or non-ELF staged binary falsifies the change; revert
the path update and move staging into a run-scoped directory.

## Next-cycle disposition

The binary handoff is validated; retain reduced intensity for any optional
handbook replay.
