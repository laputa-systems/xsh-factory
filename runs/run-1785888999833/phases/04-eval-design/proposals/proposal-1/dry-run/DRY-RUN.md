# Task-colsum staged dry run

This dry run validates the task contract, the external oracle, and a reference
XSH solution on the host. The container isolation and package-owned evaluator
wiring are inherited unchanged from the approved scaffold and were **not**
re-run end-to-end in a container this cycle (the shared
`/usr/local/lib/xsh-factory` evaluator path is a container-only surface).

## What was exercised

- The external `awk` oracle (`colsum-oracle.sh`) across all nine cases:
  - `public` (age) → `12`
  - `hidden_order` (score) → `24`
  - `hidden_negative` (delta) → `0`
  - `hidden_many` (n, 10 rows) → `55`
  - `hidden_single` (val) → `42`
  - `hidden_no_data` (qty) → `0`
  - `hidden_extra_cols` (mid) → `60`
  - `hidden_missing_header` → exit 1, no output
  - `hidden_bad_value` → exit 2, no output
- A reference XSH `colsum.xsh` on the same fixtures: it byte-matches the oracle
  on all seven passing cases and exits nonzero with no output on both failure
  controls.
- `xsht check` and `xsht lint` on the reference solution both pass (exit 0).

## Evidence files

- `dry-run/colsum.xsh` — reference solution.
- `dry-run/colsum-oracle.sh` — external oracle.
- `dry-run/fixtures/t1..t9.csv` — the nine case fixtures.
- `dry-run/evidence/reference-checks.txt` — check/lint results.
- `dry-run/evidence/dry-run-comparison.txt` — candidate-vs-oracle comparison.

## What remains unproven

- End-to-end run inside the Pi container image (fixture seeding through
  `evaluator.xsh`, `/work`, `/export`, `/session`, `run.json` manifest). The
  package-owned `evaluator.xsh`, `executor.xsh`, and `evaluate.xsh` all pass
  `xsht check` locally; the container boundary is inherited from the approved
  scaffold and not re-verified in a container this cycle.
- A fresh agent-authored solution (the reference is a design-side oracle proof,
  not a worker trial).
