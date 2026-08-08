# CTO productivity report

## Result

fail: the cycle produced one retained product delivery, but zero fresh
engineer implementation commits were delivered. The independent evaluator
passed; the organization failed on replay infrastructure evidence.

## Engineer-commit gate

One reviewable engineer commit was produced: amended provenance commit
`b9cc3ffc6425b365a172c5a897ed9684db235487` for `task-dupcheck-002`, on branch
`factory/task-dupcheck-002/1786201139234`. Delivered fresh engineer commits:
zero. The retained `task-bigfiles-004` delivery (`608ab11…`) is product
throughput but is not counted as a fresh engineer commit for this gate.

## Comparison with prior cycle

Cycle 22 admitted two tickets, dispatched one fresh engineer row, completed one
fresh primary phase and one retained fast path, and delivered one retained
product ticket. It used 8 workers, 162 assistant turns, $0.120481, and about
19 minutes wall time. The previous paid cycle was the cycle-17 linked-replay
failure with zero delivered tickets and $0.0466286 across 54 turns; product
delivery improved, but the fresh-engineer delivery target was missed.

## Efficiency judgment

Throughput improved in product commits (one retained delivery versus zero),
but stagnated against the hard fresh-engineer target. The evaluator signal was
productive: the histogram trial passed and both replay workers passed. The
bottleneck was not model correctness; it was the candidate-linked manager
acceptance wording gate, which rejected a report that said “candidate
acceptance surface exercised.”

## Assembly-line bottleneck

The constrained stage was commit -> passing replay and merge. Evidence:
`phases/02-reeval-task-dupcheck-002/report.json` records worker and manager
results as pass but `required_outputs.manager_report` and
`required_outputs.candidate_acceptance` as false. The linked phase therefore
failed closed and retained the engineer branch. I repaired
`factory/control.xsh` to accept the manager’s evidence wording and added a
regression test; I also repaired `factory/tools/run-status.xsh` to exclude
zombie PIDs and show status, age, and command.

## Evidence

- [run report](report.json)
- [CTO briefing](CTO-REPORT.md)
- [primary phase](phases/01-ticket/report.json)
- [engineer report](phases/01-ticket/workers/engineer/task-dupcheck-002/report.json)
- [linked replay report](phases/02-reeval-task-dupcheck-002/report.json)
- [retained replay report](phases/02-reeval-task-bigfiles-004/report.json)
- [independent eval report](phases/03-eval/report.json)
- [cycle improvement](CTO-IMPROVEMENT.md)

## Corrective action

The acceptance gate now recognizes “candidate acceptance surface exercised,”
covered by `tests/factory_control_test.xsh`. Live introspection now reports
non-zombie process state and elapsed age, covered by
`tests/tools_test.xsh::test_run_status_inspects_live_and_completed_evidence`.
The deferred positional-only handbook candidate is recorded in
`runtime/handbook-ledger.md` rather than silently promoted.

## Next-cycle target

Deliver at least one engineer implementation commit, with
`data.throughput.delivered_tickets >= 1` and a linked replay whose
`required_outputs.required == true`. Cycle 23 will reuse the preserved
`task-dupcheck-002` engineer branch and must prove delivery of `b9cc3ff…`.
