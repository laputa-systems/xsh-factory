# Eval-designer report

## Result

ready-for-review

## Proposal

New eval **task-colsum**: sum a named numeric column of a comma-separated
table, reading through XSH `fs`/text values with a byte-exact single-line
integer report. Repurposed from the approved task-bigfiles scaffold; title and
ID replaced, status set to `Draft.`.

Scaffolding (all present):
- `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785888999833/phases/04-eval-design/proposals/proposal-1/EVAL.md`
- `.../proposal-1/runtime/task.md`
- `.../proposal-1/runtime/artifact.md`
- `.../proposal-1/executor.xsh`
- `.../proposal-1/evaluator.xsh`
- `.../proposal-1/evaluate.xsh`
- `.../proposal-1/dry-run/DRY-RUN.md` plus `dry-run/colsum.xsh`,
  `dry-run/colsum-oracle.sh`, `dry-run/fixtures/`, `dry-run/evidence/`

## Dry run

The external `awk` oracle and a reference XSH solution were exercised on the
host across the public case, six hidden cases, and both failure controls.
The reference byte-matched the oracle on every passing case (`12`, `24`, `0`,
`55`, `42`, `0`, `60`) and both sides exited nonzero with no stdout on the
`hidden_missing_header` and `hidden_bad_value` failure controls. The reference
passes `xsht check` and `xsht lint` (exit 0). All three package scripts pass
`xsht check` locally. Evidence is saved under the proposal at
`dry-run/evidence/`.

Remaining unproven: end-to-end run inside the Pi container (fixture seeding,
`/work`/`/export`/`/session`, `run.json` manifest) and a fresh agent-authored
solution. That container boundary is inherited unchanged from the approved
scaffold and was not re-run in a container this cycle.

## North-star impact

Hypothesis: an agent with the shared handbook can replace the `awk -F,`
column-sum shape with a clear, typed XSH program — reading file text through
`fs`/`read_text`, splitting the header row to resolve a column name, parsing
each cell with `Str.parse_int()?` so a malformed cell fails loudly, and
emitting a byte-exact integer total with no subprocess escape. A successful
run teaches whether the typed-boundary `Result`/`?` idiom transfers to a
per-cell table reduction and whether comma-split header indexing is
discoverable and composable. This is a practical data-munging systems-glue
capability not covered by any approved eval (`intsum` sums argv, `total` sums
every whitespace field, `groupsum` totals per key, `jsonfilter` reads JSON).
The design resists task-specific hacks because hidden cases vary header order,
column position, sign, row count, empty tables, a missing header name, and a
malformed cell — a hard-coded total, a silent default, or a subprocess escape
each fail a distinct gate.

## Known risks

- Per-cell parsing is the main correctness surface; a candidate could silently
  coerce or ignore a bad cell, but the `hidden_bad_value` and
  `hidden_missing_header` failure controls require a loud nonzero exit with no
  output, so silent defaults fail.
- The oracle is `awk` byte-formatting (`%d`); the evaluator relies on the same
  shared base image and the same fixture path, so the candidate and oracle
  observe identical tables.
- No strict timing gate (both sides are sub-millisecond); timing is diagnostic
  until a stable envelope exists.
- Missing checks: container-isolation wiring and worker-authored artifact were
  not exercised end-to-end this cycle (inherited scaffold boundary).
- Restriction heuristic requires `read_text` and `parse_int` in source and
  forbids known subprocess tokens; it is intentionally narrow and could miss an
  exotic escape, which container isolation is expected to cover.

## Review path

Promoted eval path (pending CTO action): `evals/task-colsum/` with
`EVAL.md`, `evaluate.xsh`, `executor.xsh`, `evaluator.xsh`, and
`runtime/{artifact.md,task.md}`. Evidence for the decision: the package is
complete, status `Draft.`, source run
`runs/run-1785888999833/phases/04-eval-design/proposals/proposal-1/`, and the
host dry run (`dry-run/evidence/`) shows the oracle and a reference solution
agree byte-for-byte on all passing cases and fail loudly on both failure
controls, with all package scripts passing `xsht check`.
