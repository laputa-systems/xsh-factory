# CTO factory improvement

## Status

pending-validation

The validation cycle exposed a second infrastructure boundary after the prior
evaluator-copy repair: the product distribution build staged 17-byte shell
placeholders as `xsh` and `xsht`. The controller admitted the image because
copying succeeded, then the worker exited without creating its session.

## Change

`factory/control.xsh` now defines `eval_binary_size_ok`, and
`factory/controllers/eval.xsh` rejects staged XSH binaries smaller than 1024
bytes before building or dispatching an eval image. The focused regression is
`tests/factory_control_test.xsh::test_eval_image_inputs_are_local`.

## Throughput requirement

This cycle produced zero engineer commits and admitted zero tickets, as
intended. It produced no worker session, candidate, evaluator manifest, or
product signal because the invalid runtime image was detected only after the
pre-existing controller path had already admitted it.

## Provider-health attribution

Only the eval-manager ran. Its provider telemetry was present with zero
retries; four retained tool errors were caused by the absent executor evidence
files. No provider issue explains the cycle failure.

## Baseline metric

The prior validation attempt `runs/run-1786052381421/report.json` reached a
correct task-grep candidate but failed in evaluator artifact copying. This
attempt spent `$0.011913858` across `20` manager turns and failed before any
worker session was produced.

## Target metric

The next validation must fail before paid worker admission when the staged
runtime is invalid, with a structured preflight report naming the staging
failure. Once valid binaries are present, the same request must produce a
worker session, evaluator manifest, and exported artifacts.

## Validation

Run `xsht test`, then run the task-grep validation request. Require either a
structured staging preflight failure for binaries below the threshold or, for a
valid build, a complete worker session, `run.json` with `result: "pass"`, and
exported `grep.xsh` and `review.md`.

## Revert condition

Revert only if a valid product distribution is rejected despite both staged
binaries being real executable artifacts, or if the size gate permits a
nonfunctional placeholder. Replace the threshold-only check with a stronger
format/target-aware validation in that case.

## Next-cycle disposition

The next CTO must validate the new staging gate and the distribution build
before approving any histogram ticket or starting another engineer cycle.
