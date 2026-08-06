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
  - Turns: `16`; bucket tokens: `834492`; thinking blocks: `14`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=16; observed_output_tps=0`
  - Tool errors: `0`; cost: `0.025864`; budget: `0.150000`
- `eval-worker/task-histogram-1` (`eval-worker`): result `pass`; report `workers/eval-worker/task-histogram-1/report.json`
  - Execution: `fail`; classification: `evaluator_failed`
  - Turns: `46`; bucket tokens: `929961`; thinking blocks: `32`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=46; observed_output_tps=0`
  - Tool errors: `2`; cost: `0.023728`; budget: `0.500000`


### Nonzero tool results
### Provider health and latency

Provider retry, latency, and attribution data are in worker `report.json`
`provider_telemetry` fields. Missing telemetry is `unknown`, not evidence of
normal provider health. Provider switching is out of scope and tracked in
`TODO.md`.

### Nonzero tool results

- `eval-worker/task-histogram-1`, turn `9`, tool `bash`: arg=[12] -> err[check.pattern-constructor]: unknown constructor pattern
  /tmp/t.xsh:5:5
      ok(v) => v
      ^^^^^ unknown constructor pattern

err[check.pattern-constructor]: unknown constructor pattern
  /tmp/t.xsh:6:5
      err(e) => -999
      ^^^^^^ unknown constructor pattern
arg=[-3] -> err[check.pattern-constructor]: unknown constructor pattern
  /tmp/t.xsh:5:5
      ok(v) => v
      ^^^^^ unknown constructor pattern

err[check.pattern-constructor]: unknown constructor pattern
  /tmp/t.xsh:6:5
      err(e) => -999
      ^^^^^^ unknown constructor pattern
arg=[ 5 ] -> err[check.pattern-constructor]: unknown constructor pattern
  /tmp/t.xsh:5:5
      ok(v) => v
      ^^^^^ unknown constructor pattern

err[check.pattern-constructor]: unknown constructor pattern
  /tmp/t.xsh:6:5
      err(e) => -999
      ^^^^^^ unknown constructor pattern
arg=[0] -> err[check.pattern-constructor]: unknown constructor pattern
  /tmp/t.xsh:5:5
      ok(v) => v
      ^^^^^ unknown constructor pattern

err[check.pattern-constructor]: unknown constructor pattern
  /tmp/t.xsh:6:5
      err(e) => -999
      ^^^^^^ unknown constructor pattern
arg=[12a] -> err[check.pattern-constructor]: unknown constructor pattern
  /tmp/t.xsh:5:5
      ok(v) => v
      ^^^^^ unknown constructor pattern

err[check.pattern-constructor]: unknown constructor pattern
  /tmp/t.xsh:6:5
      err(e) => -999
      ^^^^^^ unknown constructor pattern
arg=[+7] -> err[check.pattern-constructor]: unknown constructor pattern
  /tmp/t.xsh:5:5
      ok(v) => v
      ^^^^^ unknown constructor pattern

err[check.pattern-constructor]: unknown constructor pattern
  /tmp/t.xsh:6:5
      err(e) => -999
      ^^^^^^ unknown constructor pattern
arg=[4.2] -> err[check.pattern-constructor]: unknown constructor pattern
  /tmp/t.xsh:5:5
      ok(v) => v
      ^^^^^ unknown constructor pattern

err[check.pattern-constructor]: unknown constructor pattern
  /tmp/t.xsh:6:5
      err(e) => -999
      ^^^^^^ unknown constructor pattern
arg=[] -> err[check.pattern-constructor]: unknown constructor pattern
  /tmp/t.xsh:5:5
      ok(v) => v
      ^^^^^ unknown constructor pattern

err[check.pattern-constructor]: unknown constructor pattern
  /tmp/t.xsh:6:5
      err(e) => -999
      ^^^^^^ unknown constructor pattern


Command exited with code 2
  - Structured report: `workers/eval-worker/task-histogram-1/report.json`
- `eval-worker/task-histogram-1`, turn `38`, tool `bash`: check OK


Command exited with code 1
  - Structured report: `workers/eval-worker/task-histogram-1/report.json`


### Cycle total

- Workers: `2`
- Assistant turns: `62`
- Bucket tokens: `1764453`
- Cost (USD): `0.049591`
- Nonzero tool results: `2`
- Budget failures or unknown costs: `0`


## Employee decisions

### eval-manager/task-histogram

- Role: `eval-manager`
- Result: `fail`
- Report: `workers/eval-manager/task-histogram/REPORT.md`

#### Efficiency and evidence

Trial 1 (`task-histogram-1`): 46 assistant turns, 53 tool calls (47 bash,
3 edit, 2 read, 1 write), 53 tool results, 2 tool errors, 32 thinking blocks,
session span 367,296 ms (~6.1 min; agent_wall_ms 368,590). One worker.

Worker friction in this trial was low and concentrated in two places: (1) a
pattern-matching probe used lowercase `ok(v)`/`err(e)` as constructors, which
are `Ok`/`Err` and correctly rejected; the worker pivoted to postfix `?`
propagation for validation; (2) an invalid `xsht api` discovery query
(`language.core.results` -> `expected KIND:VALUE`) that was immediately
corrected to `language:core.results`. Neither was a product or harness defect.
The decisive friction was a task-wording/literal-gate mismatch: the task told
the worker to "read the file through typed filesystem/text values," so the
worker reasonably chose `Path.lines()` (a typed streaming read) instead of the
literal `.read_text()`, which the evaluator's source-token restriction gate
requires. Correctness was unaffected (9/9 byte-exact); only the restriction
gate failed.

#### Handbook or proposal decision

Provisional candidate staged at
`runs/run-1785968539139/phases/03-eval/lineage/handbook-candidate.md`. The
approved snapshot was used as the base and one general lesson was added:
when a task names a specific typed read API (e.g. `fs.read_text` /
`Path.read_text()`), call that exact method in the source, because an
evaluator's source-level restriction check may match literal API tokens and
reject a semantically equivalent typed read such as `Path.lines()`. This is a
concise, general rule that removes repeated agent friction: it applies to any
eval whose task wording describes a typed read loosely while its restriction
gate is literal. It is global (all evals share the one handbook) and must be
replayed before promotion.

#### Ticket or product decision

zero. No product/tooling defect was observed (XSH behaved correctly; the
failure was agent literal-token compliance against a documented gate). No
factory-target ticket (the gate is eval-owned, not factory infrastructure).

#### Next action

`task-histogram` at the current lineage (approved snapshot plus the staged
candidate) on the next cycle, requiring the replays to (a) read the file via
`fs.read_text`/`Path.read_text()` so the restriction gate passes, and (b)
remain byte-exact on all nine cases with both failure controls exiting
nonzero. This replay falsifies or confirms the literal-gate handbook lesson
and is the promotion gate for the candidate. Because the lesson is general,
one additional typed-file-read eval should also rerun before the candidate is
promoted to `runtime/handbook.md`.

#### North-star impact

The run demonstrates that XSH expresses a canonical measurement-summary
composition (binned cumulative distribution) correctly and learnably: the
agent discovered typed parse, Int division, group-by, sort-by, and a
cumulative fold with the handbook and `xsht api`, and produced byte-exact
output on all nine cases including both failure controls. The remaining gap is
not language capability but agent compliance with a specific typed-read API
under a literal gate. The staged handbook lesson ("call the named read API
exactly; a literal source gate may reject an equivalent typed read") is a
small, durable ergonomics improvement that reduces repeated friction for every
future eval that couples a typed file read with a source-level restriction
check, keeping the factory's focus on learnable, explicit-boundary XSH rather
than task-specific workarounds.



## Eval proposal review

No CTO eval review was recorded.

## Handbook lineage

Checked-in `runtime/handbook.md`: `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b`
- approved snapshot: `lineage/handbook-approved.md` sha256 `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b` — promoted by CTO ledger; matches checked-in handbook
- candidate: `lineage/handbook-candidate.md` sha256 `9d08733bc2c243823f0256c5955e6738726d5b73d10e194e12cf908365df27dd` — DIFFERS; CTO promotion or rejection decision required


## Historical handbook backlog

Historical candidates: 85; differing: 79; ledger-dispositioned: 78; unresolved: 1.
Unresolved candidates requiring one explicit CTO decision:
- `runs/run-1785968539139/phases/03-eval/lineage/handbook-candidate.md` sha256 `9d08733bc2c243823f0256c5955e6738726d5b73d10e194e12cf908365df27dd`


## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
