# CTO factory improvement

## Status

validated

From a clean checkout, a controller-only invocation with
`PI_COMMAND=factory-preflight-sentinel` rebuilt feature-correct `xsht`, ran all
146 native factory tests, and completed lint before stopping at the deliberately
unavailable Pi command. No controller process or new run directory was created.

## Change

`run.xsh::preflight` now requires clean factory and product checkouts, builds
`../xsh`'s local `xsht` with `--features native-tests`, runs the factory native
suite with that binary, and runs `xsht lint --fix` followed by lint. An autofix
that changes the checkout fails admission for CTO review. The same local binary
checks package evaluators, eliminating dependence on an ambient `xsht`.
`tests/factory_control_test.xsh::test_standard_cycle_rotates_ticketless_discovery`
locks this root-preflight contract.

## Throughput requirement

Zero reviewable engineer implementation commits were produced. The inventory
contained zero Open and zero Approved tickets, so no delivery was bypassed.
The selected `task-ecount` discovery phase failed before worker admission. This
remains a throughput failure because the eval-to-ticket stage produced no
signal.

## Provider-health attribution

Provider health is `unknown`: no Pi worker started, so no provider telemetry,
latency, retry, or model-cost evidence exists.

## Baseline metric

The prior run `runs/run-1786248657421/report.json` stopped on missing
`linux/random.h` and `-lunwind`. This run's build log no longer contains those
errors; it instead records the independent `xsht/native-tests` compiler error
at `crates/xsht/src/xsht/test.rs:153`.

## Target metric

The next paid request must fail before creating a run directory whenever its
local `xsht/native-tests` build, native suite, or lint gate fails. When those
gates pass, the next organization discovery must reach at least one worker
report.

## Validation

From a clean checkout, invoke `run.xsh` with a deliberately unavailable
`PI_COMMAND`. It must execute the local feature build, factory tests, and lint
gates, then stop before a controller/run directory is created. The next
explicitly requested paid cycle then verifies that its phase reaches a worker
report.

## Revert condition

If this preflight blocks a clean checkout after all three local commands pass,
or invokes an ambient rather than `target/debug/xsht` binary, it is falsified.
Remove only the faulty root gate and restore the prior clean-checkout admission
while correcting the command ownership in a new tested change.

## Next-cycle disposition

Validated. The next explicitly requested paid cycle uses this preflight before
controller admission; its first worker report remains the next throughput
threshold.
