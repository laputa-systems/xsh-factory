# CTO factory improvement

## Status

reverted

## Change

The factory now has a repeatable comparison request at
`cycle-efficiency-ab-2.md`. The prior candidate handbook lesson was explicitly
dispositioned as deferred in `runtime/handbook-ledger.md`, so both arms used the
same approved handbook. The comparison preserves raw sessions and structured
reports for both matched arms.

## Baseline metric

The first comparison showed one mixed pair: pre-Englishlint `6c5836b` used 30
turns, 431,890 tokens, 1 tool error, and $0.015815; current `4d41409` used 53
turns, 1,120,155 tokens, 0 errors, and $0.039995. Evidence:
`runs/run-1785859174911/comparison-baseline/` and `runs/run-1785859174911/`.

## Target metric

A second matched pair must preserve correctness, protocol, restrictions, and
report completeness while showing a repeatable reduction in aggregate effort or
errors before the prompt edits are called an efficiency improvement.

## Validation

The second clean baseline arm passed all gates. Its worker used 32 turns,
634,473 tokens, 4 tool errors, and $0.021692; the manager used 15 turns,
357,711 tokens, and $0.011337. Evidence: `comparison-baseline/report.json`.

The second current arm passed all gates. Its worker used 52 turns, 925,802
tokens, 5 tool errors, and $0.025482; the manager used 13 turns, 425,579
tokens, 1 tool error, and $0.016083. Aggregate current versus baseline was 65
versus 47 turns (+38.3%), 1,351,381 versus 992,184 tokens (+36.2%), 6 versus 4
tool errors (+50%), and $0.041564 versus $0.033029 (+25.8%).

Across both pairs, the current revision has not shown a noticeable aggregate
efficiency improvement. It has lower manager effort in the second pair, but
higher worker effort, higher aggregate cost, and no durable tool-error win.

## Revert condition

Revert the Englishlint prompt edits now. Two clean matched comparisons show
higher aggregate effort and cost, with no consistent tool-error or correctness
benefit. Preserve the comparison harness and its tests. Restore the role,
briefing, runtime-agent, and assignment wording from `6c5836b`, while retaining
independently useful test or controller fixes.

## Next-cycle disposition

The Englishlint prompt change is rejected as an efficiency improvement and has
been reverted in commit `6a6ea9e` before the next paid cycle. The staged handbook
candidate remains deferred; do not promote it without an independent replay.
The second matched pair was clean and complete, so no further A/B spend is
required.
