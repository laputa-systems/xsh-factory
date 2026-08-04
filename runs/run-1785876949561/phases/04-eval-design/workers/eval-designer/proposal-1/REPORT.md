## Result

ready-for-review

## Proposal

New eval proposal `task-pathparts` staged under:

- `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785876949561/phases/04-eval-design/proposals/proposal-1/EVAL.md`
- `.../proposal-1/runtime/task.md`
- `.../proposal-1/runtime/artifact.md` (`pathparts.xsh`)
- `.../proposal-1/executor.xsh`
- `.../proposal-1/evaluator.xsh`
- `.../proposal-1/evaluate.xsh` (generic dispatcher, unchanged)
- `.../proposal-1/dry-run/DRY-RUN.md`

The scaffold's retired `task-tags` title and ID were replaced with the new
`task-pathparts` ID, and `Status` is `Draft.`. The agent boundary, oracle,
hidden cases, restriction checks, metrics, manager policy, and review/agent
scaffolding are all present. The proposal is `Draft.` pending CTO review.

## Dry run

- `xsht check` passes (exit 0) on `executor.xsh`, `evaluator.xsh`, and
  `evaluate.xsh`. Two focused scaffold fixes were required and applied: `Map[...]`
  takes one type parameter, and the effect-free `forbidden_source` helper was
  declared `pure`.
- The typed `Path` semantics (`Path(str).parent()`, `.name()`, `.ext()` with the
  `none` mapping) were verified byte-for-byte against the independent BusyBox
  `sh` / `basename` / `dirname` oracle on the local host build for every planned
  public and hidden case; each produced identical three-line output. See
  `dry-run/DRY-RUN.md`.
- Remains unproven: the live Pi agent session and the full isolated Docker
  evaluator run, which require a paid agent session and the `xsh-factory-base`
  image. That path is inherited unchanged from the approved base image and
  should be exercised at CTO review/approval. No candidate implementation or
  negative-control harness was built, per the eval-designer constraints.

## North-star impact

Hypothesis: an agent that has read the handbook and used `xsht api` should
resolve a single typed `Path` argument into its structural parts
(`parent`, `name`, `ext`) and emit a byte-exact three-line stdout contract
with little exploratory friction. XSH's typed `Path` is one of the explicit
boundaries the north star names ("connect processes, files, paths, streams,
JSON, and system state"), and the handbook already teaches the direct
`Path(str)` cast plus `Path.name()` / `Path.ext()` and the `xsht api` discovery
loop. No approved eval decomposes a path value; `task-pathparts` fills that
gap with the practical `dirname` / `basename` / extension shape that
installers, indexers, and packaging glue reach for daily. A pass is evidence
about learnability and ergonomics of the typed-Path surface, not a
task-specific trick, because hidden cases vary the path shape and a
hard-coded answer or subprocess escape each fail a distinct gate.

## Known risks

- Path edge semantics: `dirname`/`basename` and Rust `Path::parent`/`name`
  diverge on `/` and `..`, and extension semantics differ for hidden dotfiles.
  These cases are excluded from the hidden set, which was verified to agree
  between XSH and the `sh` oracle; a future case added outside that verified
  set could drift.
- The extension contract is defined as "text after the final dot, `none` if
  absent," which matches XSH `Path.ext()`. The oracle's `case "$name" in ?*.*`
  pattern replicates Rust's rule but is subtle; it is pinned by the verified
  hidden set.
- Restriction check requires the source to contain `Path(`. A candidate that
  builds the path textually (e.g., string-splitting the argument) would pass
  correctness for these cases but is flagged as a restriction failure, which is
  the intended anti-hard-code gate.
- No live agent / container run was performed; the Pi agent path and worn
  container boundary are inherited unchanged and unproven here.

## Review path

Promote the proposal package to `evals/task-pathparts/` for CTO review. The
evidence for the approval decision is: the `Draft.` contract (`EVAL.md`),
the `xsht check`-clean package scripts (`executor.xsh`, `evaluator.xsh`,
`evaluate.xsh`), and the `dry-run/DRY-RUN.md` record showing byte-for-byte
agreement between the typed `Path` decomposition and the independent `sh`
oracle on all planned cases. At review, run the inherited Docker evaluator path
against the staged candidate to confirm the orchestrator protocol end-to-end
before setting `Approved.`.
