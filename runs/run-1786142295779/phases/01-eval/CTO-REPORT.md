# CTO briefing 01-eval

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
- `workers/eval-manager/task-revrank/report.json`: result `pass`; report `workers/eval-manager/task-revrank/report.json`
- `workers/eval-worker/task-revrank-1/report.json`: result `pass`; report `workers/eval-worker/task-revrank-1/report.json`


## Employee accounting

### Worker metrics

- `eval-manager/task-revrank` (`eval-manager`): result `pass`; report `workers/eval-manager/task-revrank/report.json`
  - Execution: `not recorded`; classification: `not recorded`
  - Turns: `14`; bucket tokens: `342638`; thinking blocks: `13`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=14; observed_output_tps=0`
  - Tool errors: `1`; cost: `0.010092`; budget: `0.150000`
- `eval-worker/task-revrank-1` (`eval-worker`): result `pass`; report `workers/eval-worker/task-revrank-1/report.json`
  - Execution: `fail`; classification: `evaluator_failed`
  - Turns: `61`; bucket tokens: `1450955`; thinking blocks: `50`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=61; observed_output_tps=0`
  - Tool errors: `0`; cost: `0.036817`; budget: `0.500000`


### Nonzero tool results
### Provider health and latency

Provider retry, latency, and attribution data are in worker `report.json`
`provider_telemetry` fields. Missing telemetry is `unknown`, not evidence of
normal provider health. Provider switching is out of scope and tracked in
`TODO.md`.

### Nonzero tool results

- `eval-manager/task-revrank`, turn `7`, tool `bash`: === session: mentions of Map[Int] / restriction / map.empty ===
3
26
   1 restrictions on subprocesses
   1 restrictions stated by the
=== tool error count in session ===
0


Command exited with code 1
  - Structured report: `workers/eval-manager/task-revrank/report.json`


### Cycle total

- Workers: `2`
- Assistant turns: `75`
- Bucket tokens: `1793593`
- Cost (USD): `0.046909`
- Nonzero tool results: `1`
- Budget failures or unknown costs: `0`


## Employee decisions

### eval-manager/task-revrank

- Role: `eval-manager`
- Result: `fail`
- Report: `workers/eval-manager/task-revrank/REPORT.md`

#### Efficiency and evidence

Single trial (Trial 1) against XSH commit `a248267612439dfcfa203fba583ac3e95d37f70c`.
Worker `eval-worker/task-revrank-1`:
- assistant turns: 61; user messages: 1
- tool calls: 74 (65 bash, 2 edit, 3 read, 4 write); tool results: 74
- tool errors: 0
- thinking blocks: 50
- session span: 489,703 ms (~490 s); agent wall: 492,221 ms
- stop reasons: 1 `stop`, 60 `toolUse`; wrapper state `completed`, agent_state `pass`,
  budget_state `pass`, reporting_state `pass`, evaluator_state `fail`.
- Worker `result: pass` refers to the session completing; the trial outcome is `fail`
  (run.json classification `restriction_failed`).

Efficiency judgment: no tool errors and zero provider retries, yet 61 turns / 74 tool
calls for a ~20-line task. The exploratory load is consistent with the worker
experimenting with `sort-by --desc`, a folding Map accumulator that hit an IR-encoding
blocker, and inference of `map.empty()` typing before settling on a `var` Map reassigned
inside an `each` loop. No tool-error friction. See Timing/Thinking sections.

#### Handbook or proposal decision

Unchanged. The approved snapshot was copied verbatim to
`runs/run-1786142295779/phases/01-eval/lineage/handbook-candidate.md` (identical,
confirmed by diff). No reusable lesson is justified: the failure is a harness/evaluator
restriction-detector mismatch, not a gap in XSH knowledge the handbook can teach. Adding a
rule like "always write an explicit `Map[Int]` annotation so restriction detectors pass"
would be a task-specific recipe aimed at a brittle literal check, contrary to the
north-star rejection of task-specific recipes. Replay scope: none for a handbook change
(snapshot preserved for the next trial of this eval under the same lineage).

#### Ticket or product decision

None (0). The cause is a harness/evaluator-detector mismatch, not a general XSH ergonomics
or correctness product defect, so no product ticket is opened. Per factory policy this is
reported as a factory/CTO finding (evaluator scaffold fix), not an engineer ticket and not
a factory-target ticket.

#### Next action

After the CTO corrects the package-owned `evaluator.xsh` restriction detector so it
recognizes a Map accumulation (accept `map.empty`/`Map.set`/`Map.get`, or a typed
`Map[Str,Int]` annotation) rather than the literal `Map[Int]`, replay Trial 1 of
`task-revrank` against this same handbook lineage and XSH commit
`a248267612439dfcfa203fba583ac3e95d37f70c`. The unchanged `revrank.xsh` already passes all
ten correctness cases and the protocol gate, so it should then pass `restrictions` and the
trial should flip from `fail` to `pass` — this is the falsification check for the harness
finding. Also re-examine the `sort-by --desc` / IR-blocker product claims in a focused eval
if a future cycle wants to reproduce them independently.

#### North-star impact

This run shows a correct, restrictions-compliant-per-intent XSH program (typed file read,
`parse_int` validation, keyed Map accumulation, `sort-by` ranking, no subprocess) being
marked `fail` solely by a brittle literal-substring restriction detector — a trust and
harness problem, not a product defect. Correctness of the submitted solution is intact, so
there is no evidence the agent or handbook needs a compatibility fix; the actionable
durable change is making the eval's restriction gate match its documented contract so that
valid, general XSH solutions are not rejected by an implementation artifact. Separately,
the high-turn exploration (61 turns, 50 thinking blocks) around map-type inference,
descent-rank stability, and an opaque IR-encoding error is a candidate fluency signal worth
pursuing in a dedicated, independently-verifiable eval before any handbook or product
change is trusted.



## Eval proposal review

No CTO eval review was recorded.

## Handbook lineage

Checked-in `runtime/handbook.md`: `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b`
- approved snapshot: `lineage/handbook-approved.md` sha256 `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b` — promoted by CTO ledger; matches checked-in handbook
- candidate: `lineage/handbook-candidate.md` sha256 `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b` — promoted by CTO ledger; matches checked-in handbook


## Historical handbook backlog

Historical candidates: 28; differing: 15; ledger-dispositioned: 13; unresolved: 2.
Unresolved candidates requiring one explicit CTO decision:
- `runs/run-1786142295779/phases/02-eval/lineage/handbook-candidate.md` sha256 `af2b35ff916e42a95757f43811b072d77a1e78a387dfcf80cf254d5d6d8bb8a7`
- `runs/run-1786142295779/phases/03-eval/lineage/handbook-candidate.md` sha256 `0b92e385ad13cccb41b04d798a77836ab62e0d716577de62866d25248ad04c71`


## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
