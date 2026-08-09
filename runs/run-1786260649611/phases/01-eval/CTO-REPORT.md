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
- `workers/eval-manager/task-intsum/report.json`: result `pass`; report `workers/eval-manager/task-intsum/report.json`
- `workers/eval-worker/task-intsum-1/report.json`: result `pass`; report `workers/eval-worker/task-intsum-1/report.json`


## Employee accounting

### Worker metrics

- `eval-manager/task-intsum` (`eval-manager`): result `pass`; report `workers/eval-manager/task-intsum/report.json`
  - Execution: `not recorded`; classification: `not recorded`
  - Turns: `18`; bucket tokens: `354782`; thinking blocks: `12`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=18; observed_output_tps=0`
  - Tool errors: `2`; cost: `0.010152`; budget: `0.150000`
- `eval-worker/task-intsum-1` (`eval-worker`): result `pass`; report `workers/eval-worker/task-intsum-1/report.json`
  - Execution: `pass`; classification: `pass`
  - Turns: `24`; bucket tokens: `265249`; thinking blocks: `17`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=24; observed_output_tps=0`
  - Tool errors: `1`; cost: `0.006884`; budget: `0.500000`


### Nonzero tool results
### Provider health and latency

Provider retry, latency, and attribution data are in worker `report.json`
`provider_telemetry` fields. Missing telemetry is `unknown`, not evidence of
normal provider health. Provider switching is out of scope and tracked in
`TODO.md`.

### Nonzero tool results

- `eval-manager/task-intsum`, turn `9`, tool `edit`: Could not find edits[2] in /Users/josh/d/laputa-systems/xsh-factory/runs/run-1786260649611/phases/01-eval/workers/eval-manager/task-intsum/REPORT.md. The oldText must match exactly including all whitespace and newlines.
  - Structured report: `workers/eval-manager/task-intsum/report.json`
- `eval-manager/task-intsum`, turn `12`, tool `edit`: Could not find edits[1] in /Users/josh/d/laputa-systems/xsh-factory/runs/run-1786260649611/phases/01-eval/workers/eval-manager/task-intsum/REPORT.md. The oldText must match exactly including all whitespace and newlines.
  - Structured report: `workers/eval-manager/task-intsum/report.json`
- `eval-worker/task-intsum-1`, turn `11`, tool `bash`: ok
sh: syntax error: bad substitution


Command exited with code 2
  - Structured report: `workers/eval-worker/task-intsum-1/report.json`


### Cycle total

- Workers: `2`
- Assistant turns: `42`
- Bucket tokens: `620031`
- Cost (USD): `0.017036`
- Nonzero tool results: `3`
- Budget failures or unknown costs: `0`


## Employee decisions

### eval-manager/task-intsum

- Role: `eval-manager`
- Result: `pass`
- Report: `workers/eval-manager/task-intsum/REPORT.md`

#### Efficiency and evidence

Trial 1 (`task-intsum-1`):
- assistant turns: 24
- tool calls: 29
- tool results: 29
- tool errors: 1
- user messages: 1
- thinking blocks: 17
- agent wall time: 91804 ms; session span: 90665 ms
- worker friction: one failed bash probe at turn 11 (see Tool-error findings)

Session stop reasons: 23 toolUse, 1 stop. Tool mix: 21 bash, 5 read, 2 edit,
1 write. This is a short, focused task; the effort is in line with a
single-draft typed-argv implementation, and 24 turns is not excessive.

Provider telemetry present: retry_count 0, retry_failures 0, provider_errors
[], response_elapsed_ms 0. No external-health confounders; not an agent
efficiency concern.

#### Handbook or proposal decision

Unchanged. The approved handbook already covers typed parsing, postfix `?`,
`var` accumulation, and exact output. The worker passed without discovering a
reusable lesson missing from the handbook. The candidate file
(`lineage/handbook-candidate.md`) was copied unchanged from the approved
snapshot; no provisional candidate was staged.

#### Ticket or product decision

Zero. No strong, reproducible, generalizable observation warrants a product
ticket this cycle.

#### Next action

A falsification/regression replay of `task-intsum` against the same handbook
lineage could confirm stability of the typed-argv idiom (mixed, empty, large,
negative, and malformed cases) and detect any drift in string-length or error
semantics. Since no handbook candidate or ticket was produced, the primary
next replay is a routine re-run of this eval on a future XSH commit to confirm
the typed-sum behavior remains correct.

#### North-star impact

This run is evidence that the handbook's typed-boundary ethos is learnable:
the agent produced a genuine typed argv-sum solution (typed parsing, `var`
accumulation, postfix `?` failure propagation, exact single-line output) with
no subprocess and no hard-coded answer. It advances ergonomics and
learnability by confirming the typed argument-vector idiom works as documented,
and the explicit failure boundary (malformed argument → nonzero exit, no
numeric stdout) is exercised correctly. The only error is a one-off shell
probe, not a product defect.



## Eval proposal review

No CTO eval review was recorded.

## Handbook lineage

Checked-in `runtime/handbook.md`: `c1295e0ad1caaf0387c18293b8be7c79ebf567afd45154d4850912f686783618`
- approved snapshot: `factory-source/handbook-approved.md` sha256 `c1295e0ad1caaf0387c18293b8be7c79ebf567afd45154d4850912f686783618` — matches checked-in handbook
- approved snapshot: `lineage/handbook-approved.md` sha256 `c1295e0ad1caaf0387c18293b8be7c79ebf567afd45154d4850912f686783618` — matches checked-in handbook
- candidate: `lineage/handbook-candidate.md` sha256 `c1295e0ad1caaf0387c18293b8be7c79ebf567afd45154d4850912f686783618` — matches checked-in handbook


## Historical handbook backlog

Historical candidates: 151; differing: 144; ledger-dispositioned: 144; unresolved: 0.
No unresolved candidate content is present.

## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
