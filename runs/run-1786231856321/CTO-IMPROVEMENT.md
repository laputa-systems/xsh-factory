# CTO factory improvement

## Status

validated

The report-first manager repair was implemented after this cycle exposed the
conflicting instruction path. Run `run-1786233883963` validated that its
instruction order is singular: the primary manager's only assistant turn made
exactly the five required admission reads and did not inspect worker or
evaluator evidence first. The primary report still remained incomplete because
the provider did not return a second assistant turn after the completed tool
results; that separate lifecycle boundary is addressed by the successor
controller improvement in `runs/run-1786233883963/CTO-IMPROVEMENT.md`.

## Change

`roles/eval-manager.md` now defines one authoritative evidence order: read
exactly the five admission files, then immediately write the complete staged
report before any worker report, evaluator manifest, artifact, or raw session.
`templates/EVAL-MANAGER-ASSIGNMENT.md` and
`templates/EVAL-MANAGER-RETRY.md` state the same ordering without ambiguity.
`tests/tools_test.xsh` asserts the report-first contract in the role,
assignment, and retry templates. This removes the prior contradiction in which
the role prompt asked managers to read worker evidence before drafting while
the assignment asked them to write first.

## Throughput requirement

Engineer implementation commits: `0`; fresh-engineer target: `0`. Inventory
had two `Open.` tickets and zero `Approved.` rows, so no eligible product row
existed and the hard one-commit target was not applicable. This cycle was an
eval-only discovery run; its primary phase still failed infrastructure because
the manager closeout was incomplete.

## Provider-health attribution

Telemetry was captured for all five workers. Total cost was `$0.062499888`,
with 94 assistant turns, 5 workers, no budget failures, and no unknown costs.
No provider error or retry explains the primary manager failure; the initial
manager and its retry both stopped after reads without producing a contract
complete report.

## Baseline metric

Run 10 (`../run-1786230602946`) had two discovery phases pass with four
workers, 97 turns, and complete manager reports. Run 11
(`report.json`) had the same clean evaluator/build boundary, but
`01-eval/data.required_outputs.manager_report=false`; both
`task-bigfiles` manager attempts left `not-ready` placeholders.

## Target metric

Run `run-1786233883963` observed zero evidence-order violations: the primary
manager made only the five admission reads before its session stopped making
progress, and the independent manager made the same reads then immediately
wrote the staged report. The all-manager-completion portion of the former
target was not met because the session watcher terminated a pending provider
completion; it is now a controller lifecycle target, not an instruction-order
claim.

## Validation

`runs/run-1786233883963/phases/01-eval/workers/eval-manager/task-bigfiles/`
and its retry contain the ordered admission reads; the successful comparison is
`phases/02-eval/workers/eval-manager/task-colsum/session.jsonl.bz2`. The
current native suite protects the common role, assignment, and retry wording.

## Revert condition

If a later manager reads a worker report or evaluator manifest before its first
staged-report write, or if the wording causes an otherwise available manager
turn to omit a required evidence field after refinement, revert the prompt
changes and move report-first enforcement into a controller-owned deterministic
fallback.

## Next-cycle disposition

Validated for evidence order. The failed run remains the baseline for the
separate pending-provider lifecycle repair recorded by the current cycle.
