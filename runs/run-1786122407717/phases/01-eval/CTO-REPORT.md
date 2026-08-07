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
- `workers/eval-manager/task-bigfiles/report.json`: result `pass`; report `workers/eval-manager/task-bigfiles/report.json`


## Employee accounting

### Worker metrics

- `eval-manager/task-bigfiles` (`eval-manager`): result `pass`; report `workers/eval-manager/task-bigfiles/report.json`
  - Execution: `not recorded`; classification: `not recorded`
  - Turns: `11`; bucket tokens: `217281`; thinking blocks: `9`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=11; observed_output_tps=0`
  - Tool errors: `0`; cost: `0.007256`; budget: `0.150000`


### Nonzero tool results
### Provider health and latency

Provider retry, latency, and attribution data are in worker `report.json`
`provider_telemetry` fields. Missing telemetry is `unknown`, not evidence of
normal provider health. Provider switching is out of scope and tracked in
`TODO.md`.

### Nonzero tool results

No nonzero Pi tool results were recorded.

### Cycle total

- Workers: `1`
- Assistant turns: `11`
- Bucket tokens: `217281`
- Cost (USD): `0.007256`
- Nonzero tool results: `0`
- Budget failures or unknown costs: `0`


## Employee decisions

### eval-manager/task-bigfiles

- Role: `eval-manager`
- Result: `fail`
- Report: `workers/eval-manager/task-bigfiles/REPORT.md`

#### Efficiency and evidence

The controller configured one fresh trial (`task-bigfiles`, XSH commit
`1477f472d5b4d57db3584357116ef97c32358ab6`, approved handbook
`lineage/handbook-approved.md`). The single trial did not produce a usable
agent session. The executor returned exit code 1 with
`missing session: .../workers/eval-worker/task-bigfiles-1/session.jsonl.bz2.bz2`
(`trial-1.stderr`). The worker container was created (`agent.cid`,
`evaluator.cid`) but no `session.jsonl.bz2.bz2`, no worker `report.json`, and no
evaluator manifest/`run.json` were ever written back to the host. The work
directory holds only the seeded inputs (`task.md`, `agents.md`,
`handbook.md`, and an untouched `review.md` still showing `None.`); no
`bigfiles.xsh` was produced. `container.stdout/stderr` and
`evaluator.stdout/stderr` are all empty. Per-trial turns, tools, errors, and
session span: none available (no agent session). The phase report
`report.json` correctly fail-closed: `trial-count` expected 1 observed 0,
`missing-evaluator-manifest`, `missing-worker-reports`, missing manager
report, and `handbook-lineage` candidate missing.

#### Handbook or proposal decision

Unchanged. No agent evidence was produced, so no provisional handbook
candidate can be justified. The lineage candidate
(`lineage/handbook-candidate.md`) is an exact copy of the approved snapshot
(hash `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b`),
consistent with `runtime/handbook.md`. The eval's two teachable concepts —
numeric stream ordering (`sort-by` on a per-file size plus `take`) and the
Result / `?` loud-failure idiom for a ranked-report boundary — remain
unvalidated and should be tested in the next replay. Any future candidate
must name that concept and be replayed before promotion.

#### Ticket or product decision

Zero. The session-capture failure is factory infrastructure and belongs to
the CTO, not to an engineer ticket; no reproducible XSH ergonomics or
correctness observation emerged from this run.

#### Next action

Replay `task-bigfiles` against the same XSH commit
`1477f472d5b4d57db3584357116ef97c32358ab6` and the same approved handbook
lineage (`lineage/handbook-approved.md`, which is identical to
`runtime/handbook.md`) once the controller/executor session-capture harness
is fixed so the worker `session.jsonl.bz2.bz2` (and the subsequent worker report and
evaluator manifest) are materialized. The replay is also the falsification
check for the still-open hypothesis that `sort-by` + `take` on `fs.files` is
discoverable and that the Result / `?` idiom transfers to a ranked report.

#### North-star impact

No product signal this run: the executor never captured an agent session, so
no XSH behavior, ergonomics, or learnability was measured. The run
advances the factory only in the negative sense of surfacing a fail-closed
harness defect that must be corrected before the eval can produce the
practical, learnable evidence the north star requires. The eval's core
educational goal — making numeric stream ordering and typed filesystem
filtering discoverable via the shared handbook — is unvalidated and is the
target of the next replay.



## Eval proposal review

No CTO eval review was recorded.

## Handbook lineage

Checked-in `runtime/handbook.md`: `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b`
- approved snapshot: `lineage/handbook-approved.md` sha256 `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b` — promoted by CTO ledger; matches checked-in handbook
- candidate: `lineage/handbook-candidate.md` sha256 `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b` — promoted by CTO ledger; matches checked-in handbook


## Historical handbook backlog

Historical candidates: 1; differing: 0; ledger-dispositioned: 0; unresolved: 0.
No unresolved candidate content is present.

## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
