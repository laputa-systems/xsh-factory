# CTO briefing 02-eval-design

This is the deterministic first-pass briefing for the CTO. The structured
`report.json` files and raw Pi sessions remain the source of truth.

## Result

pass

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
  - Turns: `41`; bucket tokens: `1505721`; thinking blocks: `32`
  - Tool errors: `2`; cost: `0.038474`; budget: `0.300000`


### Nonzero tool results

- `eval-designer/proposal-1`, turn `29`, tool `edit`: Could not find edits[0] in /Users/josh/d/laputa-systems/xsh-factory/runs/run-1785781082105/phases/02-eval-design/proposals/proposal-1/EVAL.md. The oldText must match exactly including all whitespace and newlines.
  - Structured report: `workers/eval-designer/proposal-1/report.json`
- `eval-designer/proposal-1`, turn `31`, tool `edit`: Could not find the exact text in /Users/josh/d/laputa-systems/xsh-factory/runs/run-1785781082105/phases/02-eval-design/proposals/proposal-1/runtime/task.md. The old text must match exactly including all whitespace and newlines.
  - Structured report: `workers/eval-designer/proposal-1/report.json`


### Cycle total

- Workers: `1`
- Assistant turns: `41`
- Bucket tokens: `1505721`
- Cost (USD): `0.038474`
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

A new, small practical XSH eval proposal **`task-setdiff`** (no harder than
ecount) is staged and dry-run-proven under:

`runs/run-1785781082105/phases/02-eval-design/proposals/proposal-1/`

- `EVAL.md` — full contract: status `Draft.`, unique `task-setdiff` ID (not
  present under `evals/`), purpose, north-star hypothesis, task, agent
  boundary, oracle/evaluator, metrics, manager policy, staged dry run.
- `runtime/task.md`, `runtime/artifact.md` — user-facing prompt and
  `setdiff.xsh` artifact.
- `executor.xsh`, `evaluator.xsh`, `evaluate.xsh` — thin selectors, each
  passing `xsht check`, all wired to `task-setdiff`.
- `dry-run/` — reference solution, runner, and evidence (see below).

The task reads two line files, dedups each into a set (`set.from` /
`set.has`), emits the unique lines of `fileA` absent from `fileB` sorted in
byte order, and matches a portable `sort -u` + `comm -23` oracle. This is the
classic config-drift / package-reconcile shape and fills the portfolio gap for
the `set` module and set-difference logic (no approved eval covers it).

#### Ticket or product decision

not reported

#### Next action

Promote the staged package to **`evals/task-setdiff/`** (this path is free:
no `task-setdiff` exists under `evals/`). The CTO approves the eval from:

- `proposals/proposal-1/EVAL.md` (complete contract, status `Draft.`),
- `proposals/proposal-1/dry-run/DRY-RUN.md` and `cases.txt` (10/10 success +
  2/2 failure controls byte-exact),
- the reference `dry-run/setdiff-reference.xsh` proving solvability.

The proposal is intentionally left `Draft.`; the CTO sets `Approved.` only if
the first real containerized evaluator run returns a passing `run.json`, per
the factory's admit-after-review gate.

#### North-star impact

This probes whether the handbook makes the `set` module and line-stream edge
semantics discoverable and composable for real systems glue. Successful runs
teach the factory whether replacing `comm -23 <(sort -u A) <(sort -u B)` with
a typed `fs.read_text` → `Str.lines` → `set.from`/`set.has` → `sort-by`
pipeline is ergonomic for agents, and whether the Result/`?` lesson transfers
to a missing-input boundary. It resists task-specific hacks: hidden cases vary
membership, order, duplication, blank, and UTF-8 content, and the failure
controls require a loud nonzero exit — a hard-coded answer, a wrong dedup/sort,
or a subprocess escape each fail a distinct gate.



## Eval proposal review

`{relative_path(run_dir, review)}`

# CTO eval review

## Eval

`task-setdiff`

## Result

`accepted`

## Evidence

The designer report, materialized package, evaluator syntax check, required reads, and deterministic audit passed.

- Proposal: `runs/run-1785781082105/phases/02-eval-design/proposals/proposal-1`

## Promotion

`promoted` at `evals/task-setdiff`.

## Package state

`complete`

Missing package files: `None.`.

Checked-in status: `Approved.`.

Promotion records the proposal for Git review. The CTO may set `Approved.`
after the evaluator and evidence pass; promotion alone does not admit a
package to a paid cycle.


## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` (required; next CTO must
  validate or revert it before paid work)
