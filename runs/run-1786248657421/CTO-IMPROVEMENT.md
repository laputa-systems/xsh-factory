# CTO factory improvement

## Status

pending-validation

`pending-validation` means the CTO has already implemented this change. It is
not awaiting another approval; the next cycle verifies the named metric or
applies the safe inverse.

## Change

The failed discovery preflight exposed a reusable local-toolchain defect. XSH
commit `00a5df4` adds Alpine `linux-headers` and `libunwind-dev` to
`../xsh/Dockerfile.test`; the current `aws-lc-sys` musl feature probes require
`linux/random.h` and `-lunwind`. The factory now preserves the distinct
eval-only outcome in `factory/controllers/eval.xsh::write_preflight_failure_report`,
with regression coverage in
`tests/tools_test.xsh::test_eval_controller_persists_build_preflight_failure`.

## Throughput requirement

Zero reviewable engineer implementation commits were produced. The inventory
had zero Open and zero Approved tickets, so no eligible delivery was bypassed;
the selected least-recently-tried `task-ecount` discovery phase instead failed
before worker admission. This is still a throughput failure: the eval-to-ticket
stage received no signal because local infrastructure blocked it.

## Provider-health attribution

Provider health is `unknown`: no Pi worker started, so there is no provider
telemetry, latency, retry, or cost evidence.

## Baseline metric

`report.json` and `phases/01-eval/report.json` show 0 workers, 0 assistant
turns, and $0 cost, with an XSH distribution preflight failure. The exact
missing-header and linker evidence is in `phases/01-eval/xsh-build.stderr`.

## Target metric

The next explicitly requested organization cycle reaches one discovery worker
report after the local XSH image build. Its phase report must not contain an
`xsh` preflight failure.

## Validation

Before the next paid admission, rebuild the current product image and run the
debug aarch64-musl package set. In the next run, inspect
`phases/01-eval/xsh-build.stderr`, `phases/01-eval/report.json`, and the worker
directory: the former must omit both `linux/random.h` and `-lunwind` failures,
the phase must pass preflight, and at least one worker `report.json` must exist.

## Revert condition

If a freshly rebuilt current `Dockerfile.test` still emits either missing
`linux/random.h` or `-lunwind`, this image repair is falsified. Preserve that
evidence, revert to requiring an explicitly qualified `XSH_TEST_IMAGE` for
factory admission, and replace the package list only with a target-correct
image fix that passes the same debug build.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted`
after running the named verification, and link the evidence before admitting
paid work.
