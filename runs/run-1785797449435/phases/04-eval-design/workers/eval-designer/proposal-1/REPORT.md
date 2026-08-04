# Eval-designer report

## Result

ready-for-review

## Proposal

A new eval proposal, `task-renamex`, staged under
`runs/run-1785797449435/phases/04-eval-design/proposals/proposal-1/` with the
complete task package:

- `EVAL.md` — contract, north-star hypothesis, agent boundary, oracle and
  evaluator, metrics, manager policy, and staged dry-run record (`Status:
  Draft.`).
- `runtime/task.md`, `runtime/artifact.md`, `runtime/review.md`.
- `executor.xsh`, `evaluate.xsh` — thin selectors updated to the `task-renamex`
  id.
- `evaluator.xsh` — package-owned, self-contained evaluator (no shared-module
  branch).
- `dry-run/` — reference solution, passing `run.json`, negative-control
  record, and `DRY-RUN.md`.

The scaffold was renamed from the retired `task-tags` id to the new valid
`task-renamex` id (no collision under `evals/`) and its status moved from
`Disabled.` to `Draft.` before any API query or dry run.

## Dry run

Exercised on the host through the evaluator's `WORK_DIR` / `SESSION_DIR` /
`EXPORT_DIR` overrides (defaults `/work`, `/session`, `/export` match the eval
container contract):

- The reference `renamex.xsh` (recursive `fs.files` + `Str.ends_with` filter +
  `fp` destination + `fs.rename(overwrite: true)`) passes `xsht check`, `fmt`,
  `lint` with no warnings and matches the BusyBox `sh` oracle on all six
  cases.
- The staged `evaluator.xsh` produced a passing manifest
  (`classification: pass`) on a host dry run; every case was exact, including
  the two-tree comparison and the failure control.
- Negative controls all classified as intended: subprocess escape and
  no-`fs.rename` -> `restriction_failed`; wrong-target rename ->
  `candidate_failed`; missing `review.md` -> `protocol_failed`.

Remaining unproven: the live Pi agent path (requires a paid session + Pi auth,
out of scope here) and the container image mount of the staged package. Both
are inherited unchanged from the approved eval base image.

## North-star impact

XSH's mission is to make host work visible as typed APIs and reject shell
sludge. Every existing eval reads or writes one thing; none exercises the
filesystem *mutation* boundary (`fs.rename`). `task-renamex` probes whether an
agent can discover the recursive `fs.files` stream, filter by a Str suffix,
build a destination path with `fp` interpolation, and perform a rename with an
explicit overwrite policy — the classic housekeeping shape "rename every
`*.tmp` to `*.bak`" without a `find | mv` subprocess escape. A successful run
teaches whether the filesystem write surface is discoverable and whether the
path-cast guidance transfers to a mutation workflow. The design resists
task-specific hacks because hidden cases vary file placement (flat, nested,
dot-names, none) and because four distinct negative controls each fail a
different gate.

## Known risks

- **Task-specific hacks:** a hard-coded file list fails every case; the
  subprocess escape and print-only variants are caught by the `restriction`
  gate, and the wrong-target variant by `candidate_failed`.
- **Oracle parity:** the oracle and reference both replace the single `.tmp`
  suffix; fixtures deliberately avoid names with repeated `.tmp` so the simple
  `Str.replace` semantics and the shell `${f%.tmp}.bak` agree.
- **Timing:** both sides finish in milliseconds; timing is diagnostic only,
  with no strict envelope.
- **Missing checks:** the agent half and container-image mount were not
  exercised (paid session + Pi auth; standard worker path inherited). The
  resumed run relies on `/work`, `/session`, `/export` defaults matching the
  eval container contract used by all existing evals.

## Review path

Promotion target: `evals/task-renamex/` (the CTO grafts the staged package
there and immediately reviews it; per FACTORY.md the package is promoted and
set to `Approved.` only when the evaluator and this evidence pass).

Evidence for the CTO decision:
- `proposals/proposal-1/EVAL.md` (contract, oracle, cases, policy).
- `proposals/proposal-1/evaluator.xsh` (self-contained evaluator, `xsht check`
  clean).
- `proposals/proposal-1/dry-run/run.json` — passing manifest,
  `classification: pass`, all six cases exact.
- `proposals/proposal-1/dry-run/controls.md` — the four negative controls
  rejected with the intended classifications.
- `proposals/proposal-1/dry-run/DRY-RUN.md` — what was and was not exercised.
- `proposals/proposal-1/dry-run/renamex.xsh` — the reference solution.

The proposal remains `Draft.`; the CTO review gate decides whether it becomes
`Approved.` or stays `Draft.`.
