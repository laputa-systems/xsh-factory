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
  - Turns: `32`; bucket tokens: `1312147`; thinking blocks: `28`
  - Tool errors: `0`; cost: `0.032844`; budget: `0.300000`


### Nonzero tool results

No nonzero Pi tool results were recorded.

### Cycle total

- Workers: `1`
- Assistant turns: `32`
- Bucket tokens: `1312147`
- Cost (USD): `0.032844`
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

- Proposal package: `runs/run-1785873121313/phases/04-eval-design/proposals/proposal-1/`
  - `EVAL.md` — contract, `## Status` = `Draft.`, task `task-intsum`
  - `runtime/task.md` — worker instructions
  - `runtime/artifact.md` — `intsum.xsh`
  - `executor.xsh` — thin `task-intsum` selector into the shared eval-executor
  - `evaluator.xsh` — self-contained evaluator for `task-intsum`
  - `evaluate.xsh` — generic selector (shared dispatch, unchanged)
- Dry-run evidence: `proposals/proposal-1/dryrun/` (`DRYRUN.md`, candidate, oracle)
- No approved eval was edited; the existing `task-tags` seed is preserved.

Selected task: `task-intsum` — sum integer command-line arguments with a typed
loop and fail loudly (nonzero) on any non-integer argument. It is a small,
distinct, practical programming/glue capability (no existing eval is an
argv-arithmetic task), no harder than ecount.

#### Ticket or product decision

not reported

#### Next action

- Promoted eval path after CTO decision: `evals/task-intsum` (copy of this
  proposal package; status stays `Draft.` until the CTO accepts a passing
  evaluator and sets `Approved.`).
- Evidence for the CTO approval decision: `EVAL.md` (contract, `Draft.`,
  oracle/hidden-cases/agent-boundary/metrics/manager-policy), `runtime/task.md`,
  `runtime/artifact.md` (`intsum.xsh`), `executor.xsh`/`evaluator.xsh` passing
  `xsht check`, and `dryrun/` showing candidate + oracle byte-for-byte agreement
  on all six cases including the malformed expect-fail.
- The controller's eval-design gate decides `Draft.` vs `Approved.`; this
  proposal does not self-approve.

#### North-star impact

Capability hypothesis: an agent that has internalized the handbook's typed
command-line glue should turn an argument vector into a typed integer list,
propagate an expected parsing failure with postfix `?`, accumulate in a `var`,
and print an exact single line — with no subprocess and no silent coercion.
The malformed case is the key discriminator: it rewards explicit, typed failure
(clear nonzero exit) over a shell-like `0`/quirk, which is exactly the
XSH-explicit-boundary ethos in `NORTH-STAR.md`. A clean pass is evidence about
learnability and ergonomics of typed argv + `Result` propagation; a malformed
case miss points at a product or handbook gap in typed failure, which is
generalizable rather than task-specific.



## Eval proposal review

`CTO-EVAL-REVIEW.md`

# CTO eval review

## Eval

`task-intsum`

## Result

`accepted`

## Evidence

The designer report, materialized package, evaluator syntax check, required reads, and deterministic audit passed.

- Proposal: `runs/run-1785873121313/phases/04-eval-design/proposals/proposal-1`

## Promotion

`promoted` at `evals/task-intsum`.

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

Historical candidates: 57; differing: 37; ledger-dispositioned: 37; unresolved: 0.
No unresolved candidate content is present.

## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
