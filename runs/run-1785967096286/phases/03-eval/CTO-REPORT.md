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
  - Turns: `13`; bucket tokens: `318639`; thinking blocks: `11`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=13; observed_output_tps=0`
  - Tool errors: `1`; cost: `0.010059`; budget: `0.150000`
- `eval-worker/task-histogram-1` (`eval-worker`): result `pass`; report `workers/eval-worker/task-histogram-1/report.json`
  - Execution: `pass`; classification: `pass`
  - Turns: `47`; bucket tokens: `887793`; thinking blocks: `40`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=47; observed_output_tps=0`
  - Tool errors: `1`; cost: `0.024458`; budget: `0.500000`


### Nonzero tool results
### Provider health and latency

Provider retry, latency, and attribution data are in worker `report.json`
`provider_telemetry` fields. Missing telemetry is `unknown`, not evidence of
normal provider health. Provider switching is out of scope and tracked in
`TODO.md`.

### Nonzero tool results

- `eval-manager/task-histogram`, turn `10`, tool `bash`: inserted; new length 10945
---diff approved vs candidate---
158a159,172
> 
> ## Operators
> 
> XSH operators are word or symbol forms, and guessing shell conventions fails.
> Use `xsht api search:<term>` or the language summary before assuming an
> operator exists; a malformed operator is a parse error, not a fallback.
> 
> - Integer division between `Int` operands is `/` and truncates toward zero
>   (e.g. `7 / 2` is `3`). There is no `//` operator: `//` is a parse error, so
>   do not write the math notation `v // width`.
> - Boolean operators are the word forms `and` / `or`; `&&` and `||` are parse
>   errors.
> - List concatenation is `list.extend(other)` (returns a new list); `+` is not
>   list concatenation inside a stream pipeline.


Command exited with code 1
  - Structured report: `workers/eval-manager/task-histogram/report.json`
- `eval-worker/task-histogram-1`, turn `40`, tool `bash`: ls: /usr/share/hist-data.txt: No such file or directory
---
head: /usr/share/hist-data.txt: No such file or directory


Command exited with code 1
  - Structured report: `workers/eval-worker/task-histogram-1/report.json`


### Cycle total

- Workers: `2`
- Assistant turns: `60`
- Bucket tokens: `1206432`
- Cost (USD): `0.034516`
- Nonzero tool results: `2`
- Budget failures or unknown costs: `0`


## Employee decisions

### eval-manager/task-histogram

- Role: `eval-manager`
- Result: `pass`
- Report: `workers/eval-manager/task-histogram/REPORT.md`

#### Efficiency and evidence

Trial 1 (`workers/eval-worker/task-histogram-1/report.json`): 47 assistant
turns, 58 tool calls (54 `bash`, 3 `read`, 1 `write`), 58 tool results, 1 tool
error, session span 350,946 ms (~5.9 min). Worker friction was concentrated in
API/operator discovery: repeated `xsht api` probes for `parse_int`, division,
`match`, records, `delete`, and `extend`, several rejected check iterations
(parse errors for `//`, `&&`, `match` arms, `map` tail), and one failed bash
probe of a non-existent fixture path (turn 40). No protocol, budget, agent,
reporting, or evaluator failure. Correctness `pass` on all nine cases.

#### Handbook or proposal decision

Provisional candidate staged at
`runs/run-1785967096286/phases/03-eval/lineage/handbook-candidate.md`
(approved snapshot copied unchanged plus one inserted `## Operators` section).
General lesson: document XSH operator conventions — integer division is `/`
(truncating), there is no `//` operator, boolean operators are `and`/`or`,
and list concatenation is `.extend` — so agents stop rediscovering them via
parse errors. Not yet promoted: a one-trial provisional candidate becomes
trusted only after replay and CTO review.

#### Ticket or product decision

None. The two pre-existing Open tickets for this eval (`task-histogram-003`,
fold-with-print diagnostic; `task-histogram-004`, postfix `?` in a plain-return
helper) are deferred Open items carried forward by the controller; neither is a
merged post-merge assignment and neither was dispatched. This run produced no
new strong reproducible product defect, so no new ticket.

#### Next action

Replay `task-histogram` on `run-1785967096286` lineage with the `## Operators`
candidate in place, plus one independent numeric-composition eval (e.g.
`task-groupsum` or `task-colsum`) to falsify or confirm the operator lesson
before promotion to `runtime/handbook.md`. Also track whether the `map requires
a tail value` if/else-tail quirk recurs in another session as the seed for a
future secondary handbook candidate.

#### North-star impact

The run confirms the eval's hypothesis: typed integer parsing (`parse_int`),
binning via integer division, a keyed count Map, and a `sort-by` + cumulative
fold are discoverable and compose cleanly, with no subprocess escape and all
nine gates byte-exact. It also exposes a concrete learnability gap — XSH
operator conventions are undocumented, so agents rediscover `/` division,
`and`/`or`, and `.extend` through repeated parse errors. Documenting these as a
short, general rule directly advances practical, learnable, ergonomic XSH for
numeric systems-glue work and lowers token/turn cost on every future
arithmetic task.



## Eval proposal review

No CTO eval review was recorded.

## Handbook lineage

Checked-in `runtime/handbook.md`: `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b`
- approved snapshot: `lineage/handbook-approved.md` sha256 `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b` — promoted by CTO ledger; matches checked-in handbook
- candidate: `lineage/handbook-candidate.md` sha256 `ea3761e9563ed8ae34b9a9e758f04e71a739fc6d29b731fc91101f25caa3172b` — DIFFERS; CTO promotion or rejection decision required


## Historical handbook backlog

Historical candidates: 83; differing: 77; ledger-dispositioned: 76; unresolved: 1.
Unresolved candidates requiring one explicit CTO decision:
- `runs/run-1785967096286/phases/03-eval/lineage/handbook-candidate.md` sha256 `ea3761e9563ed8ae34b9a9e758f04e71a739fc6d29b731fc91101f25caa3172b`


## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
