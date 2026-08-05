# CTO factory improvement

## Status

pending-validation

`pending-validation` means the CTO has implemented this change or recorded a concrete handoff; the next cycle verifies the named metric before admitting further paid work.

## Change

The cycle tightened the approval gate by refusing to dispatch the pre-existing validation-API ticket and by recording the new grouped-key `sort-by` observation as a separate, API-surface-reviewed product ticket. It also promoted the substantive `task-svcstat` package, while preserving the failed histogram evidence rather than treating correctness without restriction compliance as a pass.

Evidence: `runs/run-1785899099112/CTO-REPORT.md`, `tickets/task-histogram-002.md`, and `evals/task-svcstat/EVAL.md`.

## Throughput requirement

Zero reviewable engineer implementation commits were produced. This is a throughput failure, but dispatch was intentionally blocked because the prior Open tickets were either a rejected/redundant API proposal, an evaluator-boundary failure, a disabled-eval observation, or newly created evidence not yet reviewed before the cycle. The corrective action is to approve `task-histogram-002` only after this review and dispatch it in the next cycle with a live linked replay.

## Provider-health attribution

Provider telemetry was present for all three workers. Retries were zero; provider errors and response timing were unknown/unpopulated. The restriction failure and the one manager tool error are therefore agent/evaluator evidence, not evidence of provider instability.

## Baseline metric

Prior completed cycle `runs/run-1785896401695/report.json`: one merged engineer commit, 253 assistant turns, and $0.318374, with a passing linked replay and independent manifest. This cycle `runs/run-1785899099112/report.json`: zero engineer commits, 93 turns, and $0.076292; the histogram artifact was byte-correct but failed the literal `sort-by` restriction, and design produced `task-svcstat`.

## Target metric

The next organization cycle must produce at least one reviewable engineer implementation commit, a passing linked replay, and a valid independent evaluator manifest. Engineer effort target is at most 70 turns and 10 tool errors; evaluator correctness and restriction compliance must both pass.

## Validation

Run `XSH_MODULE_PATH=. xsht test`, verify the approved ticket inventory contains `task-histogram-002`, and inspect the next root `report.json` for `engineer` count >= 1, a passing `02-reeval` report, and an independent `run.json` manifest. Verify no unresolved handbook candidate remains before admission.

## Revert condition

If the next cycle again produces no engineer commit despite `task-histogram-002` being Approved, classify the approval-to-delivery stage as blocked and stop further paid work until the assignment/controller boundary is repaired. If the linked replay cannot satisfy the `sort-by` restriction after the product change, reject the patch and keep the ticket Open; do not promote the provisional handbook candidate.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted` after running the named verification and link the evidence before admitting any later paid work.
