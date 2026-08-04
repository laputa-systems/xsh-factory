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
  - Turns: `49`; bucket tokens: `2516057`; thinking blocks: `35`
  - Tool errors: `0`; cost: `0.060548`; budget: `0.300000`


### Nonzero tool results

No nonzero Pi tool results were recorded.

### Cycle total

- Workers: `1`
- Assistant turns: `49`
- Bucket tokens: `2516057`
- Cost (USD): `0.060548`
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

New eval **task-groupsum** (per-key numeric aggregation / grouped sum), staged
as a `Draft.` proposal under:

`runs/run-1785826088406/phases/04-eval-design/proposals/proposal-1/`

- `EVAL.md` — full contract (status `Draft.`, id `task-groupsum`, purpose,
  north-star hypothesis, task, agent boundary, oracle/evaluator, metrics,
  manager policy). No remaining `task-tags` identifier; the retired seed name
  is fully replaced.
- `runtime/task.md` — the user-facing task prompt (accept one file path,
  print sorted `KEY SUM` rows, fail closed on malformed lines/unreadable file).
- `runtime/artifact.md` — `groupsum.xsh`.
- `executor.xsh` — thin selector calling the shared `eval-executor.xsh` for
  `task-groupsum`.
- `evaluate.xsh` — generic selector unchanged (shared evaluator protocol).
- `evaluator.xsh` — package-owned self-contained evaluator: writes hidden
  fixtures, runs `xsh /work/groupsum.xsh <file>` per case, compares byte-for-byte
  against an independent `printf` / `sh -c 'exit 1'` oracle, enforces the
  `read_text` and no-subprocess restrictions, validates `review.md` headings,
  and writes `run.json`. Uses `GROUPSUM_WORK/SESSION/EXPORT` overrides so it can
  be validated on a host without root `/work`.
- `dry-run/` — preserved evidence (see below).

The scaffold was created by renaming the `task-tags` reference, setting
`Draft.`, then making only task-specific edits to the task/artifact/executor/
evaluator files. No custom runner, helper language, or controller was added.

#### Ticket or product decision

not reported

#### Next action

Package (Draft.) is staged for CTO promotion into `evals/task-groupsum/` with
`EVAL.md`, `executor.xsh`, `evaluator.xsh`, `evaluate.xsh`, and
`runtime/{task.md,artifact.md}`. Evidence for the approval decision:
- `EVAL.md` and `runtime/task.md` define a well-posed, ecount-grade systems
  task distinct from the existing eval portfolio;
- `dry-run/pass/run.json` — every case byte-exact, restrictions + review
  protocol pass (result `pass`);
- `dry-run/pass/groupsum-ref.xsh` — `xsht check`/`lint` clean reference;
- `dry-run/fail/run.json` — wrong-sum candidate rejected as `candidate_failed`
  with a nonzero evaluator exit (fail-closed proven);
- `REPORT.md` (this file) — narrative, north-star impact, and risks.

The CTO review gate decides whether the promoted package becomes `Approved.`
or remains `Draft.`.

#### North-star impact

Capability hypothesis: an agent that has internalized the XSH handbook should
resolve a classic sysadmin aggregation — "sum the second field per first field,
print sorted `KEY SUM` rows" — with a short typed program that reads through fs
text APIs, splits a line into fields, validates an integer with `parse_int`,
accumulates into an immutable-update `Map` (`sums = sums.set(k, sums.get(k,0)+v)`),
sorts keys, and formats rows. This is practical systems glue (bytes per user,
totals per endpoint, usage per account) and exercises a capability no approved
eval covers: building an arbitrary-key Map of accumulated numbers and emitting a
sorted keyed summary (existing evals only count a fixed field, single-record
lookup, or sort plain lines). A pass is evidence about learnability and
ergonomics of the Map + integer-parse + keyed-sort trio; a miss isolates which
of those idioms is still unclear for handbook guidance. The design resists
task-specific hacks: every hidden fixture has different keys, accumulation
shape, and byte-order traps, and malformed/unreadable input must fail with a
clean nonzero exit and no stdout, so a hard-coded summary or a
throwing-in-the-towel candidate cannot pass.



## Eval proposal review

`CTO-EVAL-REVIEW.md`

# CTO eval review

## Eval

`task-groupsum`

## Result

`accepted`

## Evidence

The designer report, materialized package, evaluator syntax check, required reads, and deterministic audit passed.

- Proposal: `runs/run-1785826088406/phases/04-eval-design/proposals/proposal-1`

## Promotion

`promoted` at `evals/task-groupsum`.

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

Historical candidates: 47; differing: 34; ledger-dispositioned: 34; unresolved: 0.
No unresolved candidate content is present.

## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
