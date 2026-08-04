# Eval-designer report

## Result

ready-for-review

## Proposal

New eval **task-uniqcat** (Draft.) — "merge and dedup several line-oriented
files, keeping each distinct line once in first-occurrence order," the XSH
analogue of `awk '!seen[$0]++' file...` with no subprocess. It fills the
multi-file + order-preserving-dedup gap none of the approved evals cover.

Staged package:
`runs/run-1785801609594/phases/04-eval-design/proposals/proposal-1/`

- `EVAL.md` — purpose, north-star hypothesis, task, agent boundary, oracle and
  hidden cases, metrics, manager policy; Status `Draft.`, identity
  `task-uniqcat` (no collision under `evals/`; `task-tags` fully replaced).
- `runtime/task.md` — worker-facing contract with the `awk` oracle and
  no-subprocess / `read_text` / exact-output rules.
- `runtime/artifact.md` — `uniqcat.xsh`.
- `executor.xsh` — thin `task-uniqcat` selector to the shared eval-executor.
- `evaluate.xsh` — generic selector to the shared dispatcher (unchanged).
- `evaluator.xsh` — self-contained package-owned evaluator (the migration
  pattern; it does **not** edit the shared `evaluate_legacy.xsh`): writes the
  fixture files, runs candidate vs. BusyBox-awk oracle byte-for-byte for 8
  cases, checks the forbidden-subprocess boundary and a `read_text` reference,
  verifies `review.md` headings, and writes the standard `run.json` manifest.
- `dryrun/` — materialized dry-run evidence (see Dry run).

## Dry run

The package-owned evaluator was exercised in a scratch sandbox that mirrors the
container boundary by pointing `/work`, `/session`, `/export` at writable local
dirs. Summary in `dryrun/DRYRUN.md`; candidate, manifests, and per-case
candidate/oracle stdout staged under `dryrun/`.

Exercised: all eight representative cases — `public`, `hidden_single`,
`hidden_three`, `hidden_blank` (`a\n\nb`, unterminated last line),
`hidden_utf8`, `hidden_space`, `hidden_all_empty`, and `hidden_missing`
(failure control). Result: `classification=pass`, `result=pass`, `all_exact`
true, `restrictions.passed` true, `protocol.review_ok` true; candidate/oracle
timings recorded. Negative controls confirm the anti-hack gates: a subprocess
escape → `restriction_failed`; a hard-coded/no-`read_text` print →
`restriction_failed`; sorting instead of first-occurrence order →
`candidate_failed`. All package `.xsh` files pass `xsht check`; the candidate
also passes `xsht check`/`fmt`.

Oracle/contract issue found and fixed during the dry run: a failure-control
case with the unreadable file last lets both `awk` and a correct candidate
stream earlier lines before failing, so "print nothing" was not realizable. The
case now places the unreadable file **first**, and `task.md`/`EVAL.md` state
that ordering explicitly.

Remaining unproven: the full container worker loop (real Pi worker,
`session.jsonl.bz2`, image admission under eval-executor). This dry run proves the
task contract, oracle semantics, isolation/restriction gates, and the
evaluator's case + manifest logic.

## North-star impact

Capability hypothesis: a learner with the handbook should turn a classic
sysadmin chore — merging and deduplicating several config/host/package lists
while preserving first (priority) occurrence — into a short typed XSH program
that reads each file through XSH text APIs, honors the `Str.lines` boundary
model, and dedups with a membership set, without falling back to a subprocess
or a sort. A passing run teaches the factory whether multi-file sequential
input and order-preserving membership dedup compose for real world "merge
these lists" glue — distinct from the sorted two-file difference of
`task-setdiff` and the single-input aggregations of `task-total`/`task-col2`.
The hidden cases (overlap, blank/unterminated lines, UTF-8, preserved spaces,
empty files) and the loud-failure control make a hard-coded answer, a wrong
dedup, a silent fallback, or a subprocess escape each fail a distinct gate, so
success is evidence of a general idiom rather than a task-specific workaround.

## Known risks

- **Task-specific hack:** low — the `read_text`-reference restriction, the
  no-subprocess boundary, and eight varying hidden cases each fail distinct
  gates; a canned print is classified `restriction_failed`.
- **Oracle/Awk equivalence:** the contract depends on `Str.lines` matching
  awk's record model (blank lines, unterminated final line). This was verified
  directly against BusyBox-awk locally, but a pinned-image `awk`/`Str.lines`
  divergence would surface as a false failure; flagged for the first paid
  trial.
- **Failure-control ordering:** relies on the unreadable file being the first
  argument so both sides print nothing. An implementer that reads all files
  eagerly before printing could still differ from the streaming oracle; the
  current case ordering sidesteps this but should be watched.
- **Timing:** no strict ratio gate yet (both sides are sub-millisecond); timing
  is diagnostic until a stable envelope.
- **Container loop not proven here:** the real eval-executor/worker/image path
  was not run in this proposal phase; a full trial is the remaining validation.

## Review path

Promotion path (unchanged by this phase): the CTO's
`eval-design` controller materializes `proposals/proposal-1/` into
`evals/task-uniqcat/` and sets the status. Evidence the CTO should use for the
`Approved.` vs `Draft.` decision:

- `EVAL.md` status line (`Draft.`) and the complete contract;
- `dryrun/DRYRUN.md` + `dryrun/run.json` — all 8 cases `pass`,
  `restrictions.passed`, `protocol.review_ok`;
- `dryrun/uniqcat.xsh` — the verified correct candidate;
- negative-control results (subprocess → restriction_failed, hard-coded →
  restriction_failed, wrong order → candidate_failed);
- all package `.xsh` files pass `xsht check`.

`## Result` is `ready-for-review`; the CTO decides whether the promoted package
becomes `Approved.` or stays `Draft.`. No approved eval or shared handbook was
modified.
