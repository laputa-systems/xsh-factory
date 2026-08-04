# Eval-designer report

## Result

ready-for-review

## Proposal

New eval `task-manifest` staged under
`runs/run-1785800291944/phases/02-eval-design/proposals/proposal-1/`:

- `EVAL.md` — contract, north-star hypothesis, agent boundary, oracle and
  evaluator, metrics, manager policy, staged dry-run record (Status `Draft.`)
- `runtime/task.md`, `runtime/artifact.md` (`manifest.xsh`)
- `evaluator.xsh` — package-owned (self-contained) evaluator, no branch added
  to `evaluate_common.xsh` / `evaluate_legacy.xsh`
- `executor.xsh`, `evaluate.xsh` — selectors retargeted from `task-tags` to
  `task-manifest`
- `dry-run/` — reference solution, oracle, negative-control inputs, `run.json`
  manifests, and `DRY-RUN.md`

The scaffold's `task-tags` title/ID were replaced with the valid new
`task-manifest` (not present under `evals/`) and `Disabled.` was changed to
`Draft.` before any API query or dry run.

## Dry run

Exercised inside the pinned Alpine 3.24.1 container with the `.dist` binaries:
the reference `manifest.xsh` passed `xsht check` / `lint` (and `fmt` is
idempotent), and the evaluator produced `classification: pass` with all 8
cases byte-exact, including the `hidden_missing_root` failure control
(candidate exits 3, no `OUT`; guarded oracle exits 1). Five negative controls
were each rejected with the intended classification: `restriction_failed`
(hard-coded listing; subprocess escape), `candidate_failed` (wrong output),
`protocol_failed` (broken `review.md`), `worker_missing_artifact` (missing
artifact). Two scaffold bugs were found and fixed during the dry run
(`List.is_empty` → `len() == 0`; oracle pipeline masked `find`'s exit).
Remaining unproven: the live Pi agent half (needs a paid session/Pi auth) and
the host-to-container integration of the controller dispatcher, which is
unchanged for this eval and is checked at the first paid trial.

## North-star impact

`task-manifest` probes whether a handbook-trained agent can, with little
friction, replace the classic `find ROOT -type f | sort` packaging/index
pipeline with a typed XSH composition: recursive file discovery
(`fs.files`/`fs.walk`), relative-path computation (`Path.relative_to` /
`strip_prefix`), deterministic stream ordering (`sort-by`), and byte-exact
`fs.write` output, while failing a missing root loudly instead of leaving a
partial file. This is a practical systems-glue capability (generating file
manifests/indexes for packages, backups, release lists) that no current eval
covers — a successful run teaches whether traversal + path-relative + stream
sorting compose and are discoverable, i.e. the handbook's explicit-boundary
and composability promises hold for a real packaging shape. The design
resists task-specific hacks because hidden cases vary tree shape, names
(spaces, UTF-8), empty trees, and the missing-root failure control, and
because distinct gates reject hard-coded listings, subprocess escapes, broken
protocol, and missing artifacts.

## Known risks

- **Oracle/`find` exit masking:** the pipeline's exit status came from `sort`
  even when `find` failed on a missing root; fixed with an explicit existence
  guard in the oracle. The documented oracle in `task.md`/`EVAL.md` now
  matches the evaluator.
- **Trailing-newline edge:** the empty-tree case requires an explicit
  `len() == 0` guard so `OUT` is zero bytes; the reference implements it and
  the oracle agrees.
- **Integration gap:** the package-owned evaluator was invoked directly in the
  container; the controller's staging/mount path for a new eval is validated
  only at the first paid trial (as with `task-col2`).
- **Live-agent friction untested:** worker-side discovery of `fs.files` /
  `Path.relative_to` / `sort-by` and `review.md` completion are not exercised
  here; they are the point of the eval and only a paid trial observes them.
- **Timing:** `fs.files` with `stat: true` (default) is slower than the oracle;
  timings are recorded as diagnostic only, with no timing gate, consistent
  with the other evals.

## Review path

Promote `runs/run-1785800291944/phases/02-eval-design/proposals/proposal-1/`
to `evals/task-manifest/` (EVAL.md, runtime/, evaluator.xsh, executor.xsh,
evaluate.xsh). Evidence for the CTO decision: `dry-run/DRY-RUN.md`, the passing
`dry-run/session/run.json` (all 8 cases, `classification: pass`), the negative
controls under `dry-run/s{control}/run.json` with their intended
classifications, and the `dry-run/export/manifest.xsh` artefact copy. The
evaluator is package-owned and adds no branch to `evaluate_common.xsh`, so
this package does not disturb the approved evals or the shared handbook. The
CTO should set `Approved.` if it accepts the contract and dry-run evidence;
otherwise the package stays `Draft.` and is not admitted to paid work.
