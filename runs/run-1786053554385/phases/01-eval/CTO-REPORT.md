# CTO briefing 01-eval

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
- `workers/eval-manager/task-grep/report.json`: result `pass`; report `workers/eval-manager/task-grep/report.json`


## Employee accounting

### Worker metrics

- `eval-manager/task-grep` (`eval-manager`): result `pass`; report `workers/eval-manager/task-grep/report.json`
  - Execution: `not recorded`; classification: `not recorded`
  - Turns: `20`; bucket tokens: `396583`; thinking blocks: `18`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=20; observed_output_tps=0`
  - Tool errors: `4`; cost: `0.011914`; budget: `0.150000`


### Nonzero tool results
### Provider health and latency

Provider retry, latency, and attribution data are in worker `report.json`
`provider_telemetry` fields. Missing telemetry is `unknown`, not evidence of
normal provider health. Provider switching is out of scope and tracked in
`TODO.md`.

### Nonzero tool results

- `eval-manager/task-grep`, turn `3`, tool `read`: ENOENT: no such file or directory, access '/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786053554385/trial-1.stderr'
  - Structured report: `workers/eval-manager/task-grep/report.json`
- `eval-manager/task-grep`, turn `3`, tool `read`: ENOENT: no such file or directory, access '/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786053554385/trial-1.stdout'
  - Structured report: `workers/eval-manager/task-grep/report.json`
- `eval-manager/task-grep`, turn `3`, tool `read`: ENOENT: no such file or directory, access '/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786053554385/manager.stderr'
  - Structured report: `workers/eval-manager/task-grep/report.json`
- `eval-manager/task-grep`, turn `3`, tool `read`: ENOENT: no such file or directory, access '/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786053554385/manager.stdout'
  - Structured report: `workers/eval-manager/task-grep/report.json`


### Cycle total

- Workers: `1`
- Assistant turns: `20`
- Bucket tokens: `396583`
- Cost (USD): `0.011914`
- Nonzero tool results: `4`
- Budget failures or unknown costs: `0`


## Employee decisions

### eval-manager/task-grep

- Role: `eval-manager`
- Result: `fail`
- Report: `workers/eval-manager/task-grep/REPORT.md`

#### Efficiency and evidence

- Trials configured: `1`; trials with recorded evidence: `0`.
- Worker sessions: `0` (no `session.jsonl.bz2.bz2` produced).
- Assistant turns: `0`. Tool calls: `0`. Tool errors: `0`.
- Session span: n/a (no Pi conversation began/recorded).
- Worker friction: n/a — no agent ran to completion.

#### Handbook or proposal decision

Unchanged. The approved snapshot `lineage/handbook-approved.md` (sha
`3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b`, identical
to the checked-in `runtime/handbook.md`) is staged unchanged as
`lineage/handbook-candidate.md` (same sha). No provisional candidate is
justified: there was no agent session from which to derive a reusable lesson.
Promotion requires a successful replay, which this run could not produce.

#### Ticket or product decision

None. The observed failure is a factory infrastructure issue (executor failed
to produce the worker's canonical session artifact). Per policy, factory
infrastructure changes belong to the CTO, not to an engineer ticket, so no
`templates/TICKET.md` product ticket is opened.

#### Next action

Re-run `task-grep` (one trial) against the identical approved handbook lineage
after the CTO resolves the executor/worker infra failure. The replay must
produce a real `eval-worker/task-grep-1/session.jsonl.bz2.bz2`, a candidate
`grep.xsh`, an evaluator `run.json`, and a worker `REPORT.md` before any
manager-side evaluation, handbook candidate, or ticket decision is meaningful.

#### North-star impact

No XSH capability was exercised this run: the single trial failed at the
factory executor boundary before an agent could read the handbook, write a
typed text-pipeline program, or be measured for correctness, learnability, or
ergonomics. The run therefore produces no product signal and no north-star
advance. Its only durable value is a factory finding — the worker session
artifact pipeline did not run — that the CTO must repair so a future
`task-grep` trial can actually measure whether XSH's line-stream text APIs
compose humanely for real sysadmin glue work.



## Eval proposal review

No CTO eval review was recorded.

## Handbook lineage

Checked-in `runtime/handbook.md`: `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b`
- approved snapshot: `lineage/handbook-approved.md` sha256 `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b` — promoted by CTO ledger; matches checked-in handbook
- candidate: `lineage/handbook-candidate.md` sha256 `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b` — promoted by CTO ledger; matches checked-in handbook


## Historical handbook backlog

Historical candidates: 95; differing: 88; ledger-dispositioned: 88; unresolved: 0.
No unresolved candidate content is present.

## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
