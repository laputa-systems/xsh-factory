# CTO productivity report

## Result

fail — delivery-target-missed

## Engineer-commit gate

One fresh engineer row completed and produced a reviewable product commit,
`4862f39d` on `factory/task-histogram-005/1786212466873`, but zero engineer
commits were delivered to XSH because linked replay validation failed. This is
a throughput failure under the hard delivery gate.

## Comparison with prior cycle

Cycle 26 admitted 2 tickets, dispatched 1 fresh engineer and 1 retained row,
and delivered 0 commits. It spent `$0.123247` across 177 assistant turns; the
prior cycle spent `$0.146694` across 167 turns and also delivered 0. Cost fell,
but genuine product throughput stagnated at zero. The engineer, independent
`task-bigfiles` eval, and both replay managers produced structured pass
reports; the fresh replay was blocked by a stale restriction checker and the
retained replay consumed the initial manager ceiling plus its bounded retry.

## Efficiency judgment

Throughput stagnated: the product branch contains a real additive
`Str.parse_uint()` implementation, but evaluator-only evidence is not a
delivery. This cycle improved diagnosis and reduced cost versus cycle 25, not
delivered output.

## Assembly-line bottleneck

The constrained stage was replay/merge. The fresh worker exercised
`parse_uint()` and correctness was 9/9, but
`evals/task-histogram/evaluator.xsh` classified the required typed parser as a
restriction failure because it only recognized `parse_int`. The retained
manager also reached the retry path after its 600-second closeout bound.
The next target is one delivered fresh commit, with fresh replay still hard
and retained replay best-effort under its shorter bound.

## Evidence

Evidence: `report.json` records `fresh_engineer_rows=1`,
`delivered_tickets=0`, `reeval_dispatched=2`, and `reeval_passed=0`;
`phases/01-ticket` records the engineer pass and retained commit;
`phases/02-reeval-task-histogram-005` records correctness pass/restriction
failure; `phases/03-eval` passed; and cycle 25 is
`runs/run-1786209582303/report.json`.

## Corrective action

The concrete repair is in `evals/task-histogram/evaluator.xsh`: accept either
typed `parse_int` or typed `parse_uint`, covered by a native evaluator-contract
test. Retained replay managers now receive an explicit 300-second ceiling via
`factory/control.xsh`, `factory/controllers/organization.xsh`, and
`factory/controllers/eval.xsh`; native tests cover the policy wiring. The next
cycle must show `delivered_tickets >= 1` and a fresh delivery event before any
retained failure is considered acceptable.

## Next-cycle target

Cycle 27 target: at least one fresh engineer commit delivered, fresh replay
`required=true`, and the fresh `86-ticket-*-delivered` event preceding any
retained delivery event. Retained replay may fail, but its manager path must
close within the 300-second policy bound.
