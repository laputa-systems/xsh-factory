# Eval-designer report — proposal-1

## Result

ready-for-review

## Proposal

Proposed eval: **`task-safepath`** — a practical systems-administration /
init-and-supervisor-glue task. Given an absolute root and a relative path, an
agent writes `safepath.xsh` that normalizes `.`/`..`/empty segments, joins the
result under root, prints the normalized absolute path, or prints exactly
`escape: <relative>` and exits nonzero when the path would escape the root.

Staged package (self-contained; no edits to any approved controller or eval):
- `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785809029885/phases/04-eval-design/proposals/proposal-1/EVAL.md` (Draft.)
- `runtime/task.md`, `runtime/artifact.md` (`safepath.xsh`)
- `executor.xsh` (thin `task-safepath` selector into the shared `eval-executor.xsh`)
- `evaluate.xsh` -> package-owned `evaluator.xsh` (full oracle/cases/run.json;
  deliberately does **not** delegate to `evaluate_common.xsh` / `evaluate_legacy.xsh`)
- `dryrun/` evidence (pass manifest, candidate-failed manifest, reference
  candidate, oracle, README)

Eval id `task-safepath` is not present under `evals/`, so promotion cannot
collide with the retired `task-tags`. The scaffold was renamed from
`task-tags` to `task-safepath` and `Disabled.` changed to `Draft.` before any
dry run.

## Dry run

Executed the materialized package exactly as the executor does the evaluator
boundary: `docker run --read-only xsh-factory-base:latest xsh /run/evaluate.xsh`
with `/work` read-only (reference candidate + task.md + handbook + review.md)
and `/session` + `/export` read-write.

Pass scenario: 1 public + 7 hidden cases all matched the external `sh` oracle
byte-for-byte and exit-for-exit; `run.json` reported `result: pass`,
`classification: pass`, with per-case correctness, timings, and input/output
sha256; review-heading and no-subprocess checks passed.

Fail-closed controls (all exit nonzero with the expected classification):
hard-coded candidate -> `candidate_failed`; forbidden-subprocess candidate ->
`restriction_failed`; missing artifact -> `worker_missing_artifact`; missing
review headings -> `protocol_failed`.

What remains unproven: a real Pi agent trial (no model/network spend in this
designer dry run), and the host-side `eval-executor.xsh` worker->evaluator
handoff under the CTO's admission gate. The evaluator's isolation, oracle,
manifest, and report are proven.

## North-star impact

Capability hypothesis: a well-formed XSH handbook should let an agent turn a
real path-traversal guard into a short, typed transformation (split; ignore
`""`/`.`; drop the most recent segment on `..`; `abort` nonzero on escape)
while keeping stdout a strict output contract. No existing eval covers building
a safe path from a dynamic relative string behind a typed-Path /
deliberate-failure boundary. A successful run is evidence about ergonomics and
learnability of segment-wise string work and explicit failure; a common miss
(pop the wrong segment, print-then-exit-nonzero, or treat `..` as text) is a
learnability/ergonomics signal, not a leaderboard obstacle. The root argument
plus hidden normalize/escape cases resist hard-coding. This is disjoint work
that broadens the eval portfolio's systems-glue coverage without exceeding the
ecount difficulty ceiling.

## Known risks

- **Task-specific hack:** a fixed-workspace-relative path or a per-case branch
  could satisfy the public case; hidden cases (mid-path and deep `..`, absolute
  relative, empty, `//`) and the byte-exact + exit-code oracle make a
  hard-coded solution fail as `candidate_failed` (proven by the negative
  control).
- **Oracle/output ambiguity:** `/`-only root, trailing slashes, and repeated
  separators are the main ambiguity surface; the contract pins them (root is
  absolute without trailing slash, never `/`; empty and `.` segments ignored;
  no trailing slash in output). Both candidate and oracle implement the same
  lexical rules so they agree.
- **Timing:** no strict candidate/oracle wall gate; timings are recorded
  diagnostically. Ratios are stable in the dry run but a live envelope is not
  yet established.
- **Missing checks:** a full Pi session and the host-side executor handoff are
  the unproven pieces; the evaluator itself is validated.
- **Deliberate failure idiom:** relies on `abort` (a genuine XSH primitive used
  across the executor) rather than a generic `Error(...)` constructor, matching
  the current handbook's guidance; this is a stated part of the hypothesis, not
  a hidden dependency.

## Review path

Promoted eval path (CTO decision, not performed here):
`.../proposals/proposal-1/` -> `evals/task-safepath/` (EVAL.md `Draft.`,
runtime task/artifact, executor.xsh, evaluate.xsh, evaluator.xsh), admitted to
paid work only after the evaluator passes and the CTO sets `Approved.`.

Evidence for the approval decision: `proposal-1/dryrun/run.pass.json` (all
cases exact, review + restriction pass), `run.candidate-failed.json` (negative
control fail-closes to `candidate_failed`), `reference-candidate.xsh`
(lint-clean reference), `oracle.sh` (independent external oracle), and
`dryrun/README.md` (pass + four failure controls). All package files pass
`xsht check`. The CTO reviews the package and may promote it (kept `Draft.` if
not accepted); a live agent replay then confirms the worker->evaluator handoff.
