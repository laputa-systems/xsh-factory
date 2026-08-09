# CTO productivity report

## Result

Eligible delivery succeeded, but the organization run failed its independent
supply-manager output gate. `task-envcfg-009` produced one engineer commit,
passed its linked replay, and merged. The run therefore starts a one-cycle
eligible-delivery streak, not a healthy maintained ticket buffer.

## Engineer-commit gate

One newly dispatched engineer produced provenance-amended commit
`04fb98f8c63b63cccffce7ef2c3cabde81bb05ba` for `task-envcfg-009` in 34 turns
at $0.041923. The ticket phase passed, its linked `task-envcfg` evaluator
passed all ten configuration cases plus the exact `xsht api api:error.fail`
gate, and the recovery manager recorded `Candidate acceptance: pass.` The
organization controller fast-forwarded `../xsh` from `7b4bee1` to `04fb98f`.

## Comparison with prior cycle

`run-1786255756177` admitted one ticket and produced one reviewable candidate
but delivered zero: replay-manager output and an out-of-scope compatibility
decision blocked merge. This run admitted one ticket, spent $0.093639 across
125 assistant turns, and delivered one ticket with one passing linked replay.
Product and evaluator outcomes are `pass`; infrastructure is `fail` only
because `03-supply-eval` lacked a complete manager report. The approved
branchless product-ticket queue was one before admission and zero afterward:
the supply worker passed but did not yield a reviewable ticket decision.

## Efficiency judgment

Delivery throughput improved from zero to one merged product change, and the
previous replay-manager alignment is validated for the candidate path: its
recovery completed in eight turns. Supply throughput regressed to no usable
decision: the `task-groupsum` worker completed a passing 45-turn, $0.019359
trial, while both manager attempts stopped after one turn with a `not-ready`
report. This is infrastructure loss, not evidence that the eval found no
signal or that a weak ticket should be created.

## Assembly-line bottleneck

The current constraint is supply replenishment after eval execution, at the
worker-evidence -> manager-decision boundary. Both failed supply manager
sessions issued all five mandatory reads in one assistant turn. The combined
handbook, rationale, eval, and phase-report responses were large enough that
neither session reached its mandatory next draft call. By contrast, the
smaller `task-envcfg` retry survived that batch and completed. Provider
telemetry has zero retries and no provider errors for all manager attempts,
so the attribution is prompt/packet behavior, not provider health.

## Evidence

- Root throughput and outcome split: `runs/run-1786257836059/report.json`.
- Delivery evidence: `phases/01-ticket/report.json`,
  `phases/02-reeval-task-envcfg-009/report.json`, and event
  `90-delivery-task-envcfg-009-merged` in `events.jsonl`.
- Candidate manager recovery:
  `phases/02-reeval-task-envcfg-009/workers/eval-manager/task-envcfg-retry-1/REPORT.md`.
- Supply failure and raw sessions:
  `phases/03-supply-eval/report.json` and the two
  `workers/eval-manager/task-groupsum*/session.jsonl.bz2` archives.
- Prior comparison and earlier repair:
  `runs/run-1786255756177/CTO-PRODUCTIVITY-REPORT.md` and
  `CTO-IMPROVEMENT.md`.

## Corrective action

`templates/EVAL-MANAGER-ASSIGNMENT.md`,
`templates/EVAL-MANAGER-RETRY.md`, and `roles/eval-manager.md` now require
the five admission reads one at a time, in order, with no batching or
parallelization. `tests/tools_test.xsh` guards the rule. This preserves the
required-read contract while keeping each response boundary small enough to
reach the report draft deterministically.

## Next-cycle target

The next supply manager must produce `required_outputs.manager_report: true`
after five separately issued admission reads and a sixth draft action. Its
decision may honestly be `no ticket`, but it must be usable evidence. The
buffer remains a target of two independently reviewed, branchless Approved
product tickets; it will be replenished only by a strong, reproducible supply
observation, never by status quota.
