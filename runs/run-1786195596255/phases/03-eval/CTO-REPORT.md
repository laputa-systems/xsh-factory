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
- `workers/eval-manager/task-bigfiles/report.json`: result `pass`; report `workers/eval-manager/task-bigfiles/report.json`
- `workers/eval-worker/task-bigfiles-1/report.json`: result `pass`; report `workers/eval-worker/task-bigfiles-1/report.json`


## Employee accounting

### Worker metrics

- `eval-manager/task-bigfiles` (`eval-manager`): result `pass`; report `workers/eval-manager/task-bigfiles/report.json`
  - Execution: `not recorded`; classification: `not recorded`
  - Turns: `10`; bucket tokens: `379462`; thinking blocks: `8`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=10; observed_output_tps=0`
  - Tool errors: `1`; cost: `0.026323`; budget: `0.150000`
- `eval-worker/task-bigfiles-1` (`eval-worker`): result `pass`; report `workers/eval-worker/task-bigfiles-1/report.json`
  - Execution: `fail`; classification: `evaluator_failed`
  - Turns: `24`; bucket tokens: `246450`; thinking blocks: `18`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=24; observed_output_tps=0`
  - Tool errors: `0`; cost: `0.014181`; budget: `0.500000`


### Nonzero tool results
### Provider health and latency

Provider retry, latency, and attribution data are in worker `report.json`
`provider_telemetry` fields. Missing telemetry is `unknown`, not evidence of
normal provider health. Provider switching is out of scope and tracked in
`TODO.md`.

### Nonzero tool results

- `eval-manager/task-bigfiles`, turn `5`, tool `read`: ENOENT: no such file or directory, access '/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786195596255/phases/03-eval/workers/eval-worker/task-bigfiles-1/session.jsonl.events.jsonl'
  - Structured report: `workers/eval-manager/task-bigfiles/report.json`


### Cycle total

- Workers: `2`
- Assistant turns: `34`
- Bucket tokens: `625912`
- Cost (USD): `0.040503`
- Nonzero tool results: `1`
- Budget failures or unknown costs: `0`


## Employee decisions

### eval-manager/task-bigfiles

- Role: `eval-manager`
- Result: `fail`
- Report: `workers/eval-manager/task-bigfiles/REPORT.md`

#### Efficiency and evidence

- Trials: 1 (controller executed; not re-run by manager).
- Worker `task-bigfiles-1`: assistant_turns 24; tool_calls 26 (bash 22, read 1,
  write 3); tool_results 26; tool_errors 0; session_span_ms 603034 (~10.05 min),
  agent_wall_ms 604234.
- Worker friction: minimal structural friction. The agent discovered the
  filesystem API, sort-by/take, and `Str.parse_int`, and produced a correct
  artifact on the visible-only and non-dot cases. The single correctness
  failure (`hidden_default`, the dot-file case) stems from an undocumented API
  default, not from wasted exploration.
- The worker session ended with one provider-error stop (see `## Provider
  health`) before filling `review.md` findings; `review.md` remained at its
  default `None.` entries and was accepted by the evaluator (`review_ok: true`).
- Manager session: reads/writes only; no tool errors.

#### Handbook or proposal decision

Provisional candidate staged at
`runs/run-1786195596255/phases/03-eval/lineage/handbook-candidate.md` (approved
snapshot copied unchanged plus a new `## Hidden (dot) entries` section). The
general lesson: recursive discovery through `fs.files`/`fs.walk` omits hidden
dot entries by default, so pass `hidden: true` when a complete listing is
required. Replay scope: re-run `task-bigfiles` (whose `hidden_default` case
makes this observable) and at least one other discovery eval, e.g.
`task-findexec` or `task-histogram`, to confirm agents select `hidden: true`
from the handbook and remain byte-exact. Promotion to `runtime/handbook.md`
requires those replays and CTO approval.

#### Ticket or product decision

Zero. The one strong, reproducible observation (undocumented `hidden: false`
default) is already carried by the approved product ticket `task-bigfiles-004`
(next unused focused identity); this run's `hidden_default` failure is
additional evidence for it, not a new ticket.

#### Next action

Re-run `task-bigfiles` at the same XSH baseline `c77b01a3e2fb676cc57cdeddbb7575be7723aa32`
against `runs/run-1786195596255/phases/03-eval/lineage/handbook-candidate.md` to
verify the worker selects `hidden: true` and passes all nine cases (especially
`hidden_default`). Cross-replay a second discovery eval to confirm the
lesson generalizes before the candidate is promoted to `runtime/handbook.md`.

#### North-star impact

This run isolates a silent-behavior trap in recursive filesystem discovery:
dot entries are omitted by default while the contract does not say so, so a
correct-looking program quietly misses files. A short, general handbook rule —
pass `hidden: true` for complete discovery — plus the already-approved product
fix (document the default in `xsht api`) make discovery explicit and
trustworthy, directly serving the learnability and trust goals in the north
star. It advances "practical, learnable, ergonomic, trustworthy XSH" by removing
a fixture-experiment dependency for a canonical `find | sort | head`-style
systems task, rather than rewarding a task-specific workaround.



## Eval proposal review

No CTO eval review was recorded.

## Handbook lineage

Checked-in `runtime/handbook.md`: `9822e4305181e651c4a587b64afd487074216fae532c9a678f25a4d2f59fb3f8`
- approved snapshot: `factory-source/handbook-approved.md` sha256 `9822e4305181e651c4a587b64afd487074216fae532c9a678f25a4d2f59fb3f8` — promoted by CTO ledger; matches checked-in handbook
- approved snapshot: `lineage/handbook-approved.md` sha256 `9822e4305181e651c4a587b64afd487074216fae532c9a678f25a4d2f59fb3f8` — promoted by CTO ledger; matches checked-in handbook
- candidate: `lineage/handbook-candidate.md` sha256 `0dbed10e9498664adcc49a1007561584ef473178e6fbfeffbe92b442b67f2a9e` — DIFFERS; CTO promotion or rejection decision required


## Historical handbook backlog

Historical candidates: 83; differing: 81; ledger-dispositioned: 79; unresolved: 2.
Unresolved candidates requiring one explicit CTO decision:
- `runs/run-1786195596255/phases/02-reeval-task-bigfiles-004/lineage/handbook-candidate.md` sha256 `100f31a8317586a097c8fc3e0381ccbf83005a4ab28a4b77e80de366e0b773a7`
- `runs/run-1786195596255/phases/03-eval/lineage/handbook-candidate.md` sha256 `0dbed10e9498664adcc49a1007561584ef473178e6fbfeffbe92b442b67f2a9e`


## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
