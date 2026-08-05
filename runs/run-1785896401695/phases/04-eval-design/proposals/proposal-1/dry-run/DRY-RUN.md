# task-revrank staged dry run

## What was exercised

A reference `revrank.xsh` and an independent external
`awk | sort` oracle were exercised on the host build against ten authored
fixtures matching the evaluator's public and hidden cases. See
`dry-run/evidence/transcript.txt` for the byte-exact transcript and fixtures.

- `public`: `north 20 / south 15 / east 4` — matches.
- `hidden_multiproduct`: one region across several rows accumulates — matches.
- `hidden_tie`: three equal totals ranked ascending by region — matches.
- `hidden_negative`: negative units/price totals and rank — matches.
- `hidden_order`: non-insertion-order rows still ranked — matches.
- `hidden_many`: larger multi-region set — matches.
- `hidden_empty`: empty input prints nothing, exit 0 — matches.
- `hidden_bad_fields`: 3-field line -> candidate exit 3 / oracle exit 2, both
  stdout empty — matches the failure control.
- `hidden_bad_unit`: non-integer units -> both exit nonzero, stdout empty.
- `hidden_missing`: absent file -> both exit nonzero, stdout empty.

The reference passes `xsht check` and `xsht lint` (lint emits only
prefer-list-comprehension / p-string style warnings, exit 0), so it is a
realistic, checker-clean candidate, not an uncheckable hack.

## What remains unproven

- A live container trial of the exact `/work` and `/session` mount paths and a
  real agent session.
- The package-owned `evaluator.xsh` wiring through the shared
  `/usr/local/lib/xsh-factory/evaluate_common.xsh` protocol, which is a
  container-only surface and was not re-run end-to-end this cycle.
- The descending-rank two-pass stable-sort idiom was proven on the host build
  (`revrank3`/`revrank.xsh`); the container build is assumed to share this
  stream ordering because it is exercised by the same `xsh` runtime family.

The `executor.xsh` and `evaluator.xsh` pass `xsht check` with exit 0; only the
container-specific evaluator plumbing remains to be demonstrated by the first
live trial.
