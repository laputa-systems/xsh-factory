# CTO briefing 03-eval

This is the deterministic first-pass briefing for the CTO. The structured
`report.json` files and raw Pi sessions remain the source of truth.

## Result

pass
## Result

pass

## Outcome dimensions

- Product: `pass`
- Evaluator: `pass`
- Infrastructure: `pass`

## Operating context

- Mode: `eval`
- Request: `CYCLE-REQUEST.md`
- Structured report: `report.json`

## Phase outcomes

- `report.json`: result `pass`; report `report.json`
- `workers/eval-manager/task-histogram/report.json`: result `pass`; report `workers/eval-manager/task-histogram/report.json`
- `workers/eval-worker/task-histogram-1/report.json`: result `pass`; report `workers/eval-worker/task-histogram-1/report.json`


## Employee accounting

### Worker metrics

- `eval-manager/task-histogram` (`eval-manager`): result `pass`; report `workers/eval-manager/task-histogram/report.json`
  - Execution: `not recorded`; classification: `not recorded`
  - Turns: `16`; bucket tokens: `335349`; thinking blocks: `12`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=16; observed_output_tps=0`
  - Tool errors: `0`; cost: `0.011301`; budget: `0.150000`
- `eval-worker/task-histogram-1` (`eval-worker`): result `pass`; report `workers/eval-worker/task-histogram-1/report.json`
  - Execution: `pass`; classification: `pass`
  - Turns: `48`; bucket tokens: `1029720`; thinking blocks: `34`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=48; observed_output_tps=0`
  - Tool errors: `1`; cost: `0.024589`; budget: `0.500000`


### Nonzero tool results
### Provider health and latency

Provider retry, latency, and attribution data are in worker `report.json`
`provider_telemetry` fields. Missing telemetry is `unknown`, not evidence of
normal provider health. Provider switching is out of scope and tracked in
`TODO.md`.

### Nonzero tool results

- `eval-worker/task-histogram-1`, turn `31`, tool `bash`: === op: / ===
3
=== op: div ===
err[parse.expected-terminator]: expected statement terminator
  /tmp/op.xsh:2:14
    let x = 17 div 5
               ^^^ expected statement terminator
err[parse.expected-terminator]: expected statement terminator
  /tmp/op.xsh:2:14
    let x = 17 div 5
               ^^^ expected statement terminator


Command exited with code 2
  - Structured report: `workers/eval-worker/task-histogram-1/report.json`


### Cycle total

- Workers: `2`
- Assistant turns: `64`
- Bucket tokens: `1365069`
- Cost (USD): `0.035890`
- Nonzero tool results: `1`
- Budget failures or unknown costs: `0`


## Employee decisions

### eval-manager/task-histogram

- Role: `eval-manager`
- Result: `pass`
- Report: `workers/eval-manager/task-histogram/REPORT.md`

#### Efficiency and evidence

Single trial (`task-histogram-1`), 1 configured fresh trial; no trial 2.
Worker: 48 assistant turns (47 toolUse, 1 stop), 58 tool calls
(51 bash, 1 edit, 4 read, 2 write), 1 tool error, 1 user message. Session span
189,993 ms (~190 s); agent wall 191,661 ms. No repeated exploration beyond one
division-operator probe; recovery was immediate. Manager session: 0 tool
errors. One worker; no other workers requested.

#### Handbook or proposal decision

Unchanged. Copied `lineage/handbook-approved.md` -> `lineage/handbook-candidate.md`
byte-identical (sha256 `3b56a781...`). The only strong reusable lesson is the
missing-assertion product gap, which belongs in a ticket, not a handbook rule;
the division-operator probe was single-turn noise. No provisional candidate
is staged; any future `require` lesson becomes handbook content only after the
ticket is implemented and replayed across evals.

#### Ticket or product decision

- `/Users/josh/d/laputa-systems/xsh-factory/tickets/task-histogram-001.md`
  (Open) - first-class `require(cond, msg)` / expected-failure predicate for
  negative validation not expressible by a typed conversion. Links eval
  `task-histogram`, session `task-histogram-1`, executor `run.json`, lineage
  `handbook-approved.md`, and XSH commit `5f462670...`. For next cycle.

#### Next action

Replay `task-histogram` on the same `handbook-approved.md` lineage against a
future XSH commit after `task-histogram-001` lands, to confirm the two
validation branches can be expressed with `require(...)` while staying
byte-exact on all nine cases (including both failure controls). No falsification
replay needed for the unchanged handbook this cycle.

#### North-star impact

This eval demonstrates a composable, typed systems-glue pipeline (bin via
integer division -> keyed Map count -> sort-by -> cumulative fold) built from
the handbook stream/Result idioms with a single minor discovery misstep and
byte-exact output across width, sparsity, ties, and failure controls. It
advances learnability/ergonomics by validating that the existing handbook
idioms transfer to a real measurement-summary boundary, and it surfaces one
general ergonomics gap (explicit negative validation) opening a focused
product ticket rather than noise.



## Eval proposal review

No CTO eval review was recorded.

## Handbook lineage

Checked-in `runtime/handbook.md`: `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b`
- approved snapshot: `lineage/handbook-approved.md` sha256 `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b` — matches checked-in handbook
- candidate: `lineage/handbook-candidate.md` sha256 `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b` — matches checked-in handbook


## Historical handbook backlog

Historical candidates: 70; differing: 67; ledger-dispositioned: 67; unresolved: 0.
No unresolved candidate content is present.

## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
