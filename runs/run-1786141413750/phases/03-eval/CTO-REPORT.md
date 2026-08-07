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
- `workers/eval-manager/task-render/report.json`: result `pass`; report `workers/eval-manager/task-render/report.json`
- `workers/eval-worker/task-render-1/report.json`: result `pass`; report `workers/eval-worker/task-render-1/report.json`


## Employee accounting

### Worker metrics

- `eval-manager/task-render` (`eval-manager`): result `pass`; report `workers/eval-manager/task-render/report.json`
  - Execution: `not recorded`; classification: `not recorded`
  - Turns: `20`; bucket tokens: `1024357`; thinking blocks: `17`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=20; observed_output_tps=0`
  - Tool errors: `1`; cost: `0.025807`; budget: `0.150000`
- `eval-worker/task-render-1` (`eval-worker`): result `pass`; report `workers/eval-worker/task-render-1/report.json`
  - Execution: `pass`; classification: `pass`
  - Turns: `33`; bucket tokens: `649370`; thinking blocks: `30`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=33; observed_output_tps=0`
  - Tool errors: `0`; cost: `0.016575`; budget: `0.500000`


### Nonzero tool results
### Provider health and latency

Provider retry, latency, and attribution data are in worker `report.json`
`provider_telemetry` fields. Missing telemetry is `unknown`, not evidence of
normal provider health. Provider switching is out of scope and tracked in
`TODO.md`.

### Nonzero tool results

- `eval-manager/task-render`, turn `16`, tool `edit`: Could not find the exact text in /Users/josh/d/laputa-systems/xsh-factory/tickets/task-render-001.md. The old text must match exactly including all whitespace and newlines.
  - Structured report: `workers/eval-manager/task-render/report.json`


### Cycle total

- Workers: `2`
- Assistant turns: `53`
- Bucket tokens: `1673727`
- Cost (USD): `0.042382`
- Nonzero tool results: `1`
- Budget failures or unknown costs: `0`


## Employee decisions

### eval-manager/task-render

- Role: `eval-manager`
- Result: `pass`
- Report: `workers/eval-manager/task-render/REPORT.md`

#### Efficiency and evidence

Trial 1 (single trial; controller executed 1 fresh trial):
- Assistant turns: 33 (1 user message).
- Tool calls: 35; tool results: 35; tool errors: 0.
- Tool breakdown: bash 30, read 3, edit 1, write 1. Stop reasons: 32 × `toolUse`, 1 × `stop`.
- Session span: `session_span_ms` 235166 (~235 s); `agent_wall_ms` 236362.
- Worker friction: one notable exploration episode — discovering how to construct a `Map` (five failed literal/constructor probes before finding `map.empty()`). Otherwise a linear read → api-query → write → check/fmt/lint → oracle-compare loop with no rework. No provider retries or errors (`retry_successes 0`, `provider_errors []`), so wall time is not attributable to external health; latency attribution `normal`.

#### Handbook or proposal decision

Provisional candidate staged at `runs/run-1786141413750/phases/03-eval/lineage/handbook-candidate.md`. The approved snapshot is unchanged and is the authoritative baseline; the candidate adds one concise, general lesson under "Streams and collections": create a Map from scratch with the module function `map.empty()` (the `{}` literal is a Record, not a Map, so `.set` on it is rejected), then grow it with `Map.set` and read with `Map.get`. General lesson: "to build a typed key→value map from parsed text, start from `map.empty()`". Replay scope: this candidate was NOT replayed this cycle (single-trial plan); promote only after the controller replays `task-render` and at least one second map-building eval (e.g. `task-dupcheck` or `task-histogram`) on the same shared lineage, verifying the map is constructed without the `grep summary | map.empty` detour.

#### Ticket or product decision

- `/Users/josh/d/laputa-systems/xsh-factory/tickets/task-render-001.md` — product ticket (open, next cycle): `xsht api`/API-registry does not cross-index `module.map.empty` under the `Map` type, and `{}` is a Record with no obvious Map constructor, so an agent building a `Map` from text cannot discover construction. Links this eval, this manager run, the executor session/evidence, the handbook lineage, and XSH baseline `a248267612439dfcfa203fba583ac3e95d37f70c`. Merge-record placeholders left untouched.

#### Next action

Replay `task-render` on the same shared handbook lineage (`lineage/handbook-approved.md` → promote `handbook-candidate.md`) at the XSH baseline/next commit, checking that the worker constructs the Map on the first attempt (no `map`-summary grep) and still matches the awk oracle byte-for-byte. Falsification check: a second map-building eval (`task-dupcheck` or `task-histogram`) must demonstrate the same first-attempt Map construction before the candidate is trusted; replay `task-render-001` post-merge to confirm the `xsht api` indexing fix generalizes.

#### North-star impact

This run demonstrates XSH's core practical glue shape — read two files, fold parsed `KEY=value` lines into a typed `Map[Str]`, and substitute placeholders into a byte-exact output — solved correctly and cheaply (33 turns, $0.017, 0 tool errors), validating the handbook's typed-value and stream lessons. The one durable signal is that Map construction is not discoverable: a single general rule (`map.empty()` for a fresh Map; `{}` is a Record) plus one indexed `xsht api` tooling fix would remove the only real friction and compound across every future map-building eval, improving learnability and ergonomics as the handbook and `xsht api` are consumed by agents. This advances the north star by making the Map/collection boundary explicit and learnable rather than a per-task workaround.



## Eval proposal review

No CTO eval review was recorded.

## Handbook lineage

Checked-in `runtime/handbook.md`: `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b`
- approved snapshot: `lineage/handbook-approved.md` sha256 `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b` — promoted by CTO ledger; matches checked-in handbook
- candidate: `lineage/handbook-candidate.md` sha256 `134025e768dd555c713c9ba269505d968a820f38655a593aeea36eeca1094870` — DIFFERS; CTO promotion or rejection decision required


## Historical handbook backlog

Historical candidates: 24; differing: 13; ledger-dispositioned: 12; unresolved: 1.
Unresolved candidates requiring one explicit CTO decision:
- `runs/run-1786141413750/phases/03-eval/lineage/handbook-candidate.md` sha256 `134025e768dd555c713c9ba269505d968a820f38655a593aeea36eeca1094870`


## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
