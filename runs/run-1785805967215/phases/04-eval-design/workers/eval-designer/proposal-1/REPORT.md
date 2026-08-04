# Eval-designer report

## Result

ready-for-review

## Proposal

A new eval proposal **task-propsort** was materialized by editing the
controller-provided task-tags scaffold, not by writing a new harness. It
probes a practical systems-administration workflow no current eval covers:
reading a plain-text allowlist/config file, dropping blank and comment lines,
trimming whitespace, sorting the survivors, and printing them byte-exact to
stdout (with a correct empty-result edge that prints nothing). It exercises
the `fs.read_text` facade, `Str.lines()/trim()/starts_with`, stream
`map`/`where`/`sort-by`/`collect`, `List.join`, and exact-output handling —
a read → filter → sort → exact-output glue pipeline.

Scaffolding (staged under
`runs/run-1785805967215/phases/04-eval-design/proposals/proposal-1/`):

- `EVAL.md` — Draft.; full contract, oracle, agent boundary, metrics, manager
  policy, and staged-dry-run record.
- `runtime/task.md` and `runtime/artifact.md` — the task prompt and the single
  deliverable `propsort.xsh`.
- `executor.xsh` and `evaluator.xsh` — thin selectors now passing the new
  `task-propsort` ID (the `evaluate.xsh` generic selector is unchanged).
- `dry-run/ref/propsort.xsh`, `dry-run/cases/*`, `dry-run/DRY-RUN.md` —
  reference solution, per-case candidate/oracle outputs, and evidence writeup.

The ID `task-propsort` is not present under `evals/`; the retired `task-tags`
identifier was fully replaced before any API query or dry run, and `Disabled.`
was changed to `Draft.`.

## Dry run

Completed on host with the same `xsht check` / `fmt` / `lint` tools a worker
uses, against a BusyBox `sed`/`grep`/`sort` oracle.

- Reference solution passes `xsht check` (rc 0), `xsht fmt`, and `xsht lint`
  (clean). Two targeted fixes surfaced the build's real contract: unary
  negation is `!expr` (the `not` token only forms `not in`-style ops), and
  `let path` shadows the standard `path` module (renamed to `input`, with
  `fp"${...}"` for a clean lint).
- Byte-for-byte parity on 8 representative cases (all PASS): public mixed,
  leading/trailing whitespace, comments-only (empty result exit 0), empty
  file (empty result exit 0), blank lines, tab whitespace, duplicates, and
  unsorted input.
- Negative controls: a subprocess escape (`run cat`) and a hard-coded output
  with no `fs.read_*` are both plainly detectable by the shared evaluator's
  source scan (inherited from the approved base image and used identically by
  `task-envcfg`); documented in `dry-run/DRY-RUN.md`.

Not exercised (and noted as unproven): a live paid Pi worker session (requires
auth + an active agent) and the containerized evaluator mount. Both are
inherited unchanged from the approved base image and shared evaluator
protocol, which this proposal does not modify.

## North-star impact

Capability hypothesis: an agent armed with the handbook should normalize a
plain-text config/allowlist in a short, typed read→filter→sort→exact-output
XSH program. This matters because XSH's mission is exactly this systems glue —
composing the file, text, and stream facets without shell sludge — and no
current eval covers a multi-line text file as the input producing a sorted
stdout contract. A successful run teaches whether the file-read facade, the
`Str` line/trim/starts_with surface, and the stream `where`/`sort-by` stages
are discoverable and composable together, and whether the handbook's exact
output and empty-result lessons transfer to a real config-normalization
boundary. The design resists task-specific hacks: hidden cases vary blank,
comment, whitespace-heavy, duplicate, and empty inputs, and a hard-coded
output, a lost final newline, an added diagnostic, or a subprocess escape each
fails a distinct gate — so a correct run is evidence of general fluency, not a
memorized answer.

## Known risks

- **Sort-order parity**: `sort-by` on `Str` vs the oracle's `LC_ALL=C sort`
  are asserted equal only for the ASCII test data used here. Non-ASCII UTF-8
  ordering is a documented open risk for a later replay, not an acceptance
  gate.
- **Oracle/tooling drift**: the oracle relies on BusyBox `sed`/`grep`/`sort`
  applets already in the shared base image; this eval is treated as a `read`
  task (like `task-envcfg`), and the byte-exact oracle is external to the
  candidate.
- **Inherited evaluator/worker paths unproven end-to-end**: the live Pi agent
  and containerized evaluator mount were not run in this proposal (budgeted
  out); they are unchanged from the approved base image, but a real trial is
  the only proof they remain green.
- Missing checks to consider at approval: confirm the shared evaluator's
  `review.md` heading and `fs.read_*`-presence checks match this artifact's
  name (`propsort.xsh`) before the first paid run.

## Review path

On CTO approval the package promotes to `evals/task-propsort/` (EVAL.md,
evaluate.xsh, evaluator.xsh, executor.xsh, runtime/task.md,
runtime/artifact.md) and becomes `Approved.` only after the evaluator and
evidence pass; until then it stays `Draft.`. Evidence for the decision:
`EVAL.md` (contract + oracle + metrics + manager policy), `dry-run/DRY-RUN.md`
(recipe and verdicts), `dry-run/ref/propsort.xsh` (clean reference that
matches the oracle on all 8 cases), the per-case `dry-run/cases/*.cand` /
`*.ora` byte-for-byte outputs, and the negative-control sources. CTO gates:
confirm `xsht check`/`lint` clean, the oracle parity, and that the shared
evaluator protocol needs no task branch (this proposal adds none).
