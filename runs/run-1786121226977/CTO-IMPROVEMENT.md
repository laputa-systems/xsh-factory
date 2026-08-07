# CTO factory improvement

## Status

pending-validation

## Change

The eval controller now validates the cached `XSH_TEST_IMAGE` platform before
accepting its cache stamp. `factory/controllers/eval.xsh` uses Docker's
`{{.Os}}/{{.Architecture}}` identity and forces the product distribution build
when it does not match `FACTORY_PLATFORM`; the pure contract lives in
`factory/control.xsh` and is covered by `tests/factory_control_test.xsh`.

## Throughput requirement

This organization cycle produced zero engineer commits and zero worker
sessions. That is a throughput failure caused by an infrastructure preflight
failure, not by an eligible ticket being skipped: all five Open tickets were
explicitly deferred pending fresh replay evidence.

## Provider-health attribution

No Pi worker started, so no provider telemetry was produced. The failure is
local Docker/toolchain infrastructure, not provider health or agent effort.

## Baseline metric

Run `run-1786121226977` reached the eval phase with 0 workers, 0 assistant
turns, and $0 cost, then failed at `phases/01-eval/xsh-build.stderr` because
the cached `xsh-test:latest` image was `linux/amd64` while the build requested
`linux/arm64` and Docker attempted an unauthorized pull.

## Target metric

On the next eval admission, a matching cached image must pass the platform
check and a mismatched image must trigger a local rebuild, with zero
`pull access denied` toolchain failures before worker dispatch.

## Validation

Run `xsht test` and inspect the next phase report and `xsh-build.stderr`.
Validation passes when the native suite is green and the next eval phase is
not rejected at stage `xsh` for a cached-image platform mismatch.

## Revert condition

If a matching-platform image is rejected or the next run still reaches the
same unauthorized-pull failure despite the platform check, revert the helper
and controller change and repair the Docker image admission contract with a
new focused regression test.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted`
after running the named verification and linking the evidence.
