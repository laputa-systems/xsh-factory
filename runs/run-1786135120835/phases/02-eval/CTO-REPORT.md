# CTO briefing 02-eval

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
- `workers/eval-manager/task-groupsum/report.json`: result `pass`; report `workers/eval-manager/task-groupsum/report.json`
- `workers/eval-worker/task-groupsum-1/report.json`: result `pass`; report `workers/eval-worker/task-groupsum-1/report.json`


## Employee accounting

### Worker metrics

- `eval-manager/task-groupsum` (`eval-manager`): result `pass`; report `workers/eval-manager/task-groupsum/report.json`
  - Execution: `not recorded`; classification: `not recorded`
  - Turns: `8`; bucket tokens: `228480`; thinking blocks: `7`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=8; observed_output_tps=0`
  - Tool errors: `0`; cost: `0.009458`; budget: `0.150000`
- `eval-worker/task-groupsum-1` (`eval-worker`): result `pass`; report `workers/eval-worker/task-groupsum-1/report.json`
  - Execution: `pass`; classification: `pass`
  - Turns: `66`; bucket tokens: `1625572`; thinking blocks: `50`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=66; observed_output_tps=0`
  - Tool errors: `1`; cost: `0.036716`; budget: `0.500000`


### Nonzero tool results
### Provider health and latency

Provider retry, latency, and attribution data are in worker `report.json`
`provider_telemetry` fields. Missing telemetry is `unknown`, not evidence of
normal provider health. Provider switching is out of scope and tracked in
`TODO.md`.

### Nonzero tool results

- `eval-worker/task-groupsum-1`, turn `12`, tool `bash`: xsht api: invalid API query 'language.core.results'; expected KIND:VALUE
=== postfix ===
xsht api: invalid API query 'language.core.postfix-question'; expected KIND:VALUE


Command exited with code 2
  - Structured report: `workers/eval-worker/task-groupsum-1/report.json`


### Cycle total

- Workers: `2`
- Assistant turns: `74`
- Bucket tokens: `1854052`
- Cost (USD): `0.046174`
- Nonzero tool results: `1`
- Budget failures or unknown costs: `0`


## Employee decisions

### eval-manager/task-groupsum

- Role: `eval-manager`
- Result: `pass`
- Report: `workers/eval-manager/task-groupsum/REPORT.md`

#### Efficiency and evidence

Trial 1 (`task-groupsum-1`, XSH commit
`857154dfe505f0d01053c1b5311f44422070eb34`):
- assistant turns: 66 (stop: 1, toolUse: 65)
- tool calls: 75 total (bash 66, write 4, edit 3, read 2); tool results: 75
- tool errors: 1 (single `xsht api` query-format slip, recovered next turn)
- session span: 473101 ms (~7.9 min); agent wall: 474694 ms
- worker friction: low. One minor discovery slip; no repeated exploration, no
  re-reads beyond normal reference lookups, no budget breach. Worker friction
  classification: minimal / ordinary-noise tool error.

#### Handbook or proposal decision

Unchanged. The single discovery slip is a query-format error the tool
immediately explains and corrects; the approved handbook already documents
KIND:VALUE, gives `language:core.*`/`language:effect.*` as namespace ids, and
provides the exact `language:stream.sort-by` colon example. One recovered error
is not enough to justify a handbook edit under the short-general-rule policy.
The approved snapshot was copied unchanged to
`lineage/handbook-candidate.md` (no provisional candidate staged). If the
`parse_int`/`fold` observations reproduce in a later run, a future candidate
would name the exact language-rule query and the fold/error-propagation
limitation, replayed by a Map-accumulation eval before any promotion.

#### Ticket or product decision

Zero. The single tool error was recovered noise; the two agent-flagged friction
points are single-trial observations with workarounds and were not reproduced,
so they do not meet the one-strong-reproducible-observation bar for a product
ticket.

#### Next action

Same eval `task-groupsum` against the same approved handbook lineage
(`lineage/handbook-approved.md`) at XSH commit
`857154dfe505f0d01053c1b5311f44422070eb34`. Because the run already passes,
the next replay is a falsification/regression check (no handbook change to
validate). Separately, a follow-up eval that again routes a deliberate
validation failure should watch for the two single-run observations (fold `?`
IR blocker, `parse_int` leading-sign/whitespace permissiveness) to decide
whether they generalize into a handbook rule or a product ticket.

#### North-star impact

This run is direct product signal: it demonstrates that the handbook's typed
Map (`Map.set`/`Map.get` fallback), integer parsing, and keyed stream sort
compose into a correct aggregation tool, byte-exact against an external oracle
across accumulation, byte-order, blank-lines, empty-file, and clean-failure
cases. The agent reached the correct, clear typed solution with low friction
and no shell escape, confirming the north-star hypothesis that the immutable
Map idiom and stream sort idiom are learnable together in XSH. The single
recovered discovery slip is noise; the two candidate frictions (fold `?`
limitation, parse_int permissiveness) point at ergonomic edges worth a
replay-guided look next cycle but are not yet strong enough to warrant a ticket
or handbook edit.



## Eval proposal review

No CTO eval review was recorded.

## Handbook lineage

Checked-in `runtime/handbook.md`: `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b`
- approved snapshot: `lineage/handbook-approved.md` sha256 `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b` — promoted by CTO ledger; matches checked-in handbook
- candidate: `lineage/handbook-candidate.md` sha256 `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b` — promoted by CTO ledger; matches checked-in handbook


## Historical handbook backlog

Historical candidates: 13; differing: 6; ledger-dispositioned: 5; unresolved: 1.
Unresolved candidates requiring one explicit CTO decision:
- `runs/run-1786135120835/phases/03-eval/lineage/handbook-candidate.md` sha256 `5f8e62935443becb4cef30adc28ce72aa0a697ce96df0c0d3b56fc4f3893457b`


## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
