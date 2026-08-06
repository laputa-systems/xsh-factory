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
  - Turns: `14`; bucket tokens: `457729`; thinking blocks: `11`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=14; observed_output_tps=0`
  - Tool errors: `1`; cost: `0.013752`; budget: `0.150000`
- `eval-worker/task-histogram-1` (`eval-worker`): result `pass`; report `workers/eval-worker/task-histogram-1/report.json`
  - Execution: `pass`; classification: `pass`
  - Turns: `52`; bucket tokens: `963713`; thinking blocks: `42`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=52; observed_output_tps=0`
  - Tool errors: `0`; cost: `0.023162`; budget: `0.500000`


### Nonzero tool results
### Provider health and latency

Provider retry, latency, and attribution data are in worker `report.json`
`provider_telemetry` fields. Missing telemetry is `unknown`, not evidence of
normal provider health. Provider switching is out of scope and tracked in
`TODO.md`.

### Nonzero tool results

- `eval-manager/task-histogram`, turn `3`, tool `ls`: Path not found: /Users/josh/d/laputa-systems/xsh-factory/runs/run-1785967719321/phases/03-eval/workers/eval-worker/task-histogram-1/session.jsonl.bz2.bz2.events.jsonl
  - Structured report: `workers/eval-manager/task-histogram/report.json`


### Cycle total

- Workers: `2`
- Assistant turns: `66`
- Bucket tokens: `1421442`
- Cost (USD): `0.036915`
- Nonzero tool results: `1`
- Budget failures or unknown costs: `0`


## Employee decisions

### eval-manager/task-histogram

- Role: `eval-manager`
- Result: `pass`
- Report: `workers/eval-manager/task-histogram/REPORT.md`

#### Efficiency and evidence

Single trial (`task-histogram-1`) against XSH commit
`1cf4ad3d7ee5fde9b3160b11d8073cbd7ce5e7c4`, approved handbook snapshot
`lineage/handbook-approved.md`.

- Assistant turns: 52 (stop 1, toolUse 51).
- Tool calls: 58 total — `bash` 53, `edit` 1, `read` 4; tool results 58.
- Tool errors: 0 (structured `tool_errors` empty).
- Session span: 360433 ms (~6.0 min) wall, agent_wall_ms 361843; no retries.
- Worker friction: moderate. The helper-proc `?` restriction forced the worker
  through repeated controlled experiments (`/tmp/t17..t20.xsh`) before it
  learned to return `Result[Int]` from the helper and apply `?` at the call
  site. Not tool errors — exploratory trial-and-error on a language rule.

#### Handbook or proposal decision

Provisional candidate staged at
`lineage/handbook-candidate.md` (baseline + one concise addition to the
"Effects and errors" section). General lesson: to factor a fallible parse into
a helper, declare the return type `Result[T]` and apply `?` at the call site
(`?` is rejected in a plain `-> Int [error]` helper); for a strict
non-negative contract, reject signs with `^[0-9]+$` because `parse_int`
accepts an optional sign, and force a deliberate failure without a matching
typed conversion via `"".parse_int()?` (no unsigned parser, no `Error`
constructor). This is a short, general rule that removes repeated agent
friction rather than a task recipe. Replay scope: `task-histogram` and any
eval that reads a numeric field or factors a validation helper. Promotion to
`runtime/handbook.md` requires a later replay + CTO approval; this run does not
edit the approved snapshot or the checked-in handbook.

#### Ticket or product decision

- `tickets/task-histogram-005.md` — product ticket for the strict
  non-negative-integer validation ergonomics gap (unsigned parser / generic
  `Error` constructor). Links eval `task-histogram`, this manager run, executor
  `run.json`, the handbook lineage, and XSH commit
  `1cf4ad3d7ee5fde9b3160b11d8073cbd7ce5e7c4`. Open for the next cycle; not
  dispatched to engineer this cycle.
- No factory-target ticket (no infrastructure finding this run).

#### Next action

Replay `task-histogram` on the next cycle's lineage to (a) falsify or support
the staged handbook candidate (the `Result`-returning helper + strict
non-negative validation idiom) and (b) post-merge-replay `task-histogram-005`
and `task-histogram-004` once either is merged at a future XSH commit,
checking that the natural `parse_uint`/`Error` spelling and the relaxed `?`
rule keep all nine cases byte-exact.

#### North-star impact

This eval confirms XSH composes a measured distribution pipeline (typed file
read → `parse_int` → integer div to a derived bin → `group-by` keyed count →
`sort-by` → cumulative `fold` → exact output) with no subprocess escape — a
canonical systems-glue shape. The durable signal is ergonomics: two error/edge
idioms (`?` in helpers; strict unsigned validation) cost the agent real
exploration and are now (a) a staged global handbook lesson and (b) a linked
product ticket, so future agents and the language itself can make strict
numeric validation explicit, learnable, and trustworthy rather than relying on
regex-plus-empty-string hacks.



## Eval proposal review

No CTO eval review was recorded.

## Handbook lineage

Checked-in `runtime/handbook.md`: `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b`
- approved snapshot: `lineage/handbook-approved.md` sha256 `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b` — promoted by CTO ledger; matches checked-in handbook
- candidate: `lineage/handbook-candidate.md` sha256 `bf3a0c802847dfd9d940c1cb7317854fb6b49b26d2a530dd7863c630030b03b0` — DIFFERS; CTO promotion or rejection decision required


## Historical handbook backlog

Historical candidates: 84; differing: 78; ledger-dispositioned: 77; unresolved: 1.
Unresolved candidates requiring one explicit CTO decision:
- `runs/run-1785967719321/phases/03-eval/lineage/handbook-candidate.md` sha256 `bf3a0c802847dfd9d940c1cb7317854fb6b49b26d2a530dd7863c630030b03b0`


## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
