# CTO briefing 04-eval-design

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
  - Turns: `49`; bucket tokens: `2177522`; thinking blocks: `45`
  - Tool errors: `0`; cost: `0.057914`; budget: `0.300000`


### Nonzero tool results

No nonzero Pi tool results were recorded.

### Cycle total

- Workers: `1`
- Assistant turns: `49`
- Bucket tokens: `2177522`
- Cost (USD): `0.057914`
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

A new eval proposal, `task-renamex`, staged under
`runs/run-1785797449435/phases/04-eval-design/proposals/proposal-1/` with the
complete task package:

- `EVAL.md` — contract, north-star hypothesis, agent boundary, oracle and
  evaluator, metrics, manager policy, and staged dry-run record (`Status:
  Draft.`).
- `runtime/task.md`, `runtime/artifact.md`, `runtime/review.md`.
- `executor.xsh`, `evaluate.xsh` — thin selectors updated to the `task-renamex`
  id.
- `evaluator.xsh` — package-owned, self-contained evaluator (no shared-module
  branch).
- `dry-run/` — reference solution, passing `run.json`, negative-control
  record, and `DRY-RUN.md`.

The scaffold was renamed from the retired `task-tags` id to the new valid
`task-renamex` id (no collision under `evals/`) and its status moved from
`Disabled.` to `Draft.` before any API query or dry run.

#### Ticket or product decision

not reported

#### Next action

Promotion target: `evals/task-renamex/` (the CTO grafts the staged package
there and immediately reviews it; per FACTORY.md the package is promoted and
set to `Approved.` only when the evaluator and this evidence pass).

Evidence for the CTO decision:
- `proposals/proposal-1/EVAL.md` (contract, oracle, cases, policy).
- `proposals/proposal-1/evaluator.xsh` (self-contained evaluator, `xsht check`
  clean).
- `proposals/proposal-1/dry-run/run.json` — passing manifest,
  `classification: pass`, all six cases exact.
- `proposals/proposal-1/dry-run/controls.md` — the four negative controls
  rejected with the intended classifications.
- `proposals/proposal-1/dry-run/DRY-RUN.md` — what was and was not exercised.
- `proposals/proposal-1/dry-run/renamex.xsh` — the reference solution.

The proposal remains `Draft.`; the CTO review gate decides whether it becomes
`Approved.` or stays `Draft.`.

#### North-star impact

XSH's mission is to make host work visible as typed APIs and reject shell
sludge. Every existing eval reads or writes one thing; none exercises the
filesystem *mutation* boundary (`fs.rename`). `task-renamex` probes whether an
agent can discover the recursive `fs.files` stream, filter by a Str suffix,
build a destination path with `fp` interpolation, and perform a rename with an
explicit overwrite policy — the classic housekeeping shape "rename every
`*.tmp` to `*.bak`" without a `find | mv` subprocess escape. A successful run
teaches whether the filesystem write surface is discoverable and whether the
path-cast guidance transfers to a mutation workflow. The design resists
task-specific hacks because hidden cases vary file placement (flat, nested,
dot-names, none) and because four distinct negative controls each fail a
different gate.



## Eval proposal review

`CTO-EVAL-REVIEW.md`

# CTO eval review

## Eval

`task-renamex`

## Result

`accepted`

## Evidence

The designer report, materialized package, evaluator syntax check, required reads, and deterministic audit passed.

- Proposal: `runs/run-1785797449435/phases/04-eval-design/proposals/proposal-1`

## Promotion

`promoted` at `evals/task-renamex`.

## Package state

`complete`

Missing package files: `None.`.

Checked-in status: `Approved.`.

Promotion records the proposal for Git review. The CTO may set `Approved.`
after the evaluator and evidence pass; promotion alone does not admit a
package to a paid cycle.



## Handbook lineage

No handbook lineage snapshots were recorded for this run. Checked-in handbook: `97c5d804c42c7742c9edfea4480163828d864279391d391df77aa60ee4a40e83`.

## Historical handbook backlog

Historical candidates: 29; differing: 26; ledger-dispositioned: 26; unresolved: 0.
No unresolved candidate content is present.

## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
