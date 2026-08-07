# CTO factory improvement

## Status

validated

## Change

The fake eval-controller fixture in
`tests/tools_test.xsh::test_eval_controller_completes_with_fake_build_docker_and_pi`
now removes its shared `runs/.cache/xsh-test-aarch64-unknown-linux-musl.stamp`
and `evals/.dist` staging context on exit. The test no longer leaves no-op XSH
binaries for the next paid eval to accept through the cache.

## Throughput requirement

Zero engineer commits and zero eval-worker sessions; this was a throughput
failure caused by test-state contamination, not by skipping an eligible ticket.
All five Open histogram tickets remained explicitly deferred.

## Provider-health attribution

The eval-manager recorded provider telemetry with zero retries; worker provider
health is unknown because the worker image contained a no-op test binary and
never emitted a session. This is local fixture contamination, not provider
health.

## Baseline metric

Run `run-1786123087467` spent `$0.0104202` on 14 manager turns and failed with
zero worker trials. Its `xsh-build.state` reported a cache hit while the staged
XSH binary was the 1,041-byte fake shell fixture; trial output records the
missing session and `xsh-factory-base:latest` lookup.

## Target metric

After any native suite, no fixture cache stamp or `evals/.dist` context remains;
the next paid eval must rebuild a real XSH distribution and persist one worker
session, worker report, and evaluator manifest.

## Validation

`xsht test tests/tools_test.xsh` passes 52/52 and the full `xsht test` passes
112/112, with both transient paths absent afterward. The next replay must show a
non-stub worker image with `workers/eval-worker/task-bigfiles-1/session.jsonl`
before compression.

## Revert condition

If a native test leaves either shared fixture path, or a replay still reports a
cache hit with a no-op XSH binary, revert the fixture cleanup and move the eval
build context to a run-scoped directory before another paid cycle.

## Next-cycle disposition

The next CTO must validate the cleanup invariant before paid admission.
