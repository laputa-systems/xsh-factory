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
  - Turns: `14`; bucket tokens: `436007`; thinking blocks: `12`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=14; observed_output_tps=0`
  - Tool errors: `0`; cost: `0.014085`; budget: `0.150000`
- `eval-worker/task-histogram-1` (`eval-worker`): result `pass`; report `workers/eval-worker/task-histogram-1/report.json`
  - Execution: `pass`; classification: `pass`
  - Turns: `79`; bucket tokens: `2139493`; thinking blocks: `60`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=79; observed_output_tps=0`
  - Tool errors: `2`; cost: `0.052988`; budget: `0.500000`


### Nonzero tool results
### Provider health and latency

Provider retry, latency, and attribution data are in worker `report.json`
`provider_telemetry` fields. Missing telemetry is `unknown`, not evidence of
normal provider health. Provider switching is out of scope and tracked in
`TODO.md`.

### Nonzero tool results

- `eval-worker/task-histogram-1`, turn `71`, tool `bash`: === lint ===
=== fmt ===
=== rerun tests ===
0 3 3
1 4 7
exit=0
runtime traceback
executable: /usr/local/bin/xsh
operation: result.propagate
error: fs-read: No such file or directory (os error 2)
call path:
  1. proc main at histogram.xsh:1:1-1:1


Command exited with code 3
  - Structured report: `workers/eval-worker/task-histogram-1/report.json`
- `eval-worker/task-histogram-1`, turn `72`, tool `bash`: ls: /work/s.txt: No such file or directory
---
runtime traceback
executable: /usr/local/bin/xsh
operation: result.propagate
error: fs-read: No such file or directory (os error 2)
call path:
  1. proc main at histogram.xsh:1:1-1:1


Command exited with code 3
  - Structured report: `workers/eval-worker/task-histogram-1/report.json`


### Cycle total

- Workers: `2`
- Assistant turns: `93`
- Bucket tokens: `2575500`
- Cost (USD): `0.067073`
- Nonzero tool results: `2`
- Budget failures or unknown costs: `0`


## Employee decisions

### eval-manager/task-histogram

- Role: `eval-manager`
- Result: `pass`
- Report: `workers/eval-manager/task-histogram/REPORT.md`

#### Efficiency and evidence

- Trial 1 (`task-histogram-1`): 79 assistant turns, 89 tool calls
  (83 bash, 3 read, 1 edit, 2 write), 89 tool results, 2 tool errors, session
  span 741927 ms (agent wall 743883 ms). Stop reasons: 1 `stop`, 78 `toolUse`.
- Worker friction: moderate. The agent reached a correct, clean solution but
  spent roughly 30 turns probing Result / error / match / require / halt /
  assert discovery after the `?` helper restriction blocked its first
  `parse_uint` helper, and 4–5 turns confirming the integer-division operator
  (`/`, with no `//`). The remaining pipeline (read_text, sort-by, group-by,
  fold, fp interpolation) was straightforward from the handbook.
- The 2 tool errors are ordinary self-test friction (missing `/work/s.txt`
  during a pre-submission test), not eval or handbook impact.

#### Handbook or proposal decision

Provisional candidate staged at
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785965138991/phases/03-eval/lineage/handbook-candidate.md`.
It is a one-trial plan (single controller trial), so it was NOT replayed this
cycle. Two general, short additions:
1. postfix `?` requires a Result-returning (or Unit `main`) context — a plain
   value-returning `[error]` helper cannot use `?`; inline or return `Result`.
2. integer division is `/` (truncated quotient), remainder `%`, with no `//`
   operator.
Replay scope: any future eval with typed validation helpers or integer-division
binning should confirm the `?`-context note removes the helper wall and the
division note removes operator guesswork. Promotion to `runtime/handbook.md`
requires CTO review and replay across more than one eval.

#### Ticket or product decision

- `/Users/josh/d/laputa-systems/xsh-factory/tickets/task-histogram-004.md`
  (Open, product): postfix `?` should be accepted in any proc declaring the
  `error` effect, removing the Result-returning-context asymmetry. Merge-record
  placeholders left untouched. Open for the next cycle.

#### Next action

Re-run `task-histogram` (and one additional helper-heavy eval) against the
staged handbook candidate and against the merged `task-histogram-004` change
(if approved). Verify: (a) the `?`-context and division notes remove the
~30-turn discovery wall while keeping 9/9 byte-exact, and (b) the checker
relaxation is accepted with no regression. This is the falsification check for
both the handbook candidate and the ticket.

#### North-star impact

The eval demonstrates that XSH's typed read/parse/sort/fold idioms compose
into a correct binned cumulative distribution with no subprocess escape —
directly advancing the "practical systems glue" mission. The main product
signal is a reproducible ergonomics asymmetry in postfix `?` error propagation
that forces inlining of small validation helpers, and a discoverability gap
around integer division. Documenting the `?`-context rule and proposing a
checker relaxation target the north-star goal: fewer repeated discoveries and
clearer, more composable error handling for every future agent, with a
specific replay named to validate the change.



## Eval proposal review

No CTO eval review was recorded.

## Handbook lineage

Checked-in `runtime/handbook.md`: `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b`
- approved snapshot: `lineage/handbook-approved.md` sha256 `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b` — promoted by CTO ledger; matches checked-in handbook
- candidate: `lineage/handbook-candidate.md` sha256 `91d37b46ef5a14af294741f8e23a533f83201228a055ebd03363ceafe8891c3a` — DIFFERS; CTO promotion or rejection decision required


## Historical handbook backlog

Historical candidates: 81; differing: 75; ledger-dispositioned: 74; unresolved: 1.
Unresolved candidates requiring one explicit CTO decision:
- `runs/run-1785965138991/phases/03-eval/lineage/handbook-candidate.md` sha256 `91d37b46ef5a14af294741f8e23a533f83201228a055ebd03363ceafe8891c3a`


## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
