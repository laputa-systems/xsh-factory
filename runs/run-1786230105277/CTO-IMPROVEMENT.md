# CTO factory improvement

## Status

pending-validation

`pending-validation` means the CTO has implemented the named deterministic
repair; the next paid request must validate it before this status changes.

## Change

The ticketless discovery batch exposed a toolchain admission defect. Even with
an explicit platform-qualified `XSH_TEST_IMAGE` present, the eval controller
rebuilt the default toolchain when the local cache stamp was stale. The build
then failed on the known missing `linux/random.h` and `-lunwind` dependencies
before any paid worker started.

The repair is implemented in `factory/control.xsh` and
`factory/controllers/eval.xsh`: an explicit, platform-matched image skips a
stale default rebuild unless `FACTORY_FORCE_XSH_TOOLCHAIN_REBUILD=true` is set.
Native coverage lives in `tests/factory_control_test.xsh` and
`tests/tools_test.xsh`.

## Throughput requirement

Zero reviewable engineer commits were produced. No product ticket was
Approved, so this was a discovery cycle rather than a fresh-eligible delivery
cycle. The cycle spent zero model dollars and failed before worker admission;
the correction is infrastructure-focused, not an engineer-throughput claim.

## Provider-health attribution

No provider telemetry was captured because both eval controllers failed during
local image build before Pi dispatch. Attribution is infrastructure/build
failure, not provider health.

## Baseline metric

The prior cycle delivered one retained commit (`run-1786229388916`) with a
qualified local image. This cycle failed in both parallel eval phases at the
toolchain build boundary; evidence is in each phase's `xsh-build.stderr` and
`report.json`.

## Target metric

With the same explicit qualified image and a stale cache stamp, the next
ticketless cycle must skip the default toolchain rebuild and reach evaluator
worker admission. The build failure count must be zero.

## Validation

Run the next organization request through `run.xsh` with
`XSH_TEST_IMAGE=xsh-test-throughput-1786225102047` and
`XSH_TEST_IMAGE_BUILD=0`. Verify `xsh-build.stderr` does not contain a
toolchain build, both phases reach `20-trial-1-started`, and native
`xsht test --jobs 1` remains green at 143 tests.

## Revert condition

If an explicit image is missing, has the wrong platform, or a forced rebuild is
requested and the controller skips it, the policy is wrong. Restore the
default rebuild path for that case while keeping the explicit-image fast path
only for a present, platform-matched image.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted`
after running the named verification, and link the evidence before admitting
paid work.
