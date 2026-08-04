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
  - Turns: `54`; bucket tokens: `2055524`; thinking blocks: `37`
  - Tool errors: `2`; cost: `0.056464`; budget: `0.300000`


### Nonzero tool results

- `eval-designer/proposal-1`, turn `14`, tool `bash`: === find oracle ===
permlist-test/root/a.txt
permlist-test/root/sub/c
=== xsh candidate ===
err[parse.expected-terminator]: expected statement terminator
  perm.xsh:8:16
      |> sort_by { |a| a }
                 ^ expected statement terminator

err[parse.expected-record-field]: expected record field
  perm.xsh:8:18
      |> sort_by { |a| a }
                   ^ expected record field

err[parse.expected-token]: expected `}` after record
  perm.xsh:8:18
      |> sort_by { |a| a }
                   ^ expected `}` after record

err[parse.expected-terminator]: expected statement terminator
  perm.xsh:8:18
      |> sort_by { |a| a }
                   ^ expected statement terminator

err[parse.expected-expression]: expected expression
  perm.xsh:8:18
      |> sort_by { |a| a }
                   ^ expected expression

err[parse.expected-expression]: expected expression
  perm.xsh:9:5
      |> collect()
      ^^ expected expression


Command exited with code 2
  - Structured report: `workers/eval-designer/proposal-1/report.json`
- `eval-designer/proposal-1`, turn `38`, tool `bash`: === oracle ===
/t/.h1
/t/sub/.h2
/t/sub/r.sh
=== candidate hidden=true ===
err[parse.expected-token]: expected `)` after call arguments
  /test/candidate3.xsh:3:37
    let files = fs.files(root, hidden = true)?
                                      ^ expected `)` after call arguments

err[parse.expected-terminator]: expected statement terminator
  /test/candidate3.xsh:3:37
    let files = fs.files(root, hidden = true)?
                                      ^ expected statement terminator

err[parse.expected-expression]: expected expression
  /test/candidate3.xsh:3:37
    let files = fs.files(root, hidden = true)?
                                      ^ expected expression


Command exited with code 2
  - Structured report: `workers/eval-designer/proposal-1/report.json`


### Cycle total

- Workers: `1`
- Assistant turns: `54`
- Bucket tokens: `2055524`
- Cost (USD): `0.056464`
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

Staged proposal package (Draft., eval id `task-findexec`):
`runs/run-1785804030340/phases/04-eval-design/proposals/proposal-1/`

- `EVAL.md` — north-star hypothesis, task prompt, agent boundary, oracle and
  evaluator, metrics, manager policy, staged dry-run record.
- `runtime/task.md` — user-facing task contract and acceptance oracle.
- `runtime/artifact.md` — required artifact `findexec.xsh`.
- `executor.xsh` / `evaluator.xsh` — selectors rewritten from the `task-tags`
  scaffold to reference `task-findexec`; `evaluate.xsh` is the unchanged
  generic evaluator selector.
- `dryrun/` — materialized evidence for the CTO review.

The `task-tags` title/ID were replaced with `task-findexec` and `Disabled.`
with `Draft.` before any dry run. No `task-tags` or `Disabled.` reference
remains in the package.

#### Ticket or product decision

not reported

#### Next action

Promoted eval path on approval: `evals/task-findexec/` (new id, verified absent
under `evals/`). Evidence for the CTO decision: the staged package at
`runs/run-1785804030340/phases/04-eval-design/proposals/proposal-1/`, the
in-image byte-for-byte oracle matches in `dryrun/dryrun.log` (plus
`oracle*.txt`/`cand*.txt`), the passing `xsht check/fmt/lint` in the dev loop,
and this report. The CTO promotes the package and decides `Approved.` vs
`Draft.`; this proposal remains `Draft.` pending that review.

#### North-star impact

This eval probes XSH's typed metadata boundary — a capability no current eval
covers: fetching a tree with the fs stream API, trusting a typed permission
field (`owner_executable`) over a guessed name, and finding the `hidden: true`
option so the result matches the oracle's dotfile set. It is the XSH analogue
of the classic sysadmin "list executable files in a tree"
(`find -type f -perm -u+x | sort`). A successful run teaches whether the
handbook/API make filesystem metadata fields and stream options discoverable
and composable, and whether an agent avoids a subprocess fallback to `find`.
The owner/group/other distinction plus a hidden-file fixture raise the failure
bar above a trivial "is-executable" or hard-coded listing, so evidence points
at general ergonomics rather than a task trick.



## Eval proposal review

`CTO-EVAL-REVIEW.md`

# CTO eval review

## Eval

`task-findexec`

## Result

`accepted`

## Evidence

The designer report, materialized package, evaluator syntax check, required reads, and deterministic audit passed.

- Proposal: `runs/run-1785804030340/phases/04-eval-design/proposals/proposal-1`

## Promotion

`promoted` at `evals/task-findexec`.

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

Historical candidates: 33; differing: 27; ledger-dispositioned: 27; unresolved: 0.
No unresolved candidate content is present.

## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
