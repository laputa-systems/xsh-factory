# CTO briefing 04-eval

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
- `workers/eval-manager/task-intsum/report.json`: result `pass`; report `workers/eval-manager/task-intsum/report.json`
- `workers/eval-worker/task-intsum-1/report.json`: result `pass`; report `workers/eval-worker/task-intsum-1/report.json`


## Employee accounting

### Worker metrics

- `eval-manager/task-intsum` (`eval-manager`): result `pass`; report `workers/eval-manager/task-intsum/report.json`
  - Execution: `not recorded`; classification: `not recorded`
  - Turns: `18`; bucket tokens: `425161`; thinking blocks: `15`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=18; observed_output_tps=0`
  - Tool errors: `0`; cost: `0.014210`; budget: `0.150000`
- `eval-worker/task-intsum-1` (`eval-worker`): result `pass`; report `workers/eval-worker/task-intsum-1/report.json`
  - Execution: `pass`; classification: `pass`
  - Turns: `19`; bucket tokens: `231217`; thinking blocks: `15`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=19; observed_output_tps=0`
  - Tool errors: `0`; cost: `0.006237`; budget: `0.500000`


### Nonzero tool results
### Provider health and latency

Provider retry, latency, and attribution data are in worker `report.json`
`provider_telemetry` fields. Missing telemetry is `unknown`, not evidence of
normal provider health. Provider switching is out of scope and tracked in
`TODO.md`.

### Nonzero tool results

No nonzero Pi tool results were recorded.

### Cycle total

- Workers: `2`
- Assistant turns: `37`
- Bucket tokens: `656378`
- Cost (USD): `0.020447`
- Nonzero tool results: `0`
- Budget failures or unknown costs: `0`


## Employee decisions

### eval-manager/task-intsum

- Role: `eval-manager`
- Result: `pass`
- Report: `workers/eval-manager/task-intsum/REPORT.md`

#### Efficiency and evidence

Trial 1 (worker `task-intsum-1`, model `openrouter/deepseek/deepseek-v4-flash-0731`):
assistant turns 19 (plus 1 user message), tool calls 20, tool results 20, tool
errors 0, thinking blocks 15. Tools used: bash 15, read 3, write 2. Session
span 124,025 ms; agent wall 128,308 ms; agent state `pass`. Budget state
`pass` ($0.5 budget). Worker friction: minimal. The two API-discovery touch
points (summary grep returning nothing; `not` rejected as negation) each cost a
single extra probe before the worker moved on; neither caused looped
exploration. 19 turns for a correct single-file program is efficient.

#### Handbook or proposal decision

Provisional candidate staged at
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786135120835/phases/04-eval/lineage/handbook-candidate.md`
(sha256 differs from approved; see file). It is a copy of the approved
snapshot plus two concise, general edits: (1) corrects the API-enumeration
guidance so `xsht api summary | grep Str` is not recommended (the summary is a
tree with counts) and points to `search:TERM` / exact `method:X.Y` queries; (2)
documents that boolean negation is `!`, not `not`. Both are general lessons for
the shared factory-wide handbook, not task-specific recipes. The candidate is
NOT promoted to `runtime/handbook.md`; promotion requires re-review and replay.
Replay scope: re-run this eval and at least one other typed-boundary eval
(e.g. a regex or env-typed task) against the candidate to confirm the corrected
enumeration guidance and the `!` idiom reduce discovery friction without
changing correct behavior.

#### Ticket or product decision

None. The summary-grep and negation lessons are concise general handbook
edits (staged as the candidate), not product defects; no strong, general XSH
ergonomics bug merits a product ticket this cycle.

#### Next action

Re-run `task-intsum` (and one additional typed/API-discovery eval, e.g.
`task-histogram` or `task-dupcheck`) against the same XSH commit
`857154dfe505f0d01053c1b5311f44422070eb34` with the `handbook-candidate.md`
lineage to falsify or confirm the corrected enumeration and negation guidance
before promotion to `runtime/handbook.md`.

#### North-star impact

This cycle demonstrates typed CLI glue done correctly: the worker summed argv
with a typed `parse_int()?` loop and an explicit strict decimal check, letting
a typed failure produce the nonzero exit rather than silently coercing `+5`,
`0x1F`, or whitespace. The run passed all public and hidden cases and is cheap
and low-friction, confirming the handbook's typed-boundary model is learnable
for this class of task. The staged candidate improves learnability and API
ergonomics by fixing two general discovery/idiom lessons (`xsht api summary`
is not a flat enumerator; negation is `!`) that will otherwise recur across
every eval, advancing the practical, learnable, ergonomic XSH north star.



## Eval proposal review

No CTO eval review was recorded.

## Handbook lineage

Checked-in `runtime/handbook.md`: `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b`
- approved snapshot: `lineage/handbook-approved.md` sha256 `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b` — promoted by CTO ledger; matches checked-in handbook
- candidate: `lineage/handbook-candidate.md` sha256 `b2069c71aa8f20b8e34b0cec2d2415f5152d81492feaa47a24df5c46a0a3dbb8` — DIFFERS; CTO promotion or rejection decision required


## Historical handbook backlog

Historical candidates: 14; differing: 7; ledger-dispositioned: 5; unresolved: 2.
Unresolved candidates requiring one explicit CTO decision:
- `runs/run-1786135120835/phases/03-eval/lineage/handbook-candidate.md` sha256 `5f8e62935443becb4cef30adc28ce72aa0a697ce96df0c0d3b56fc4f3893457b`
- `runs/run-1786135120835/phases/04-eval/lineage/handbook-candidate.md` sha256 `b2069c71aa8f20b8e34b0cec2d2415f5152d81492feaa47a24df5c46a0a3dbb8`


## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
