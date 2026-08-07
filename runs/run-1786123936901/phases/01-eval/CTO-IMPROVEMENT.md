# CTO factory improvement

## Status

pending-validation

## Change

The eval controller now reads the cross-build output from
`target/<target>/dist`, matching the `dist-Linux-docker` Make target. The
native fixture now exercises that path with an isolated target and removes all
of its transient outputs.

## Baseline metric

The sole trial failed with `missing session`; the image contained the stale
no-op binary left at the former `target/docker-...` path. Manager cost was
`$0.014268132` across 12 turns, with zero worker sessions.

## Target metric

The next one-trial replay must produce a worker session, report, artifact, and
evaluator `run.json` from a real staged XSH binary.

## Validation

The focused regression passes and the full native suite passes `112/112`;
fixture target, cache stamp, and staged context are absent afterward. The next
replay is the end-to-end gate.

## Revert condition

Another stale or missing staged binary on replay, or fixture residue after
tests, requires reverting this path fix and isolating staging per run.

## Next-cycle disposition

Run exactly one `task-bigfiles` trial and inspect the complete evidence packet
before any qualitative ticket decision.
