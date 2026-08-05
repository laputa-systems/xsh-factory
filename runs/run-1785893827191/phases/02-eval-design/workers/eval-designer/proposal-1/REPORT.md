# Eval-designer report

## Result

ready-for-review

## Proposal

A new eval `task-usagerep` (aggregate per-service usage across a tree of
measurement files) was materialized under the controller-staged package:

- `phases/02-eval-design/proposals/proposal-1/EVAL.md` — full contract; `Status`
  set to `Draft.`; includes the required `## Difficulty justification`.
- `phases/02-eval-design/proposals/proposal-1/runtime/task.md` — agent-facing
  task text.
- `phases/02-eval-design/proposals/proposal-1/runtime/artifact.md` — artifact
  name `usagerep.xsh`.
- `phases/02-eval-design/proposals/proposal-1/executor.xsh` — thin
  `task-usagerep` selector for the shared eval executor.
- `phases/02-eval-design/proposals/proposal-1/evaluator.xsh` — package-owned
  evaluator (stages a fixture tree per case, runs the candidate as
  `xsh /work/usagerep.xsh <root>`, compares byte-for-byte with an independent
  printf / `sh -c 'exit 1'` oracle, checks `read_text`/`fs.files`/`fs.walk`
  source references and the no-subprocess boundary, writes `run.json`).
- `phases/02-eval-design/proposals/proposal-1/evaluate.xsh` — unchanged generic
  shared-evaluator selector.
- `phases/02-eval-design/proposals/proposal-1/dry-run/DRY-RUN.md` — saved
  reference-check evidence.

The task combines recursive multi-file discovery + content parsing (a richer
transformation than `task-ecount`, which never reads a file body), a stateful
Map fold with two independent accumulators (SUM and COUNT per service), and
composite ranking (SUM desc, then SERVICE asc byte order). It includes a
meaningful failure control (any malformed line forces nonzero exit with empty
stdout) and ten hidden cases (multi-file spread, SUM ties, byte-order traps,
blank/whitespace lines, empty tree, empty file mixed in, spaces in names, and
two malformed-line failures) that defeat a hard-coded answer; the source checks
block a subprocess or literal-output escape.

## Dry run

Exercised on the host with the local XSH build: `xsht check` on
`evaluator.xsh`, `executor.xsh`, and the generic `evaluate.xsh`; all three pass
with exit 0. The result is saved under the proposal at
`proposal-1/dry-run/DRY-RUN.md`. The evaluator's staging, oracle, restriction,
and `run.json` logic follow the approved package-owned pattern from
`task-groupsum`.

Remaining unproven (normal for a design-cycle dry run, not a gap): a live
container trial that exercises the exact `/work`, `/session`, `/export` mount
paths, a real agent session, and candidate-vs-oracle byte matching for every
case. No candidate-vs-oracle run was fabricated; the report and `EVAL.md` state
only the syntax/reference check that was actually performed.

## North-star impact

Hypothesis: an agent that has read the handbook can turn "read every `*.usage`
file under a root, sum units and count lines per distinct service, and print a
ranked `SERVICE SUM COUNT` report" into a typed XSH program using recursive
filesystem streams, `read_text`, integer parsing, a two-accumulator Map fold,
and composite `sort-by`, without falling back to subprocesses. This is the
XSH analogue of the metering/summary glue (`cat *.usage | awk ...`) that UNIX
solves with sludge; a pass would show the factory that multi-file discovery and
two-field stateful aggregation compose from the handbook, while a miss names
which idiom (Map accumulation, tie-break sorting, or content reads) needs
clearer handbook guidance. It honors the explicit-boundary and composability
ethos by keeping the whole pipeline in typed XSH values and requiring a loud
nonzero failure on malformed input.

## Known risks

- Task-specific hacks are blocked by source checks (`read_text` memory,
  `fs.files`/`fs.walk`, no forbidden subprocess) and by hidden cases that vary
  the tree shape, spread, ordering, and byte-order traps at runtime; a
  literal-output or `awk`/`sh` escape fails a distinct gate. A candidate
  writing its own hidden shell call inside a string that avoids the simple
  forbidden subprocess tokens is a residual (low) risk, consistent with the
  approved evaluators.
- Oracle/timing: success cases use a `printf` oracle fed authored expected rows
  derived independently of XSH; failure cases use `sh -c 'exit 1'`. Fixture
  expected strings contain no `%` or backslashes, so `printf` is safe. Timing
  is diagnostic only (no strict envelope); both sides finish in milliseconds.
- The evaluator assumes `env.get_or` fallbacks default to the container paths;
  the host overrides (`USAGEREP_*`) are only for non-production validation and
  are unproven until a live container trial.
- Missing check: a live container end-to-end trial is not in this proposal and
  must be confirmed by the CTO review before any admission.

## Review path

Promote to `evals/task-usagerep/` (with `EVAL.md` left as `Draft.` per the
factory contract; the CTO sets `Approved.` only after the evaluator and
evidence pass). Evidence for the CTO decision: the complete package with the
`## Difficulty justification` section, the package-owned `evaluator.xsh`,
the saved `dry-run/DRY-RUN.md` showing all package scripts pass `xsht check`,
and the explicitly named unproven surface (live container trial). Until that
trial passes, the eval is not admitted to paid work.
