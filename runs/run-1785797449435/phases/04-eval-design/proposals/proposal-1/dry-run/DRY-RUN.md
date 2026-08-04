# task-renamex dry run

Run: `runs/run-1785797449435/phases/04-eval-design/proposals/proposal-1/dry-run/`

## What was exercised

- The reference XSH solution (`dry-run/renamex.xsh`) uses the recursive
  `fs.files` stream, a `Str.ends_with(".tmp")` filter, `fp` path interpolation
  for the destination, and `fs.rename(src, dest, overwrite: true)` — the
  intended handbook path for a mutation workflow. It passes `xsht check`,
  `xsht fmt`, and `xsht lint` with no advisory warnings.
- The package-owned `evaluator.xsh` was run on the host via the
  `WORK_DIR` / `SESSION_DIR` / `EXPORT_DIR` overrides (defaults `/work`,
  `/session`, `/export` preserve the container contract) against the reference
  solution and a correctly filled `review.md`. It produced a passing manifest
  (`dry-run/run.json`) with `classification: pass` and every case exact —
  including the two-directory tree comparison and the crediting of timings.
- Cases exercised: `public`, `hidden_nested`, `hidden_dotname`,
  `hidden_no_suffix`, `hidden_empty`, and `hidden_missing` (failure control).
  Each candidate tree was compared byte-for-byte against the BusyBox `sh`
  oracle's tree.

## Negative controls

Each was rejected with the intended classification (see `dry-run/controls.md`):

- subprocess escape (`process.` / `run` / `mv`) -> `restriction_failed`;
- a print-only solution without `fs.rename` -> `restriction_failed`;
- a rename to the wrong target extension -> `candidate_failed`;
- a missing `/work/review.md` -> `protocol_failed`.

## What remains unproven

- The agent half (a live Pi worker) was not exercised: it requires a paid
  agent session and a Pi auth file and is not part of this proposal's scope.
  The worker entry point is inherited unchanged from the approved base image.
- The container image build / mount of the staged package was not run; host
  overrides prove the evaluator logic, and the `/work`, `/session`, `/export`
  defaults rely on the standard eval container contract used by every existing
  eval.
