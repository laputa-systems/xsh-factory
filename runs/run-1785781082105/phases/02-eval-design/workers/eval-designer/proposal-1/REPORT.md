# Eval-designer report — task-setdiff

## Result

ready-for-review

## Proposal

A new, small practical XSH eval proposal **`task-setdiff`** (no harder than
ecount) is staged and dry-run-proven under:

`runs/run-1785781082105/phases/02-eval-design/proposals/proposal-1/`

- `EVAL.md` — full contract: status `Draft.`, unique `task-setdiff` ID (not
  present under `evals/`), purpose, north-star hypothesis, task, agent
  boundary, oracle/evaluator, metrics, manager policy, staged dry run.
- `runtime/task.md`, `runtime/artifact.md` — user-facing prompt and
  `setdiff.xsh` artifact.
- `executor.xsh`, `evaluator.xsh`, `evaluate.xsh` — thin selectors, each
  passing `xsht check`, all wired to `task-setdiff`.
- `dry-run/` — reference solution, runner, and evidence (see below).

The task reads two line files, dedups each into a set (`set.from` /
`set.has`), emits the unique lines of `fileA` absent from `fileB` sorted in
byte order, and matches a portable `sort -u` + `comm -23` oracle. This is the
classic config-drift / package-reconcile shape and fills the portfolio gap for
the `set` module and set-difference logic (no approved eval covers it).

## Dry run

Exercised with `xsht check` / `fmt` / `lint` (all clean) and a byte-for-byte
comparison against the portable oracle:

- **10 success cases all PASS**: public overlap, disjoint, all-in-B (empty),
  B-empty, A-empty, duplicates (dedup), UTF-8 + spaces, unsorted, interior
  blank line, trailing-newline edge.
- **2 failure controls** (`missing_a`, `missing_b`): exit code 3 (nonzero),
  no fabricated output — matching the task-col2-style candidate-only contract
  (the `comm` oracle does not propagate a missing file, so it is not matched).
- **Contract semantics confirmed**: `Str.lines()` yields no trailing empty
  member but does yield interior blank lines; `sort-by` is byte (C-locale)
  order; the oracle was reformulated to BusyBox-`sh`-compatible temp-file form
  (bash-only `<(...)` process substitution is not portable to the Alpine
  container).

Unproven: the live Pi worker session and the containerized
`evaluate_common` `run.json` classification — both inherited unchanged from
the approved platform and require a paid agent/Pi auth file; the reference
program proves the task contract and oracle are solvable and byte-exact.

## North-star impact

This probes whether the handbook makes the `set` module and line-stream edge
semantics discoverable and composable for real systems glue. Successful runs
teach the factory whether replacing `comm -23 <(sort -u A) <(sort -u B)` with
a typed `fs.read_text` → `Str.lines` → `set.from`/`set.has` → `sort-by`
pipeline is ergonomic for agents, and whether the Result/`?` lesson transfers
to a missing-input boundary. It resists task-specific hacks: hidden cases vary
membership, order, duplication, blank, and UTF-8 content, and the failure
controls require a loud nonzero exit — a hard-coded answer, a wrong dedup/sort,
or a subprocess escape each fail a distinct gate.

## Known risks

- **Oracle portability (addressed)**: the first oracle draft used bash-only
  process substitution; the finalized oracle uses temp files verified under
  plain `sh`. Stated clearly in `EVAL.md`/`task.md`.
- **Missing-file failure is candidate-only**: the `comm` oracle returns 0 on a
  missing file, so the evaluator must check the candidate's exit code rather
  than matching the oracle for the failure cases (same design as task-col2).
- **Evaluator restriction heuristic**: enforcing the `set`-module reference
  is a static source check; a clever candidate could still pass while
  hard-coding via `set.from` of a literal, but the hidden randomized content
  makes a hard-coded answer fail correctness.
- **Unproven harness**: the containerized evaluator `run.json` classification
  and live agent path were not exercised (paid/Pi-auth required); the CTO
  review should treat correctness as proven and the harness run as pending
  first execution.
- **Sort-ordering coupling**: byte vs. collation order must stay `LC_ALL=C`
  in the oracle; the UTF-8 case passed, confirming byte order.

## Review path

Promote the staged package to **`evals/task-setdiff/`** (this path is free:
no `task-setdiff` exists under `evals/`). The CTO approves the eval from:

- `proposals/proposal-1/EVAL.md` (complete contract, status `Draft.`),
- `proposals/proposal-1/dry-run/DRY-RUN.md` and `cases.txt` (10/10 success +
  2/2 failure controls byte-exact),
- the reference `dry-run/setdiff-reference.xsh` proving solvability.

The proposal is intentionally left `Draft.`; the CTO sets `Approved.` only if
the first real containerized evaluator run returns a passing `run.json`, per
the factory's admit-after-review gate.
