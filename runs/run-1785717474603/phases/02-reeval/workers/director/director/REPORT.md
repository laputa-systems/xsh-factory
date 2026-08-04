# Director report: task-ecount candidate re-evaluation (phase 02-reeval)

## Result

fail.

The phase re-evaluated the task-ecount-003 candidate fix (`c2e1039`,
branch `factory/task-ecount-003/1785687504767`) against the task-ecount eval
before merge. The controller completed exactly one fresh trial; the eval worker
session ended without writing `ecount.xsh`, so the evaluator classified the
trial `worker_missing_artifact` with no candidate output and all-zero timings.
The eval-manager reviewed the packet and recorded **needs-replay**: the trial
provides no runtime evidence about the candidate fix, so the fix is neither
accepted nor rejected. The ticket stays `Approved.` and the branch stays
pending top-level user review. The phase itself is a fail because the required
replay evidence was not produced.

## Cycle

- Mode: `eval` (post-merge-adjacent candidate re-evaluation; ticket remains
  unmerged)
- Selected eval: `task-ecount`
- Trial plan: 1 trial (controller-owned executor dispatch)
- New eval proposals: 0
- Approved tickets in scope: `task-ecount-003` (candidate, pre-merge)
- Controller plan: validate the task-ecount-003 implementation against the
  linked task-ecount eval before merge by running one trial against the
  candidate commit, then have the eval-manager classify the evidence and
  record a decision.
- Controller events confirm the plan executed: trial 1 started and completed
  as `failed`; the manager completed; the director was dispatched for
  post-run review. The `eval-designer` row is `not-requested` (record only,
  no child).
- XSH commits in evidence: phase `report.json` names master baseline
  `de9880ce`; the trial `run.json` and `xsh-build.state` name the candidate
  `c2e1039`, so the trial did run the candidate. The manager flagged this
  provenance difference as expected for a pre-merge run, not a conflict.

## Children

Dispatched children in eval mode are already-complete controller evidence; the
director launched no child and waited on none.

- `eval-worker` / `task-ecount-1` — result: **fail** (trial 1).
  Evidence: `runs/run-1785717474603/phases/02-reeval/workers/eval-worker/task-ecount-1/run.json`
  (`classification: worker_missing_artifact`, `correctness.fail`,
  `protocol.artifact_present: false`, all timings 0, `xsh_commit: c2e1039`).
  Session: `session.jsonl.bz2` (8 assistant turns, 13 tool calls, 1 tool error at
  turn 7 — unbounded background probe plus `python3` absent from the minimal
  Alpine image; transcript ends after a turn-8 tool result with no artifact).
  Worker report: `report.json` (`execution.artifact.state: missing`,
  `result: fail`).
- `eval-manager` / `task-ecount` — result: **fail.** (phase verdict),
  worker process completed. Evidence:
  `runs/run-1785717474603/phases/02-reeval/workers/eval-manager/task-ecount/REPORT.md`
  — verdict **needs-replay**, ticket stays `Approved.`, branch stays pending
  top-level review, handbook unchanged, zero tickets created, next-replay
  checks and falsification plan recorded. Worker report:
  `workers/eval-manager/task-ecount/report.json` (valid, 0 tool errors).
- `eval-designer` / `proposal-1` — `not-requested` (record only, no child).

## Required-output status

Controller-required outputs from `runs/run-1785717474603/phases/02-reeval/report.json`
and the phase plan:

- `workers/` session directory (artifact `session-directory`) — **present**;
  contains eval-manager and eval-worker sessions plus the director session.
- `events.jsonl` (artifact `raw-events`) — **present**; 7 controller events
  (cycle start through director dispatch), consistent with the phase state.
- `workers/eval-manager/task-ecount/REPORT.md` (narrative) — **present and
  valid**; phase `report.json` `narratives` lists it with `result: fail.`,
  `valid: true`.
- `workers/eval-manager/task-ecount/report.json` — **present and valid**.
- `workers/eval-worker/task-ecount-1/run.json` and `report.json` — **present
  and valid**; evidence of a failed trial (missing artifact).
- `lineage/handbook-approved.md` and `lineage/handbook-candidate.md` —
  **present**; identical (sha256 `c7c9dd9a…`), matching the manager's
  "unchanged" handbook decision.
- `workers/director/director/REPORT.md` (this report) — **present after this
  write**; was the single `missing`/`invalid` finding in the phase
  `report.json` and is now the director's required narrative output.
- `eval-designer` row — `not-requested` (record only, not an output gap).
- No ticket-implementation dispatch rows exist in eval mode; `engineer` is
  empty as expected.

## North-star impact

This cycle produced no product signal about the candidate fix: the worker
never reached XSH code, so the sort-by compound-key/stability/loud-rejection
change under review remains unexercised. The durable lesson is about agent
behavior and harness trust, not about XSH semantics:

- The failure was the agent's own resource-boundedness violation (unbounded
  background producer) plus an image-awareness error (`python3` is not in the
  gym), both already covered by the approved handbook — evidence that the
  guidance exists but was ignored, which argues for prompt/harness hardening,
  not handbook edits.
- The session terminated after the last tool result with no final message and
  no artifact at n=1. One sample cannot distinguish a harness defect from
  resource truncation after the flood; the manager's falsification plan (if
  the next replay also ends artifact-less at n≥2, investigate harness
  termination) is the right next step.
- Uncertainty: the trial gives no runtime evidence either way about
  task-ecount-003. Acceptance of the fix depends entirely on the next replay
  producing `ecount.xsh`, matching the `fd | awk | sort | uniq -c | sort -n`
  oracle byte-for-byte (including a tie-containing synthetic root), and
  verifying `xsht api language:stream.sort-by` documents key types,
  ascending/`--desc`, and stability. Until then the ticket remains
  `Approved.` and unmerged, pending the top-level user review.
