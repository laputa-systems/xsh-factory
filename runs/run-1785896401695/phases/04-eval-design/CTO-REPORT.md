# CTO briefing 04-eval-design

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

- Mode: `eval-design`
- Request: `CYCLE-REQUEST.md`
- Structured report: `report.json`

## Phase outcomes

- `report.json`: result `pass`; report `report.json`
- `workers/eval-designer/proposal-1/report.json`: result `pass`; report `workers/eval-designer/proposal-1/report.json`


## Employee accounting

### Worker metrics

- `eval-designer/proposal-1` (`eval-designer`): result `pass`; report `workers/eval-designer/proposal-1/report.json`
  - Execution: `not recorded`; classification: `not recorded`
  - Turns: `48`; bucket tokens: `2118075`; thinking blocks: `40`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=48; observed_output_tps=0`
  - Tool errors: `2`; cost: `0.048722`; budget: `0.300000`


### Nonzero tool results
### Provider health and latency

Provider retry, latency, and attribution data are in worker `report.json`
`provider_telemetry` fields. Missing telemetry is `unknown`, not evidence of
normal provider health. Provider switching is out of scope and tracked in
`TODO.md`.

### Nonzero tool results

- `eval-designer/proposal-1`, turn `22`, tool `bash`: PASS public :: north 20
south 15
east 4
PASS hidden_multiproduct :: north 48
south 15
FAIL hidden_tie rc=0/0
  c='gamma 10
beta 10
alpha 10'
  o='alpha 10
beta 10
gamma 10'
PASS hidden_negative :: north 12
south -15
FAIL hidden_order rc=0/0
  c='zebra 9
apple 9'
  o='apple 9
zebra 9'
PASS hidden_many :: r2 29
r3 16
r1 10
PASS hidden_empty :: 


Command exited with code 3
  - Structured report: `workers/eval-designer/proposal-1/report.json`
- `eval-designer/proposal-1`, turn `29`, tool `edit`: Could not find the exact text in /Users/josh/d/laputa-systems/xsh-factory/runs/run-1785896401695/phases/04-eval-design/proposals/proposal-1/EVAL.md. The old text must match exactly including all whitespace and newlines.
  - Structured report: `workers/eval-designer/proposal-1/report.json`


### Cycle total

- Workers: `1`
- Assistant turns: `48`
- Bucket tokens: `2118075`
- Cost (USD): `0.048722`
- Nonzero tool results: `2`
- Budget failures or unknown costs: `0`


## Employee decisions

### eval-designer/proposal-1

- Role: `eval-designer`
- Result: `ready-for-review`
- Report: `workers/eval-designer/proposal-1/REPORT.md`

#### Efficiency and evidence

not reported

#### Handbook or proposal decision

A new draft eval `task-revrank` was designed and staged under
`runs/run-1785896401695/phases/04-eval-design/proposals/proposal-1/`. The task
replaces the scaffolded `task-bigfiles` title and ID, and its status is
`Draft.`

Scaffolding:

- `EVAL.md` — contract, artifact, oracle, hidden cases, agent boundary,
  metrics, manager policy, difficulty justification;
- `runtime/task.md` — the worker-facing task instructions;
- `runtime/artifact.md` — artifact name `revrank.xsh`;
- `executor.xsh` — thin selector dispatching the shared eval-executor for
  `task-revrank`;
- `evaluator.xsh` — package-owned evaluator (fixture, oracle, correctness,
  restriction, protocol checks, `run.json` manifest);
- `evaluate.xsh` — unchanged generic package selector;
- `dry-run/` — `DRY-RUN.md`, `reference/revrank.xsh`,
  `oracle/revrank-oracle.sh`, and `evidence/transcript.txt`.

The task: read a single-space four-field table (`REGION PRODUCT UNITS PRICE`),
derive per-row revenue `UNITS * PRICE`, accumulate it per region into an XSH
`Map[Int]`, and print `REGION TOTAL` rows ranked by total descending with an
ascending byte-order tie-break. Failure controls: a malformed row (wrong field
count or non-integer units/price) or an unreadable file must exit nonzero and
print nothing.

#### Ticket or product decision

not reported

#### Next action

Promoted eval path would be `evals/task-revrank/` (package-owned
`evaluator.xsh`). Evidence for the CTO approval decision:

- `proposals/proposal-1/EVAL.md` with the `## Difficulty justification` naming
  the per-row arithmetic projection, the keyed Map aggregation, and the numeric
  ranking as three independent operations, plus the explicit failure control
  and the hidden cases that defeat one-liners / hard-coded answers.
- `proposals/proposal-1/dry-run/DRY-RUN.md` and
  `dry-run/evidence/transcript.txt` showing the reference byte-matching the
  oracle on all passing cases and both exiting nonzero with empty stdout on all
  three failure controls.
- `xsht check` passing for `executor.xsh`, `evaluator.xsh`, `evaluate.xsh`, and
  the reference `revrank.xsh`.

The package remains `Draft.` pending the CTO review gate.

#### North-star impact

Probes whether an agent can compose three genuinely independent XSH operations
into one practical report: a per-row arithmetic projection (parsing two typed
integer columns and multiplying), a keyed stateful aggregation into a Map, and
a numeric descending rank with a deterministic ascending tie-break. This is the
canonical "leaderboard / spend / usage per region" glue shape
(`awk '{s[$1]+=$3*$4} END{...}' | sort -rn`) that no approved eval covers. A
clean pass would teach that per-row derived arithmetic plus Map accumulation
plus the two-pass stable descending sort is discoverable from the handbook; a
miss would localize which of those idioms (typed parsing, Map immutable update,
or compound ordering) is still unclear, giving the manager a concrete,
generalizable handbook or product signal rather than a task-specific workaround.



## Eval proposal review

`CTO-EVAL-REVIEW.md`

# CTO eval review

## Eval

`task-revrank`

## Result

`accepted`

## Evidence

The designer report, materialized package, evaluator syntax check, required reads, and deterministic audit passed.

- Proposal: `runs/run-1785896401695/phases/04-eval-design/proposals/proposal-1`

## Promotion

`promoted` at `evals/task-revrank`.

## Package state

`complete`

Missing package files: `None.`.

Checked-in status: `Approved.`.

Promotion records the proposal for Git review. The CTO may set `Approved.`
after the evaluator and evidence pass; promotion alone does not admit a
package to a paid cycle.



## Handbook lineage

No handbook lineage snapshots were recorded for this run. Checked-in handbook: `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b`.

## Historical handbook backlog

Historical candidates: 68; differing: 67; ledger-dispositioned: 67; unresolved: 0.
No unresolved candidate content is present.

## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
