# CTO briefing 02-eval-design

This is the deterministic first-pass briefing for the CTO. The structured
`report.json` files and raw Pi sessions remain the source of truth.

## Result

fail
## Result

fail

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
  - Turns: `22`; bucket tokens: `700091`; thinking blocks: `18`
  - Provider telemetry: `present=true; retries=0; retry_delay_ms=0; retry_successes=0; retry_failures=0; provider_errors=unknown; event_turns=22; observed_output_tps=0`
  - Tool errors: `0`; cost: `0.019986`; budget: `0.300000`


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
- Assistant turns: `22`
- Bucket tokens: `700091`
- Cost (USD): `0.019986`
- Nonzero tool results: `0`
- Budget failures or unknown costs: `0`


## Employee decisions

### eval-designer/proposal-1

- Role: `eval-designer`
- Result: `ready-for-review`
- Report: `workers/eval-designer/proposal-1/REPORT.md`

#### Efficiency and evidence

not reported

#### Handbook or proposal decision

A new eval `task-usagerep` (aggregate per-service usage across a tree of
measurement files) was materialized under the controller-staged package:

- `phases/02-eval-design/proposals/proposal-1/EVAL.md` — full contract; `Status`
  set to `Draft.`; includes the required `## Difficulty justification`.
- `phases/02-eval-design/proposals/proposal-1/runtime/task.md` — agent-facing
  task text.
- `phases/02-eval-design/proposals/proposal-1/runtime/artifact.md` — artifact
  name `usagerep.xsh`.
- `phases/02-eval-design/proposals/proposal-1/executor.xsh` — thin
  `task-usagerep` selector for the shared eval executor.
- `phases/02-eval-design/proposals/proposal-1/evaluator.xsh` — package-owned
  evaluator (stages a fixture tree per case, runs the candidate as
  `xsh /work/usagerep.xsh <root>`, compares byte-for-byte with an independent
  printf / `sh -c 'exit 1'` oracle, checks `read_text`/`fs.files`/`fs.walk`
  source references and the no-subprocess boundary, writes `run.json`).
- `phases/02-eval-design/proposals/proposal-1/evaluate.xsh` — unchanged generic
  shared-evaluator selector.
- `phases/02-eval-design/proposals/proposal-1/dry-run/DRY-RUN.md` — saved
  reference-check evidence.

The task combines recursive multi-file discovery + content parsing (a richer
transformation than `task-ecount`, which never reads a file body), a stateful
Map fold with two independent accumulators (SUM and COUNT per service), and
composite ranking (SUM desc, then SERVICE asc byte order). It includes a
meaningful failure control (any malformed line forces nonzero exit with empty
stdout) and ten hidden cases (multi-file spread, SUM ties, byte-order traps,
blank/whitespace lines, empty tree, empty file mixed in, spaces in names, and
two malformed-line failures) that defeat a hard-coded answer; the source checks
block a subprocess or literal-output escape.

#### Ticket or product decision

not reported

#### Next action

Promote to `evals/task-usagerep/` (with `EVAL.md` left as `Draft.` per the
factory contract; the CTO sets `Approved.` only after the evaluator and
evidence pass). Evidence for the CTO decision: the complete package with the
`## Difficulty justification` section, the package-owned `evaluator.xsh`,
the saved `dry-run/DRY-RUN.md` showing all package scripts pass `xsht check`,
and the explicitly named unproven surface (live container trial). Until that
trial passes, the eval is not admitted to paid work.

#### North-star impact

Hypothesis: an agent that has read the handbook can turn "read every `*.usage`
file under a root, sum units and count lines per distinct service, and print a
ranked `SERVICE SUM COUNT` report" into a typed XSH program using recursive
filesystem streams, `read_text`, integer parsing, a two-accumulator Map fold,
and composite `sort-by`, without falling back to subprocesses. This is the
XSH analogue of the metering/summary glue (`cat *.usage | awk ...`) that UNIX
solves with sludge; a pass would show the factory that multi-file discovery and
two-field stateful aggregation compose from the handbook, while a miss names
which idiom (Map accumulation, tie-break sorting, or content reads) needs
clearer handbook guidance. It honors the explicit-boundary and composability
ethos by keeping the whole pipeline in typed XSH values and requiring a loud
nonzero failure on malformed input.



## Eval proposal review

`CTO-EVAL-REVIEW.md`

# CTO eval review

## Eval

`task-usagerep`

## Result

`rejected`

## Evidence

The package was preserved for inspection, but one or more CTO review gates did not pass.

- Proposal: `runs/run-1785893827191/phases/02-eval-design/proposals/proposal-1`

## Promotion

`promoted` at `evals/task-usagerep`.

## Package state

`incomplete`

Missing package files: `evaluator.xsh (package-owned evaluator)`.

Checked-in status: `Draft.`.

Promotion records the proposal for Git review. The CTO may set `Approved.`
after the evaluator and evidence pass; promotion alone does not admit a
package to a paid cycle.



## Handbook lineage

No handbook lineage snapshots were recorded for this run. Checked-in handbook: `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b`.

## Historical handbook backlog

Historical candidates: 65; differing: 65; ledger-dispositioned: 65; unresolved: 0.
No unresolved candidate content is present.

## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
