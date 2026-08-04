# task-uniqcat dry run (eval-designer)

Staged proposal: `proposals/proposal-1`. This directory holds the materialized
dry-run evidence from the eval-design phase.

## What was exercised

The package-owned `evaluator.xsh` (self-contained; it does not edit the shared
`evaluate_legacy.xsh`) was run in a local scratch sandbox that mirrors the
container boundary by pointing its `/work`, `/session`, `/export` roots at a
writable directory. A correct candidate `uniqcat.xsh` was placed in the work
tree alongside a `review.md` and the handbook/task snapshots.

All eight representative cases were run, each comparing the candidate
`xsh uniqcat.xsh FILE...` against the BusyBox-awk oracle
`awk '!seen[$0]++' FILE...` byte-for-byte (see `run.json` correctness block):

- `public` — two files with one shared line → `alpha,beta,gamma,delta`
- `hidden_single` — internal duplicates in one file
- `hidden_three` — cross-file duplicates across three files
- `hidden_blank` — `a\n\nb` (blank line inside, unterminated last line)
- `hidden_utf8` — UTF-8 lines with a later duplicate
- `hidden_space` — leading/trailing spaces preserved, not over-deduped
- `hidden_all_empty` — every file empty → empty stdout
- `hidden_missing` (failure control) — both sides exit nonzero, empty stdout

Result: `classification = pass`, `result = pass`, `all_exact = true`,
`restrictions.passed = true`, `protocol.review_ok = true`. Candidate and
oracle timings are recorded in `run.json`.

## Negative controls (anti-hack gates)

- subprocess escape (`process.run("awk", ...)`): `classification = restriction_failed`
  (`forbidden_operations = false`);
- hard-coded print with no `read_text` reference: `classification = restriction_failed`
  (`read_referenced = false`);
- wrong semantics (sorting instead of first-occurrence order): `classification = candidate_failed`.

Each non-compliant shape is caught by a distinct gate.

## Oracle/contract finding fixed during the dry run

An initial failure-control case put the unreadable file last. Both `awk` and a
correct candidate stream the earlier valid file's lines to stdout before
failing on the missing file, so "print nothing" was not realizable. The case
was changed to place the unreadable file **first**, so both sides fail before
emitting any stdout, honoring the stated contract. `task.md` and `EVAL.md`
were updated to state this ordering explicitly.

## Remaining unproven locally

The full container worker loop (eval-executor launching a real Pi worker,
session `session.jsonl.bz2`, image admission) was not run here; this dry run
proves the contract and the package-owned evaluator's case/oracle/restriction/
manifest logic. All package `.xsh` files pass `xsht check`.
