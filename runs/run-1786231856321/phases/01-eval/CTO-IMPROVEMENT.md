# CTO factory improvement

## Status

pending-validation

This phase exposed the report-first instruction conflict. The shared repair is
implemented after the cycle and awaits a later explicit validation.

## Change

The eval-manager role, assignment, and bounded retry now share one ordering:
five admission reads, immediate staged-report write/edit, then evidence
refinement. Native source-contract tests cover the ordering.

## Throughput requirement

Zero engineer rows and zero deliveries were expected because the queue had no
Approved tickets. The phase failed only its manager-report infrastructure gate.

## Provider-health attribution

Manager telemetry was present; no provider error explains the incomplete
report. The initial manager idled into the watcher and the retry ended with an
error after reads.

## Baseline metric

Run 11 primary phase: `manager_report=false`; evaluator trial itself passed.

## Target metric

Next manager attempt writes a complete report immediately after the five
admission reads, with no report-incomplete retry.

## Validation

Use a later explicit organization cycle and inspect the manager session event
order plus `required_outputs.manager_report` in its phase report. Native tests
pass 144/144.

## Revert condition

Revert if the repaired prompts still permit worker/manifests reads before the
first report draft, or if report completeness regresses.

## Next-cycle disposition

Pending validation.
