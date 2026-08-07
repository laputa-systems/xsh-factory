# CTO factory improvement

## Status

pending-validation

## Change

The eval controller now stages binaries from the path produced by the
`dist-Linux-docker` Make target, `target/<target>/dist`. The fake native
controller fixture uses an isolated target with that same output contract and
cleans its cache stamp, staged context, and fake product target afterward.

## Throughput requirement

Zero engineer commits and zero eval-worker sessions. The cycle was eval-only
because all five Open histogram tickets remained explicitly deferred; the
failure was infrastructure before product signal.

## Provider-health attribution

The eval-manager recorded zero provider retries and completed normally. Worker
provider health is unknown because the stale-image executor path emitted no
worker session.

## Baseline metric

Run `run-1786123936901` spent `$0.014268132` on 12 manager turns and failed its
only trial with `missing session`. The build compiled a real XSH distribution
but staged the stale 1,041-byte fixture binary from the wrong target path.

## Target metric

The native suite must remain green with no fixture target or shared staged
context left behind, and the next paid replay must persist one real worker
session, worker report, and evaluator manifest.

## Validation

The isolated regression first failed on the old path and passes after the
controller fix. Focused and full native validation pass (`1/1` and `112/112`);
the next replay is the end-to-end gate.

## Revert condition

If a replay still stages a binary different from the current
`target/<target>/dist` output, or native tests leave fixture paths behind,
revert this change and move build staging into a run-scoped context.

## Next-cycle disposition

Replay `task-bigfiles` once with one trial. Do not admit an engineer or design
phase until a real worker evidence packet exists.
