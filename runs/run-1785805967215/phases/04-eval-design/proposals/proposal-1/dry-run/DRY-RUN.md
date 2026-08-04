# task-propsort — staged dry run

This proposal was materialized under `proposals/proposal-1/` and dry-run with a
reference solution exactly as a real worker would (handbook + `xsht` tools, no
subprocesses). The agent half (a live Pi worker) is inherited unchanged from
the approved base image (`eval-worker.xsh`) and was not re-exercised; it
requires a paid Pi session and an auth file.

## Contract viability

`ref/propsort.xsh` (the intended solution shape) passes:

- `xsht check` — parse + type-check clean (rc 0), after two targeted fixes:
  1. `not l.starts_with(...)` is not a unary-prefix form in this build; use
     `!l.starts_with(...)` (the `not` token is only the `not in`-style op).
  2. a `let path = ...` binding shadows the standard `path` module; renamed to
     `input`. `Path(argv[0])` lints as preferring `fp"${argv[0]}"`, so the
     reference uses the interpolated path form for a clean `xsht lint`.
- `xsht fmt` — idempotent formatting.
- `xsht lint` — clean (rc 0, no warnings).

The verified API surface: `fs.read_text(path: Path) -> Result[Str]` (effects
`fs`), `Str.lines()`, `Str.trim()`, `Str.starts_with(prefix)`, stream
`map`/`where`/`sort-by { |l| l }`/`collect()`, `List.join("\n")`, and the
exact-output empty-result guard (`if out.len() != 0 { print ... }` so an empty
result emits nothing, not a lone newline).

## Oracle parity (on host, BusyBox `sed`/`grep`/`sort`)

Oracle: `sed 's/^[[:space:]]*//; s/[[:space:]]*$//' "$in" | grep -v '^#' |
grep -v '^$' | LC_ALL=C sort`. Eight representative cases, all byte-for-byte
PASS (candidate stdout == oracle stdout, `cmp` clean):

| case | input | result |
| --- | --- | --- |
| public | mixed comments + blank + padded ASCII | PASS |
| hidden_mixed | leading/trailing whitespace | PASS |
| hidden_comments_only | only `#`/blank/whitespace lines | PASS (empty, exit 0) |
| hidden_empty | empty file | PASS (empty, exit 0) |
| hidden_blank_lines | many blank lines | PASS |
| hidden_tab_whitespace | tab-indent + trailing tabs | PASS (trim handles tabs) |
| hidden_duplicates | duplicate entries | PASS (both preserved) |
| hidden_unsorted | deliberately out-of-order | PASS (sorted) |

Reference stdin/error were empty on every case (no diagnostics on stdout; the
empty-result cases exit 0 and print nothing).

## Negative controls

The shared evaluator enforces a source scan for the forbidden subprocess
boundary and for a hard-coded text workaround (no `fs.read_text`). Evidence:

- `bad_subprocess.xsh` (`run cat …`) — detected: source contains the process
  boundary (and also fails `xsht check`); would be classified `restriction_failed`.
- `bad_hardcoded.xsh` (prints a literal, never reads the file) — compiles but
  contains no `fs.read_*` call; detected as a hard-coded workaround and would
  be classified `restriction_failed`.
- `review.md` protocol (both required headings) is enforced by the shared
  evaluator exactly as in `task-envcfg`; not re-run here.

## Remaining unproven

- A live paid Pi worker session (requires auth + an active agent); the worker
  entry point is unchanged from the approved base image.
- The containerized evaluator mount (Docker images + `/usr/local/lib/xsh-factory`
  factory lib) end-to-end; the shared `evaluate_common.xsh` protocol is
  inherited and was not modified.
- Non-ASCII byte ordering in `sort-by` vs `LC_ALL=C sort`: test data is ASCII
  by design; UTF-8 ordering is left to a later replay if the eval is approved.
