# CTO factory improvement

## Status

pending-validation

## Change

The Englishlint pass consisted of factory commits `6c5836b` and `4d41409`.
It shortened and restructured role prompts, the shared Pi briefing, and runtime
agent guidance. This cycle added the executable comparison request and updated
prompt contract tests in `cycle-efficiency-ab.md` and `tests/tools_test.xsh`.

## Baseline metric

A matched `task-envcfg` trial on the pre-Englishlint revision `6c5836b` passed
with 30 total assistant turns, 431,890 bucket tokens, 1 tool error, and
$0.015815 cost. Evidence:
`comparison-baseline/runs/run-1785861543618/report.json`.

## Target metric

The current Englishlint revision `4d41409` must preserve correctness, protocol,
restrictions, and report completeness while reducing aggregate effort or tool
errors. One trial cannot establish causality, so the comparison reports worker
and manager deltas separately.

## Validation

The matched current revision trial passed all gates with 53 turns, 1,120,155
bucket tokens, 0 tool errors, and $0.039995. The eval-worker improved from 18 to
29 turns? No: the worker increased from 18 to 29 turns, while tokens rose from
180,887 to 342,036 and cost rose from $0.005475 to $0.011660. The manager rose
from 12 to 24 turns, tokens rose from 251,003 to 778,119, and cost rose from
$0.010340 to $0.028335. Aggregate turns rose 76.7%, tokens rose 159.4%, and
cost rose 152.9%; tool errors fell from 1 to 0. Both arms passed correctness,
protocol, restrictions, and reporting. Evidence: `report.json` and
`comparison-baseline/runs/run-1785861543618/CTO-REPORT.md`.

The result is not a noticeable aggregate efficiency improvement. The zero-tool-
error result is a small positive signal, but it does not offset the higher
turns, tokens, and cost. The earlier comparison against `434080d` showed the
same mixed direction: worker effort improved while manager effort increased.

## Revert condition

Do not revert the Englishlint prompt edits based on one stochastic comparison.
Revert them if two additional matched comparisons show higher aggregate cost
and turns without a durable reduction in tool errors or a correctness benefit,
or if the shortened prompts cause a report, safety, or evaluator gate failure.
The next comparison must use the same request and inspect worker and manager
metrics separately.

## Next-cycle disposition

The A/B harness is validated: it produced complete, directly comparable
structured evidence. The Englishlint prompt change remains unproven and should
not be described as an efficiency improvement. A second matched comparison is
still required before keeping or reverting it on efficiency grounds.
