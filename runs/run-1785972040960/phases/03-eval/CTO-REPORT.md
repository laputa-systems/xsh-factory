# CTO briefing 03-eval

This is the deterministic first-pass briefing for the CTO. The structured
`report.json` files and raw Pi sessions remain the source of truth.

## Result

fail
## Result

fail

## Outcome dimensions

- Product: `fail`
- Evaluator: `fail`
- Infrastructure: `fail`

## Operating context

- Mode: `eval`
- Request: `CYCLE-REQUEST.md`
- Structured report: `report.json`

## Phase outcomes

- `report.json`: result `fail`; report `report.json`
- `workers/eval-manager/task-histogram/report.json`: result `pass`; report `workers/eval-manager/task-histogram/report.json`
- `workers/eval-worker/task-histogram-1/report.json`: result `pass`; report `workers/eval-worker/task-histogram-1/report.json`


## Employee accounting

### Worker metrics

- `eval-manager/task-histogram` (`eval-manager`): result `pass`; report `workers/eval-manager/task-histogram/report.json`
  - Execution: `not recorded`; classification: `not recorded`
  - Turns: `13`; bucket tokens: `298280`; thinking blocks: `10`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=13; observed_output_tps=0`
  - Tool errors: `0`; cost: `0.011042`; budget: `0.150000`
- `eval-worker/task-histogram-1` (`eval-worker`): result `pass`; report `workers/eval-worker/task-histogram-1/report.json`
  - Execution: `fail`; classification: `evaluator_failed`
  - Turns: `47`; bucket tokens: `834808`; thinking blocks: `37`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=47; observed_output_tps=0`
  - Tool errors: `1`; cost: `0.019820`; budget: `0.500000`


### Nonzero tool results
### Provider health and latency

Provider retry, latency, and attribution data are in worker `report.json`
`provider_telemetry` fields. Missing telemetry is `unknown`, not evidence of
normal provider health. Provider switching is out of scope and tracked in
`TODO.md`.

### Nonzero tool results

- `eval-worker/task-histogram-1`, turn `38`, tool `bash`: === width -5 ===
runtime traceback
executable: /usr/local/bin/xsh
operation: result.propagate
sh: syntax error: bad substitution


Command exited with code 2
  - Structured report: `workers/eval-worker/task-histogram-1/report.json`


### Cycle total

- Workers: `2`
- Assistant turns: `60`
- Bucket tokens: `1133088`
- Cost (USD): `0.030862`
- Nonzero tool results: `1`
- Budget failures or unknown costs: `0`


## Employee decisions

### eval-manager/task-histogram

- Role: `eval-manager`
- Result: `fail`
- Report: `workers/eval-manager/task-histogram/REPORT.md`

#### Efficiency and evidence

Trial 1 (worker `task-histogram-1`): agent_state pass, evaluator_state fail.
47 assistant turns, 48 tool calls / 48 tool results, 1 tool error. Session span
144,867 ms (~2.4 min); agent_wall 146,196 ms. Tool mix: bash 42, read 4, write
1, edit 1. Provider telemetry present: 0 retries, 0 provider errors, 0 retry
delays, 0 output_tokens_per_second (external-health signal clean). Worker
friction per trial: low — a single exploratory bash probe error (turn 38), no
repeated exploration, no retry/latency signal.

#### Handbook or proposal decision

Provisional candidate staged at
`runs/run-1785972040960/phases/03-eval/lineage/handbook-candidate.md`
(approved snapshot copied plus the new section). Lesson 1 (general, this run's
failure): `print` always terminates with a newline, so `print x.join("\n")`
emits a blank line for empty `x`; guard with an emptiness check for
"print nothing on empty input" exact-output contracts. Lesson 2 (learnability):
avoid binding names that shadow standard modules (`let path = ...`). Both are
short, general rules. Replay scope: `task-histogram` and other exact-output
evals (`task-bigfiles`, `task-colsum`, `task-total`, `task-groupsum`) before
promotion to `runtime/handbook.md`. Not promoted this cycle.

#### Ticket or product decision

None. The single correctness miss is a verification gap on one designed case,
not a reproducible general product defect; the review.md ergonomics notes need
replay evidence before becoming a ticket.

#### Next action

Re-run `task-histogram` against this run's lineage with the staged handbook
candidate, confirming that (a) `hidden_empty` now prints nothing and all nine
cases pass, and (b) the candidate's two general rules cause no regression on a
second exact-output eval (`task-colsum`). That replay must also gate the empty
input byte-for-byte against the oracle, which the worker did not do this cycle.

#### North-star impact

The run isolates a clean, reusable exact-output discipline (guard empty
collection prints) that removes a whole class of "almost correct" byte-mismatch
failures across measurement-summary and file-listing evals, directly serving
the learnability and ergonomics goals. It also surfaces two genuine XSH
ergonomics signals — the absence of a deliberate-error constructor and
module-name shadowing — that, once replayed with evidence, could become
product tickets. The eval's empty-input gate worked as designed, demonstrating
the correctness of the hidden-case test design rather than a defect.



## Eval proposal review

No CTO eval review was recorded.

## Handbook lineage

Checked-in `runtime/handbook.md`: `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b`
- approved snapshot: `lineage/handbook-approved.md` sha256 `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b` — promoted by CTO ledger; matches checked-in handbook
- candidate: `lineage/handbook-candidate.md` sha256 `9b0d6f75be6d6e7e5113236917274101167e06391e26fb8a6b8aac5072902cb6` — DIFFERS; CTO promotion or rejection decision required


## Historical handbook backlog

Historical candidates: 89; differing: 83; ledger-dispositioned: 82; unresolved: 1.
Unresolved candidates requiring one explicit CTO decision:
- `runs/run-1785972040960/phases/03-eval/lineage/handbook-candidate.md` sha256 `9b0d6f75be6d6e7e5113236917274101167e06391e26fb8a6b8aac5072902cb6`


## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
