# CTO factory improvement

## Status

pending-validation

## Change

The fake eval-controller fixture now removes its shared toolchain cache stamp
and `evals/.dist` staging context on exit, preventing no-op test binaries from
reaching a later eval image.

## Throughput requirement

Zero engineer commits and zero eval-worker sessions; the failure was fixture
contamination. No eligible product ticket was skipped.

## Provider-health attribution

Manager telemetry recorded zero retries; worker provider health is unknown
because the no-op image emitted no worker session.

## Baseline metric

The phase failed after a cache-hit build staged a 1,041-byte fake XSH shell and
the worker emitted no session; see `xsh-build.state` and `trial-1.stdout`.

## Target metric

Native tests leave no shared fake cache/staging output, and the next replay
persists worker session, report, and evaluator manifest.

## Validation

Run `xsht test tests/tools_test.xsh`; verify the two transient paths are absent,
then inspect the next phase report for a real worker session and `run.json`.

## Revert condition

Any leftover fixture path or another no-op image cache hit falsifies the repair;
move staging to a run-scoped context before paying again.

## Next-cycle disposition

The next CTO must validate the cleanup invariant before paid admission.
