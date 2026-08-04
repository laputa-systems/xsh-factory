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
  - Turns: `61`; bucket tokens: `2705709`; thinking blocks: `47`
  - Tool errors: `6`; cost: `0.073036`; budget: `0.300000`


### Nonzero tool results

- `eval-designer/proposal-1`, turn `12`, tool `bash`: /bin/bash: line 0: cd: /Users/josh/d/xsh: No such file or directory


Command exited with code 1
  - Structured report: `workers/eval-designer/proposal-1/report.json`
- `eval-designer/proposal-1`, turn `12`, tool `bash`: /bin/bash: line 0: cd: /Users/josh/d/xsh: No such file or directory


Command exited with code 1
  - Structured report: `workers/eval-designer/proposal-1/report.json`
- `eval-designer/proposal-1`, turn `28`, tool `bash`: sed: 1: "count.xsh
": command c expects \ followed by text
== check ==

err[check.type-mismatch]: type mismatch
  count.xsh:11:43
      let line_text = row.count.to_text() + "\t" + row.line
                                            ^^^^ expected Int, found Str

err[check.type-mismatch]: type mismatch
  count.xsh:11:50
      let line_text = row.count.to_text() + "\t" + row.line
                                                   ^^^^^^^^ expected Int, found Str
== run ==
err[runtime.error]: to_text
  count.xsh:11:21
      let line_text = row.count.to_text() + "\t" + row.line
                      ^^^^^^^^^^^^^^^^^
runtime traceback
executable: /Users/josh/usr/bin/xsh
operation: runtime.error
error: missing-field: to_text


Command exited with code 3
  - Structured report: `workers/eval-designer/proposal-1/report.json`
- `eval-designer/proposal-1`, turn `30`, tool `bash`: == case: ties + blank + missing final newline ==
--- oracle ---
2	alpha
2	beta
1	gamma
--- xsh ---
2	beta
2	alpha
1	gamma
--- diff (empty=same) ---
1d0
< 2	alpha
2a2
> 2	alpha
== case: trailing spaces & leading spaces & single space line ==
--- oracle ---
3	x
1	
1	x
--- xsh ---
3	 x
1	x
1	 
--- diff ---
1,2c1
< 3	x
< 1	
---
> 3	 x
3a3
> 1	 


Command exited with code 1
  - Structured report: `workers/eval-designer/proposal-1/report.json`
- `eval-designer/proposal-1`, turn `31`, tool `bash`: --- run (asc first then desc) ---
err[runtime.error]: join expected List[Str]
  desctest.xsh:6:9
    print $xs.join(",")
          ^^^^^^^^^^^^^
runtime traceback
executable: /Users/josh/usr/bin/xsh
operation: runtime.error
error: type-error: join expected List[Str]
--- desc only ---
err[runtime.error]: join expected List[Str]
  desctest2.xsh:5:9
    print $xs.join(",")
          ^^^^^^^^^^^^^
runtime traceback
executable: /Users/josh/usr/bin/xsh
operation: runtime.error
error: type-error: join expected List[Str]


Command exited with code 3
  - Structured report: `workers/eval-designer/proposal-1/report.json`
- `eval-designer/proposal-1`, turn `36`, tool `bash`: == trailing blank line ==
STDOUT SAME
== two trailing blanks + last no-newline ==
STDOUT SAME
== blank between ==
STDOUT SAME
== with newline at very end ==
cat: illegal option -- A
usage: cat [-belnstuv] [file ...]
== candidate ==
cat: illegal option -- A
usage: cat [-belnstuv] [file ...]


Command exited with code 1
  - Structured report: `workers/eval-designer/proposal-1/report.json`


### Cycle total

- Workers: `1`
- Assistant turns: `61`
- Bucket tokens: `2705709`
- Cost (USD): `0.073036`
- Nonzero tool results: `6`
- Budget failures or unknown costs: `0`


## Employee decisions

### eval-designer/proposal-1

- Role: `eval-designer`
- Result: `ready-for-review`
- Report: `workers/eval-designer/proposal-1/REPORT.md`

#### Efficiency and evidence

not reported

#### Handbook or proposal decision

New eval **`task-grep`** — a line-oriented literal text-search workflow that
replaces `grep -nF`'s glue with a typed XSH program. A correct run taught the
factory whether an agent can read a file, stream its lines, filter on a
byte-exact literal substring, number the hits from 1, and emit an exact
`N:text` contract without a subprocess.

Staged package (complete, `Draft.`):

- `runs/run-1785795835208/phases/02-eval-design/proposals/proposal-1/EVAL.md`
- `.../evaluator.xsh` (package-owned oracle + cases, writes session `run.json`)
- `.../executor.xsh` (thin selector, `task-grep` id)
- `.../evaluate.xsh` (generic shared-protocol selector, unchanged)
- `.../runtime/task.md`, `.../runtime/artifact.md`

The scaffold's `task-tags` title/ID were retired to `task-grep` and `Disabled.`
flipped to `Draft.` before any dry run; no `task-tags` reference remains in the
package. The proposed eval path for promotion is `evals/task-grep`.

#### Ticket or product decision

not reported

#### Next action

- Proposed promoted eval path: `evals/task-grep/` (EVAL.md, evaluate.xsh,
  evaluator.xsh, executor.xsh, runtime/{task,artifact}.md).
- Evidence for the CTO approval decision: the staged package under
  `.../proposals/proposal-1/` plus the dry-run manifests under
  `.../proposals/proposal-1/dry-run/` — `session-pass/run.json`
  (`pass`, 9/9 exact) and `session-bad/run.json` (`fail`, candidate_failed),
  which together prove the evaluator distinguishes a correct solution from a
  wrong one. All package `.xsh` files pass `xsht check`.
- The CTO may promote the package to `evals/task-grep` and set `Approved.`
  after confirming the container routing; until then it remains `Draft.` and
  is not admitted to paid work.

#### North-star impact

Capability hypothesis: XSH's explicit line-stream boundaries — `read_text`,
`text.lines`, `enumerate`, `where`/`contains` — should let an agent compose a
correct, clear search-and-report tool with little exploratory friction,
turning the classic `grep -n` shape into a small typed program. A successful
paid run would strengthen the claim that XSH's text-glue ergonomics and
explicit boundaries (instead of grep's implicit regex/line contract) are
learnable and AI-efficient; it reads a file, which distinctively crosses a
text-file boundary absent from the argv-level `task-tags` and complements the
field-extraction `task-col2`, set-difference `task-setdiff`, and
numeric-aggregation `task-total`.

The design resists task-specific hacks by requiring byte-exact `N:text`
output across hidden empty-pattern, case, regex-meta-literal, whitespace, and
unicode inputs, plus a no-match empty-output case and a missing-file failure
contract, all under a no-subprocess boundary — so a hard-coded answer, a
recognition-only solution, or a shell-out would be fragile and fail the
oracle.



## Eval proposal review

`CTO-EVAL-REVIEW.md`

# CTO eval review

## Eval

`task-grep`

## Result

`accepted`

## Evidence

The designer report, materialized package, evaluator syntax check, required reads, and deterministic audit passed.

- Proposal: `runs/run-1785795835208/phases/02-eval-design/proposals/proposal-1`

## Promotion

`promoted` at `evals/task-grep`.

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

Historical candidates: 29; differing: 26; ledger-dispositioned: 25; unresolved: 1.
Unresolved candidates requiring one explicit CTO decision:
- `runs/run-1785795835208/phases/01-eval/lineage/handbook-candidate.md` sha256 `d9a2e262a449a28552b523f7a0d34c3542e7932f6c60a0761de28798229e8d35`


## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
