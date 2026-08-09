# CTO factory improvement

## Status

validated

The focused native regression and the re-audited completed run both validate
this change. No paid work was relaunched.

## Change

`factory/tools/audit.xsh` now includes preserved manager recovery reports named
`report.attempt-N.json`, while deduplicating the canonical recovery copy by the
worker identity inside its report. This counts each paid manager attempt once:
the initial failed attempt remains in cost/turn accounting, and the copied
retry report cannot be counted twice. The regression is
`tests/tools_test.xsh::test_audit_counts_manager_recovery_attempts_once`.

## Throughput requirement

Zero reviewable engineer implementation commits were produced. This is a
throughput failure, although no eligible delivery was skipped: the immutable
inventory records zero Open and zero Approved product tickets. The sole
factory-targeted historical ticket is closed and cannot be dispatched. The
ticketless controller therefore correctly selected one least-recently-tried
approved eval. That rotation protects against repeated sampling; it cannot
manufacture product supply. The next corrective delivery action is to restore
one evidence-backed, branchless Approved product ticket before expecting an
engineer row, rather than opening a weak ticket to satisfy a quota.

## Provider-health attribution

Provider telemetry was captured. The eval worker had no provider retries or
provider errors. The preserved initial manager attempt records one
`Stream ended without finish_reason` provider error and a two-second automatic
retry before the session-limit watcher stopped it; the controller-owned manager
recovery then completed in three turns with no provider error. That manager
stall is provider/harness closeout evidence, not an agent or product
regression.

## Baseline metric

Before the repair, this run's controller-written audit projected 61 assistant
turns, 1,537,507 bucket tokens, and `$0.037204056`: it counted the recovered
manager report at both canonical and retry paths, while omitting the preserved
four-turn, `$0.003425220` initial attempt. The preserved source is
`phases/01-eval/workers/eval-manager/task-ecount/report.attempt-1.json`.

## Target metric

For any recovery, report exactly one row per unique report identity and include
each preserved `report.attempt-N.json`. In this completed run, the corrected
phase and root reports both show three workers, 62 turns, 1,534,777 bucket
tokens, and `$0.038061792`.

## Validation

`../xsh/target/debug/xsht test --exact
tests/tools_test.xsh::test_audit_counts_manager_recovery_attempts_once` passes.
The deterministic re-audit of
`runs/run-1786251384949/phases/01-eval` and its organization root verifies
`data.cost` against the preserved initial manager report and the retry report.

## Revert condition

If two distinct paid attempts legitimately share the same in-report
role/worker identity and the auditor drops one, this key is insufficient.
Revert only the identity de-duplication and replace it with an explicit
controller-written attempt identity, while retaining inclusion of preserved
attempt reports.

## Next-cycle disposition

Validated by this run's preserved recovery evidence and the focused native
test. Before another paid organization cycle, require one evidence-backed,
branchless Approved product ticket to make an engineer-delivery result
possible; three arbitrary ticketless cycles cannot establish the
`THROUGHPUT.md` operating target.
