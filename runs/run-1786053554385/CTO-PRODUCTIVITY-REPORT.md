# CTO productivity report

## Result

fail

## Engineer-commit gate

Engineer commits: `0`. No ticket was admitted, and no eval-worker session was
created.

## Comparison with prior cycle

The prior validation run `runs/run-1786052381421/report.json` reached a correct
candidate but failed in the task-grep evaluator's export copy. This run spent
`$0.011913858` and `20` manager turns, but stopped earlier: the worker image
contained 17-byte `/bin/sh; exit 0` placeholders in place of `xsh` and `xsht`,
so no candidate or evaluator phase could start. The product, evaluator, and
infrastructure outcomes are all failed at the cycle boundary; this is not
evidence against the XSH product.

## Efficiency judgment

Throughput remained zero because paid admission reached an invalid runtime
boundary. The manager's four ENOENT tool errors were consequences of missing
executor evidence, not agent churn or provider health. The new fail-closed gate
prevents spending another worker budget on this state.

## Assembly-line bottleneck

The bottleneck is eval runtime admission, specifically validating the local XSH
distribution before Docker image construction. The corrective action is the
`eval_binary_size_ok` gate in `factory/control.xsh` and its controller use in
`factory/controllers/eval.xsh`.

## Evidence

- Run report: `runs/run-1786053554385/report.json`
- CTO report: `runs/run-1786053554385/CTO-REPORT.md`
- Phase events: `runs/run-1786053554385/phases/01-eval/events.jsonl`
- Failure detail: `runs/run-1786053554385/phases/01-eval/trial-1.stderr`
- Product artifact observed: `../xsh/target/docker-aarch64-unknown-linux-musl-release/aarch64-unknown-linux-musl/dist/xsh-multicall`
- Prior evaluator failure: `runs/run-1786052381421/report.json`

## Corrective action

Keep the staging gate and require a clean preflight report before paid work.
Do not relaunch this failed validation attempt.

## Next-cycle target

Produce a complete task-grep validation packet: worker session, candidate,
evaluator `run.json` with `result: "pass"`, exported artifacts, and a passing
phase report. If the build remains invalid, stop before worker admission with a
clear staging failure and no paid child process.
