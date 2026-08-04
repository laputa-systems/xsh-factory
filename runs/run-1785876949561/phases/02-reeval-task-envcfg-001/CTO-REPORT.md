# CTO briefing 02-reeval-task-envcfg-001

This is the deterministic first-pass briefing for the CTO. The structured
`report.json` files and raw Pi sessions remain the source of truth.

## Result

fail
## Result

fail

## Outcome dimensions

- Product: `pass`
- Evaluator: `pass`
- Infrastructure: `fail`

## Operating context

- Mode: `eval`
- Request: `CYCLE-REQUEST.md`
- Structured report: `report.json`

## Phase outcomes

- `report.json`: result `fail`; report `report.json`
- `workers/eval-manager/task-envcfg/report.json`: result `pass`; report `workers/eval-manager/task-envcfg/report.json`
- `workers/eval-worker/task-envcfg-1/report.json`: result `pass`; report `workers/eval-worker/task-envcfg-1/report.json`


## Employee accounting

### Worker metrics

- `eval-manager/task-envcfg` (`eval-manager`): result `pass`; report `workers/eval-manager/task-envcfg/report.json`
  - Execution: `not recorded`; classification: `not recorded`
  - Turns: `16`; bucket tokens: `714866`; thinking blocks: `13`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=16; observed_output_tps=0`
  - Tool errors: `0`; cost: `0.019613`; budget: `0.150000`
- `eval-worker/task-envcfg-1` (`eval-worker`): result `pass`; report `workers/eval-worker/task-envcfg-1/report.json`
  - Execution: `pass`; classification: `pass`
  - Turns: `24`; bucket tokens: `286162`; thinking blocks: `12`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=24; observed_output_tps=0`
  - Tool errors: `0`; cost: `0.007477`; budget: `0.500000`


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
- Assistant turns: `40`
- Bucket tokens: `1001028`
- Cost (USD): `0.027090`
- Nonzero tool results: `0`
- Budget failures or unknown costs: `0`


## Employee decisions

### eval-manager/task-envcfg

- Role: `eval-manager`
- Result: `pass`
- Report: `workers/eval-manager/task-envcfg/REPORT.md`

#### Efficiency and evidence

Trial 1 (worker `task-envcfg-1`, the only configured trial; one-trial plan):
- assistant turns: 24 (1 user message, 23 tool-use turns, 1 stop)
- tool calls: 30; tool results: 30; tool errors: 0
- tool mix: bash 22, read 3, write 2, edit 3
- session span: 136,615 ms (agent wall 138,088 ms)
- worker friction: minimal. The agent read `/work/task.md`, `agents.md`, and
  the handbook, then discovered the correct env/fs API surface through
  `xsht api`. It twice probed unavailable string methods (`search:is_empty`,
  `search:isEmpty` -> `status: missing`) and made one malformed `xsht api`
  query (`language.core.path-literals` -> `invalid API query`), recovering on
  the next probe. It hit one `||` parse error and self-corrected to `or`
  (word form). No repeated exploration or churn beyond that.

#### Handbook or proposal decision

Provisional candidate staged. The standalone observation: teach the
deliberate-validation primitive. The approved handbook directs agents to
route a deliberate rejection through an unrelated typed conversion because
"this build has no generic `Error(...)` constructor"; that guidance is now
obsolete because `fail(message)?` exists and is discoverable via
`xsht api language:core.fail`. Candidate replaces those lines with a rule to
use `fail(...)?` for deliberate validation failure and to prefer it over a
sentinel typed conversion.

Staged at
`runs/run-1785876949561/phases/02-reeval-task-envcfg-001/lineage/handbook-candidate.md`
(one targeted edit; otherwise identical to the approved snapshot
`97c5d804...`). Global scope: the lesson applies to any eval gating on a loud
nonzero config/args-validation exit (e.g. `task-ecount`, `task-tags`), not just
`task-envcfg`. Promotion requires a later replay plus CTO approval.

#### Ticket or product decision

Zero. The candidate fix (XSH `fail` primitive) is already implemented in the
engineer worktree at commit `754fcba` and passes this replay; no new product
ticket is warranted. The single reusable handbook change is staged as a
candidate for replay, not a ticket.

#### Next action

Replay `task-envcfg` once more against the approved handbook that promotes the
`fail(...)?` deliberate-error lesson (after CTO approval), and optionally
replay `task-ecount`/`task-tags` to confirm the lesson generalizes across
validation-boundary evals. Also confirm the stale "no generic `Error`"
sentence is fully removed from the promoted handbook.

#### North-star impact

This run validates the first-class deliberate-error primitive (`fail(message)?`
propagating through `?` with kind `validation`), which lets programs reject
malformed config clearly and exit nonzero without creating a partial file —
exactly the structured-error, expected-failures-visible goal in the north
star. It removes the opaque `parse_int` sentinel workaround that previously
contradicted the handbook's own guidance. The parallel handbook candidate
teaches this reusable lesson globally so agents stop rediscovering `fail` via
`xsht api` in every future validation eval.



## Eval proposal review

No CTO eval review was recorded.

## Handbook lineage

Checked-in `runtime/handbook.md`: `97c5d804c42c7742c9edfea4480163828d864279391d391df77aa60ee4a40e83`
- approved snapshot: `lineage/handbook-approved.md` sha256 `97c5d804c42c7742c9edfea4480163828d864279391d391df77aa60ee4a40e83` — promoted by CTO ledger; matches checked-in handbook
- candidate: `lineage/handbook-candidate.md` sha256 `b67607ea2dc717d2430ea3a82de6cf2e16a0b54a94ef59595aa00b8a715933e0` — DIFFERS; CTO promotion or rejection decision required


## Historical handbook backlog

Historical candidates: 59; differing: 38; ledger-dispositioned: 37; unresolved: 1.
Unresolved candidates requiring one explicit CTO decision:
- `runs/run-1785876949561/phases/02-reeval-task-envcfg-001/lineage/handbook-candidate.md` sha256 `b67607ea2dc717d2430ea3a82de6cf2e16a0b54a94ef59595aa00b8a715933e0`


## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
