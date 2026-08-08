# CTO factory improvement

## Status

pending-validation

The report-first manager repair was implemented after this cycle exposed the
conflicting instruction path. It is not awaiting approval; a later explicit
cycle must validate the exact manager-report invariant before this handoff is
marked `validated`.

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

On the next explicit organization cycle, every manager attempt must issue its
first post-admission-dossier tool call as `write` or `edit` to the staged
report. The root report must show every phase's `required_outputs.manager_report`
as `true`, with no manager retry caused solely by an incomplete first draft.

## Validation

Run `xsht test --jobs 1` after the repair and then use a later explicit
organization request with the qualified image. Inspect the phase reports and
manager raw sessions for the ordering: five admission reads, immediate report
write/edit, then evidence refinement. The native suite currently passes
144/144, but paid validation is intentionally pending because the failed run
must not be relaunched under the same request.

## Revert condition

If a later manager still reads a worker report or evaluator manifest before its
first staged-report write, or if the new wording causes a manager to omit a
required evidence field after refinement, revert the prompt changes and move
the report-first enforcement into a controller-owned deterministic fallback.

## Next-cycle disposition

Pending validation. The failed run remains preserved as the falsifying baseline;
the next explicit cycle must validate the manager-report invariant before this
handoff is closed.
