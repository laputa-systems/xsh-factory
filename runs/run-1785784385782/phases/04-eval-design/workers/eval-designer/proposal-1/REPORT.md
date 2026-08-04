# Eval-designer report

## Result

ready-for-review

## Proposal

- Proposal package: `runs/run-1785784385782/phases/04-eval-design/proposals/proposal-1/`
  - `EVAL.md` (task contract, agent boundary, oracle, hidden cases, metrics,
    manager policy, staged dry-run record)
  - `runtime/task.md`, `runtime/artifact.md` (deliverable `bigfiles.xsh`)
  - `executor.xsh`, `evaluator.xsh`, `evaluate.xsh` (task-bigfiles selector
    over the shared scaffold)
  - `dry-run/bigfiles.xsh` (reference solution), `dry-run/DRY-RUN.md` (evidence)
- New eval ID `task-bigfiles`; the staged `task-tags` title/ID were replaced
  and `Disabled.` changed to `Draft.` before any dry run. No reference to the
  retired `task-tags` remains in the package.
- On approval, the CTO promotes this package to `evals/task-bigfiles/`; the
  package-owned `evaluator.xsh` plugs into the existing generic evaluator
  protocol with no new task branch in shared controllers.

## Dry run

Exercised on the host with the cycle's `xsh`/`xsht` build:
- Reference solution passes `xsht check`, `fmt`, and `lint` (lint exit 0).
- Candidate vs the external `sh`/`find`/`wc`/`sort`/`head` oracle, compared
  byte-for-byte, on all nine `EVAL.md` cases: `public`, `hidden_default`,
  `hidden_n2`, `hidden_single`, `hidden_deep`, `hidden_spaces`, `hidden_utf8`,
  `hidden_empty` (all PASS) and the `hidden_bad_n` failure control (both
  candidate and oracle exited nonzero with empty output). Full transcript in
  `dry-run/DRY-RUN.md`.

Remaining unproven this cycle:
- The container isolation boundary and the package-owned `evaluator.xsh`
  protocol, whose paths (`/usr/local/lib/xsh-factory/...`) are container-only.
  These are inherited unchanged from the approved scaffold; this proposal only
  changed the selected task ID.
- A live Pi worker session (requires a paid agent session and auth file); the
  agent admission and worker path are inherited from the approved base image.
- The shared evaluator's source-level restriction scan (rejects `run`/`process`
  /`spawn`/shell escapes; requires an `fs.files`/`fs.walk` plus `sort-by`
  reference) was not re-run end-to-end in a container here.

## North-star impact

Capability hypothesis: does an agent with the handbook compose the typed
filesystem stream API into a real ranked-report workflow — walk a tree, sort
files by a numeric attribute descending, truncate to a top-N, and print a
byte-exact `<size> <path>` line — without a subprocess escape or a hard-coded
answer? This is the modern XSH analogue of the classic Unix
`find | sort -S | head` disk-hygiene glue and covers a boundary no approved
eval does (ecount groups/counts extensions; envcfg renders scalar config;
setdiff diffs line sets; jsonfilter crosses JSON; probe owns subprocesses).

A successful trial teaches the factory whether numeric stream ordering
(`sort-by` on a per-file size with a negated key, since this build has no
reverse/descending stage, plus a runtime-count `take`) is discoverable from the
handbook, and whether the Result / postfix-`?` idiom transfers to a
malformed-count failure. Evidence for a general capability (not a hack) comes
from varying tree depth, count, naming (spaces, UTF-8) and an empty result, and
from the explicit failure control.

## Known risks

- Ordering determinism: fixtures must keep file byte sizes unique within a
  tree, or `sort-by`'s equal-key order can diverge from the oracle's. The
  contract and fixtures guarantee unique sizes; documented as a fixture
  invariant.
- Oracle portability: `wc -c` padding differs by host, so the oracle
  normalizes sizes with shell arithmetic (`size=$(($(wc -c < f)))`) before
  `printf`, removing host/vendor padding from the compared bytes.
- `reverse`/descending API absence: the build exposes no descending sort
  stage, so the reference uses a negated integer key. A future build change
  could alter the idiomatic solution; the oracle remains the truth.
- Missing checks: no live worker session or in-container evaluator run this
  cycle; the report marks these as unproven rather than claimed.
- Hard-coded / escape / silent-default hacks each fail a distinct evaluator
  gate (restriction scan + failure control), but those gates are enforced by
  shared evaluator code not re-run end-to-end here.

## Review path

Promoted eval path on approval: `evals/task-bigfiles/` (EVAL.md, runtime/,
executor.xsh, evaluator.xsh, evaluate.xsh).

Evidence for the CTO approval decision:
- `proposals/proposal-1/EVAL.md` — full contract, oracle, hidden cases,
  metrics, manager policy, and dry-run record;
- `proposals/proposal-1/dry-run/DRY-RUN.md` — host transcript: reference
  solution passes check/fmt/lint and byte-matches the oracle on 8 passing
  cases plus the failure control (both nonzero, empty);
- `proposals/proposal-1/executor.xsh` and `evaluator.xsh` — task-bigfiles
  selector over the shared scaffold; no `task-tags` collision remains.
