# Director report: 02-reeval (task-ecount)

## Result

pass

The eval cycle completed with valid, mutually consistent evidence. Trial 1 of
`task-ecount` passed every evaluator gate against the pre-merge candidate
commit `c2e1039d8856c04ad8466504d445dc93a341f720` (task-ecount-003 worktree):
byte-for-byte oracle equality (`candidate_sha256 == oracle_sha256 ==
c7c35609…`), restriction compliance, protocol completion, and timing ratio
0.9434 within the 0.90–1.10 gate (`run.json` `result: pass`). The eval-manager
reviewed the executor packet and the worker session, classified the evidence,
accepted the candidate for pre-merge validation (ACCEPT), and filed one new
open ticket (`task-ecount-007`) for the next cycle. The phase-level
`report.json` reads `fail` only because the director report was missing at
snapshot time; that required output is written now, so no child evidence is
missing or contradictory.

## Cycle

- Mode: `eval`.
- Selected eval: `task-ecount`; trials configured/completed: 1 / 1. New eval
  proposals: 0. Approved tickets for implementation: none (this phase is a
  pre-merge validation, not a ticket-implementation run).
- Controller's plan (per `CYCLE-REQUEST.md` and `report.json`): validate the
  task-ecount-003 implementation against the linked task-ecount eval before
  merge. The controller executed the eval-worker (executor) and eval-manager
  rows; eval-designer was `not-requested`. The director reviewed the completed
  evidence and did not launch or wait on any child.
- Candidate XSH commit under test: `c2e1039d` (confirmed by `run.json`
  `xsh_commit`, `xsh-build.state` `build-id=c2e1039d…`, and XSH repo HEAD).
- Handbook lineage: `lineage/handbook-approved.md` == `lineage/handbook-candidate.md`
  (identical sha256 `c7c9dd9a…`); manager decision: unchanged.

## Children

One row per dispatched/recorded child (eval mode: all rows are completed
evidence; no children launched by the director):

- `eval-worker` `task-ecount-1` (trial 1): **pass**. `run.json` correctness
  pass (exact byte-identical output, oracle ok), restrictions pass, protocol
  pass (artifact `ecount.xsh` present, `review.md` present), timing pass
  (ratio 0.9434), `xsh_commit c2e1039d…`. 3 structured tool errors, all
  classified by the manager as minor product/tooling friction or ordinary
  worker friction, none failing the eval. Evidence:
  `workers/eval-worker/task-ecount-1/run.json`, `report.json`,
  `session.jsonl.bz2`, `ecount.xsh`, `review.md`.
- `eval-manager` `task-ecount`: **pass**. Narrative `REPORT.md` present and
  valid; manager accepted the task-ecount-003 candidate for pre-merge
  validation, kept the handbook unchanged, and created new open ticket
  `tickets/task-ecount-007.md` (fold/reduce accumulator-plus-item binding
  unusable) with reproducible probes. Evidence:
  `workers/eval-manager/task-ecount/REPORT.md`, `report.json`, `session.jsonl.bz2`.
- `eval-designer`: `not-requested` — record only, no child. Evidence path:
  `report.json` `designer` entry (`present: false`).

## Required-output status

Controller-required outputs from `report.json` and the phase assignment, with
presence/validity:

- `workers/` session directory (artifact `session-directory`): present.
- `events.jsonl` (artifact `raw-events`): present; events record
  cycle-started → manager-admitted → trial-1-started/completed →
  manager-started/completed → director-started.
- Eval-worker evidence packet (`workers/eval-worker/task-ecount-1/run.json`,
  `report.json`, `session.jsonl.bz2`, `ecount.xsh`, `review.md`): present, valid,
  result pass.
- Eval-manager narrative (`workers/eval-manager/task-ecount/REPORT.md`) and
  `report.json`: present, valid, result pass.
- Handbook lineage files (`lineage/handbook-approved.md`,
  `lineage/handbook-candidate.md`): both present; candidate identical to
  approved (unchanged).
- Director narrative (`workers/director/director/REPORT.md`): this file;
  present and valid now (was the sole `missing` finding at phase snapshot,
  which is the reason the phase `report.json` `result` field reads `fail`).
- New ticket `tickets/task-ecount-007.md`: created by the manager, status
  Open, not part of this phase's dispatch; waits for the next human-approved
  transition per policy.
- Metadata note (not a product defect): the phase `report.json` `xsh_commit`
  field (`ea7dea2f…`) disagrees with the authoritative executor manifest
  (`run.json` `xsh_commit` `c2e1039d…`) and `xsh-build.state` build-id
  (`c2e1039d…`); XSH repo HEAD is `c2e1039d…`. The container ran the
  candidate. The phase field appears to be a controller-level baseline label;
  the manager flagged it for controller verification.

## North-star impact

This cycle validates the first concrete correction to XSH's sort contract:
record-key `sort`/`sort-by` now orders deterministically (field-by-field in
sorted field-name order), unsupported keys fail loudly instead of silently
no-op'ing, and stability is documented. The evidence that this is a general
improvement rather than noise: the eval worker read the updated contract and
derived the count-major/name-minor ordering directly in one step (session
thinking lines 57 → 133 → 135: from the two-pass trial-and-error idiom to
"records compare field-by-field … `sort()` might give the exact ordering
directly!", then byte-identical verification on `/usr/share` and a synthetic
tie-containing root). That is exactly the removal of the "repeated
discoveries" the north star demands, and the run matches the oracle
byte-for-byte. Uncertainty remains on the compound-key half of the
acceptance criteria: the eval oracle's `/usr/share` data has no count ties and
the eval did not directly exercise `sort-by` on a compound record key, so the
tie-order claim rests on the worker-side synthetic check plus the candidate's
own test suite; the manager's next replay should use an evaluator-managed
tie-containing root after the user merges `c2e1039d…`.

The run also surfaced the next ergonomics defect: `fold`/`reduce` cannot
express an accumulator-plus-item reduction in the compact runtime (parse and
arity rejections, plus an internal `compact.indexed-build` /
`full_ir_function_blocker` crash with no source mapping), even though the
handbook points agents to it. That generalizes to any accumulate pipeline and
is recorded as open ticket `task-ecount-007` with reproducible probes. Minor
frictions (`Str.len()` naming inconsistency in the same discoverability class
as `task-ecount-001`, `cannot display Record`/`List` introspection limits)
were noted but not separately ticketed. The metadata discrepancy on the phase
`xsh_commit` label is a controller-side bookkeeping item, not a language
signal. Overall the cycle is strong product evidence: one accepted sort
correction and one clearly specified follow-up defect, with the next replay
named for falsification.
