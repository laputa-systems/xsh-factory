# DRY-RUN — task-setdiff

## What was exercised

A reference XSH solution (`setdiff-reference.xsh`, using `fs.read_text`,
`Str.lines`, `set.from` / `set.has`, `where`, `sort-by`, and a `for` print
loop) was validated with `xsht check`, `xsht fmt`, and `xsht lint` (all
clean), then compared byte-for-byte against the portable
`sort -u` + `comm -23` oracle on ten representative cases plus two
missing-file failure controls. Evidence is in `cases.txt`.

| Case | Result |
| --- | --- |
| public (overlap) | PASS |
| hidden_disjoint (no common lines) | PASS |
| hidden_all_in_b (empty result) | PASS |
| hidden_b_empty (all of A) | PASS |
| hidden_a_empty (empty result) | PASS |
| hidden_duplicates (dedup required) | PASS |
| hidden_utf8_spaces (spaces + UTF-8) | PASS |
| hidden_unsorted (deterministic sorted output) | PASS |
| hidden_blank_lines (interior blank line is a member) | PASS |
| hidden_trailing (trailing newline adds no line) | PASS |
| missing A (failure control) | exit=3 nonzero, no fabricated output |
| missing B (failure control) | exit=3 nonzero, no fabricated output |

The two success oracle semantics vital to the contract were confirmed:

- `Str.lines()` splits on `\n`; a final trailing newline does not add an empty
  member, but an interior blank line does — matching `sort -u` on the same
  file.
- `sort-by { |k| k }` sorts in byte (C-locale) order, matching
  `LC_ALL=C sort -u`.

## What remains unproven

- The live Pi worker agent session (requires a paid agent session and a Pi
  auth file). The agent path is inherited unchanged from the approved base
  image and is not part of this package's contract.
- The containerized `evaluate_common` evaluator harness run against a staged
  `/work` directory and its `run.json` classification output. The package's
  `evaluator.xsh` / `executor.xsh` / `evaluate.xsh` selectors each pass
  `xsht check`; the reference program proves the task contract and oracle are
  solvable and byte-exact, and the evaluator's restriction and `review.md`
  heading checks are inherited from the approved platform.
