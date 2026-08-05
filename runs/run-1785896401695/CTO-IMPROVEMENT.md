# CTO factory improvement

## Status

validated

## Change

The cycle preserved the engineer-throughput path while explicitly allowing measured reuse of `task-histogram` after the next-untried candidate set exposed invalid packages (`task-dupcheck` harness failure and `task-findexec` legacy dispatcher). The selected `task-histogram` trial passed, and the controller dispatched a second evidence-backed engineer ticket, `task-colsum-002`, concurrently with its linked replay.

## Throughput requirement

One reviewable engineer implementation commit was produced and merged: `a1cbb632d1ab8673176f6ef9f9d9cf04a7ad5e02` on `factory/task-colsum-002/1785896402449`. Its linked `task-colsum` replay passed all nine cases and directly exercised the previously failing pipeline shapes. The independent `task-histogram` eval also passed.

## Provider-health attribution

Provider telemetry was present for all seven workers. Retries were zero; provider errors were unknown and response timing was unpopulated. The 18 structured tool errors were agent-side discovery or editing failures, not provider retry evidence.

## Baseline metric

Prior run `runs/run-1785894766939/report.json`: one merged engineer commit, 225 turns, and $0.233828; linked replay passed but independent `task-dupcheck` failed before a manifest. This run `runs/run-1785896401695/report.json`: one merged engineer commit, 253 turns, and $0.318374; linked replay, independent eval, and controller infrastructure all passed.

## Target metric

The next organization cycle must preserve at least one merged engineer commit and run a valid independent approved eval with a manifest. Target cost is at or below $0.318374 unless a second product result is delivered. Prefer a fresh approved eval with a package-owned evaluator; measured reuse is allowed only when the next-untried candidate is invalid or the request records the rationale.

## Validation

Run `XSH_MODULE_PATH=. xsht test`, verify XSH `HEAD` is `a1cbb632d1ab8673176f6ef9f9d9cf04a7ad5e02`, run `XSH_MODULE_PATH=. xsh run-cto.xsh`, and inspect the next root report for at least one engineer commit, a valid independent `run.json`, and no unresolved handbook candidates. Reconcile `task-colsum-002` to `Merged.` only after the merged-head replay is proven.

## Revert condition

If the next cycle lacks a valid independent manifest, repair or rotate the evaluator before further paid work. If the merged `task-colsum-002` replay fails on the previously fixed pipeline forms, investigate and safely revert only the pipeline change; do not revert the prior validated `task-colsum-001` product change without evidence against it.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted` after running the named verification and link the evidence before admitting paid work.
