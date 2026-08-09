# CTO briefing 01-eval

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
- `workers/eval-manager/task-envcfg-retry-1/report.json`: result `pass`; report `workers/eval-manager/task-envcfg-retry-1/report.json`
- `workers/eval-manager/task-envcfg/report.json`: result `pass`; report `workers/eval-manager/task-envcfg/report.json`
- `workers/eval-worker/task-envcfg-1/report.json`: result `pass`; report `workers/eval-worker/task-envcfg-1/report.json`


## Employee accounting

### Worker metrics

- `eval-manager/task-envcfg-retry-1` (`eval-manager`): result `pass`; report `workers/eval-manager/task-envcfg-retry-1/report.json`
  - Execution: `not recorded`; classification: `not recorded`
  - Turns: `10`; bucket tokens: `253961`; thinking blocks: `10`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=10; observed_output_tps=0`
  - Tool errors: `1`; cost: `0.008920`; budget: `0.150000`
- `eval-manager/task-envcfg` (`eval-manager`): result `pass`; report `workers/eval-manager/task-envcfg/report.attempt-1.json`
  - Execution: `not recorded`; classification: `not recorded`
  - Turns: `3`; bucket tokens: `42272`; thinking blocks: `2`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=3; observed_output_tps=0`
  - Tool errors: `0`; cost: `0.002346`; budget: `0.150000`
- `eval-worker/task-envcfg-1` (`eval-worker`): result `pass`; report `workers/eval-worker/task-envcfg-1/report.json`
  - Execution: `pass`; classification: `pass`
  - Turns: `21`; bucket tokens: `274780`; thinking blocks: `16`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=21; observed_output_tps=0`
  - Tool errors: `2`; cost: `0.007483`; budget: `0.500000`


### Nonzero tool results
### Provider health and latency

Provider retry, latency, and attribution data are in worker `report.json`
`provider_telemetry` fields. Missing telemetry is `unknown`, not evidence of
normal provider health. Provider switching is out of scope and tracked in
`TODO.md`.

### Nonzero tool results

- `eval-manager/task-envcfg-retry-1`, turn `5`, tool `edit`: Could not find edits[2] in /Users/josh/d/laputa-systems/xsh-factory/runs/run-1786254016688/phases/01-eval/workers/eval-manager/task-envcfg-retry-1/REPORT.md. The oldText must match exactly including all whitespace and newlines.
  - Structured report: `workers/eval-manager/task-envcfg-retry-1/report.json`
- `eval-worker/task-envcfg-1`, turn `5`, tool `bash`: sh: syntax error: unexpected "("


Command exited with code 2
  - Structured report: `workers/eval-worker/task-envcfg-1/report.json`
- `eval-worker/task-envcfg-1`, turn `13`, tool `bash`: --- invalid abc
runtime traceback
executable: /usr/local/bin/xsh
operation: result.propagate
error: parse-int: invalid integer `abc`
call path:
  1. proc main at envcfg.xsh:1:1-1:1
exit=3
ls: /tmp/o4: No such file or directory
--- empty port
runtime traceback
executable: /usr/local/bin/xsh
operation: result.propagate
error: parse-int: invalid integer ``
call path:
  1. proc main at envcfg.xsh:1:1-1:1
exit=3
ls: /tmp/o5: No such file or directory
--- leading zeros
exit=0
host=localhost
port=09001
debug=false
--- plus sign (invalid per oracle)
runtime traceback
executable: /usr/local/bin/xsh
operation: result.propagate
error: parse-int: invalid integer `+5`
call path:
  1. proc main at envcfg.xsh:1:1-1:1
exit=3
ls: /tmp/o7: No such file or directory
--- space
runtime traceback
executable: /usr/local/bin/xsh
operation: result.propagate
error: parse-int: invalid integer ` 7`
call path:
  1. proc main at envcfg.xsh:1:1-1:1
exit=3
ls: /tmp/o8: No such file or directory


Command exited with code 1
  - Structured report: `workers/eval-worker/task-envcfg-1/report.json`


### Cycle total

- Workers: `3`
- Assistant turns: `34`
- Bucket tokens: `571013`
- Cost (USD): `0.018749`
- Nonzero tool results: `3`
- Budget failures or unknown costs: `0`


## Employee decisions

### eval-manager/task-envcfg-retry-1

- Role: `eval-manager`
- Result: `pass`
- Report: `workers/eval-manager/task-envcfg-retry-1/REPORT.md`

#### Efficiency and evidence

One trial (controller configured count `1`). Single eval-worker
`task-envcfg-1`, result `pass`, valid `true`. Worker reported
`assistant_turns: 21`, `tool_calls: 26`, `tool_results: 26`,
`tool_errors: 2`, `user_messages: 1`, `thinking_blocks: 16`. Worker
`session_span_ms: 102322` (~102s), `agent_wall_ms: 103507`. Stop reasons: 20
`toolUse` + 1 `stop`. Tool mix: `bash` 20, `read` 3, `edit` 2, `write` 1.
Model: `openrouter/deepseek/deepseek-v4-flash-0731`.

Trial 1 `evidence`: `classification: pass`, `correctness: pass`,
`restrictions: pass`, `protocol: pass`, `timing: pass`, `passed: true`,
`valid: true`, `result: pass`. No budget failures (`budget_failures: 0`).

#### Handbook or proposal decision

Unchanged. The approved snapshot
`runs/run-1786254016688/phases/01-eval/lineage/handbook-approved.md`
(sha256 `eba997ebd583ac6f2eb0ac48feaf701f64696fcaf72e93626fae238102b46d32`)
is copied unchanged to
`runs/run-1786254016688/phases/01-eval/lineage/handbook-candidate.md`. The
env/config surface (typed `env.int`/`env.bool` are convenience readers, not
strict validators; fallbacks apply on absence, not emptiness; `?` on a typed
conversion produces the nonzero exit and no partial file) already taught in
the handbook and was exercised correctly here; no candidate change is
proposed this cycle. Replay scope for a future env-handbook change would be
any `task-envcfg` rerun plus a second env-reading eval.

#### Ticket or product decision

None. The worker friction (one probe typo) is ordinary noise; no strong,
generalizable, reproducible product defect was found. No pre-manager ticket
was modified. Pre-manager ticket identities listed by the controller are
immutable and were not written.

#### Next action

`task-envcfg` next cycle against the unchanged approved handbook lineage
(`runs/run-1786254016688/phases/01-eval/lineage/handbook-approved.md`), XSH
commit `e2a609a94d8f624b8dc7cc1efae62a2691d3cbc8`. Falsification check:
confirm the malformed/empty-port failure controls still exit nonzero with no
output file and present-but-empty variables are kept (not defaulted) on
replay. No candidate branch to retain (`not-reevaluation`).

#### North-star impact

Demonstrates XSH's env/config surface as practical systems glue: typed
environment reads with absence-only defaults, a byte-exact config deliverable,
and expected malformed-value failures made loud with no partial file. That a
fresh worker, not the proposal author, reached a passing solution on the
standalone handbook is evidence the env/`?` idioms are learnable and
composable rather than task-special tricks — a step toward the ergonomic,
trustworthy systems language the north star targets.

### eval-manager/task-envcfg

- Role: `eval-manager`
- Result: `pass`
- Report: `workers/eval-manager/task-envcfg/REPORT.md`

#### Efficiency and evidence

One trial (controller configured count `1`). Single eval-worker
`task-envcfg-1`, result `pass`, valid `true`. Worker reported
`assistant_turns: 21`, `tool_calls: 26`, `tool_results: 26`,
`tool_errors: 2`, `user_messages: 1`, `thinking_blocks: 16`. Worker
`session_span_ms: 102322` (~102s), `agent_wall_ms: 103507`. Stop reasons: 20
`toolUse` + 1 `stop`. Tool mix: `bash` 20, `read` 3, `edit` 2, `write` 1.
Model: `openrouter/deepseek/deepseek-v4-flash-0731`.

Trial 1 `evidence`: `classification: pass`, `correctness: pass`,
`restrictions: pass`, `protocol: pass`, `timing: pass`, `passed: true`,
`valid: true`, `result: pass`. No budget failures (`budget_failures: 0`).

#### Handbook or proposal decision

Unchanged. The approved snapshot
`runs/run-1786254016688/phases/01-eval/lineage/handbook-approved.md`
(sha256 `eba997ebd583ac6f2eb0ac48feaf701f64696fcaf72e93626fae238102b46d32`)
is copied unchanged to
`runs/run-1786254016688/phases/01-eval/lineage/handbook-candidate.md`. The
env/config surface (typed `env.int`/`env.bool` are convenience readers, not
strict validators; fallbacks apply on absence, not emptiness; `?` on a typed
conversion produces the nonzero exit and no partial file) already taught in
the handbook and was exercised correctly here; no candidate change is
proposed this cycle. Replay scope for a future env-handbook change would be
any `task-envcfg` rerun plus a second env-reading eval.

#### Ticket or product decision

None. The worker friction (one probe typo) is ordinary noise; no strong,
generalizable, reproducible product defect was found. No pre-manager ticket
was modified. Pre-manager ticket identities listed by the controller are
immutable and were not written.

#### Next action

`task-envcfg` next cycle against the unchanged approved handbook lineage
(`runs/run-1786254016688/phases/01-eval/lineage/handbook-approved.md`), XSH
commit `e2a609a94d8f624b8dc7cc1efae62a2691d3cbc8`. Falsification check:
confirm the malformed/empty-port failure controls still exit nonzero with no
output file and present-but-empty variables are kept (not defaulted) on
replay. No candidate branch to retain (`not-reevaluation`).

#### North-star impact

Demonstrates XSH's env/config surface as practical systems glue: typed
environment reads with absence-only defaults, a byte-exact config deliverable,
and expected malformed-value failures made loud with no partial file. That a
fresh worker, not the proposal author, reached a passing solution on the
standalone handbook is evidence the env/`?` idioms are learnable and
composable rather than task-special tricks — a step toward the ergonomic,
trustworthy systems language the north star targets.



## Eval proposal review

No CTO eval review was recorded.

## Handbook lineage

Checked-in `runtime/handbook.md`: `eba997ebd583ac6f2eb0ac48feaf701f64696fcaf72e93626fae238102b46d32`
- approved snapshot: `factory-source/handbook-approved.md` sha256 `eba997ebd583ac6f2eb0ac48feaf701f64696fcaf72e93626fae238102b46d32` — matches checked-in handbook
- approved snapshot: `lineage/handbook-approved.md` sha256 `eba997ebd583ac6f2eb0ac48feaf701f64696fcaf72e93626fae238102b46d32` — matches checked-in handbook
- candidate: `lineage/handbook-candidate.md` sha256 `e60b70ebb4e3e33f897ae366feaba0aa43d5dd698ac79f2f28d0ceb42f970e4a` — DIFFERS; CTO promotion or rejection decision required


## Historical handbook backlog

Historical candidates: 143; differing: 140; ledger-dispositioned: 139; unresolved: 1.
Unresolved candidates requiring one explicit CTO decision:
- `runs/run-1786254016688/phases/01-eval/lineage/handbook-candidate.md` sha256 `e60b70ebb4e3e33f897ae366feaba0aa43d5dd698ac79f2f28d0ceb42f970e4a`


## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
