# Eval-designer report

## Result

ready-for-review

## Proposal

Staged proposal package (Draft., eval id `task-findexec`):
`runs/run-1785804030340/phases/04-eval-design/proposals/proposal-1/`

- `EVAL.md` — north-star hypothesis, task prompt, agent boundary, oracle and
  evaluator, metrics, manager policy, staged dry-run record.
- `runtime/task.md` — user-facing task contract and acceptance oracle.
- `runtime/artifact.md` — required artifact `findexec.xsh`.
- `executor.xsh` / `evaluator.xsh` — selectors rewritten from the `task-tags`
  scaffold to reference `task-findexec`; `evaluate.xsh` is the unchanged
  generic evaluator selector.
- `dryrun/` — materialized evidence for the CTO review.

The `task-tags` title/ID were replaced with `task-findexec` and `Disabled.`
with `Draft.` before any dry run. No `task-tags` or `Disabled.` reference
remains in the package.

## Dry run

The dry run ran the intended solution (`findexec-solution.xsh`, staged under
`dryrun/`) inside the pinned gym base image
(`xsh-factory-base:cto-check`) and compared stdout byte-for-byte with the
BusyBox oracle `find "$ROOT" -type f -perm -u+x | sort` on representative
fixtures. All three cases passed:

1. **Mixed fixture** — nested dirs, hidden dotfiles (`.hidden`, `.hdir/.deep`),
   owner-executable (755/700), group-only (070), other-only (007), and
   non-executable (644) files, a symlink-to-file and a symlinked directory.
   Candidate and oracle matched exactly; both included the hidden owner-
   executable files, excluded group/other-only and non-executable files, and
   excluded the symlinks without descending the symlinked directory.
2. **Negative control** — a tree with no owner-executable files; both produced
   empty stdout.
3. **Single-result** — one owner-executable file at the root; both emitted the
   one path.

The solution also passes the task's recommended dev loop in-gym:
`xsht check` OK, `xsht fmt` exit 0, `xsht lint` exit 0 (one informational
`path-constructor` warning on the required `Path(argv[0])` runtime cast), and
`xsh findexec-solution.xsh /usr/share` produced `/usr/share/udhcpc/default.script`.

Proven: the typed-stream metadata contract (`owner_executable`, `kind`) and the
`hidden: true` option reproduce the external oracle byte-for-byte; the
staged selectors reference only `task-findexec`; no extra image utility is
needed (BusyBox find is in the base image). Not directly exercised here: the
paid evaluator harness (a controller-owned boundary) and the live agent session;
these are decided by the CTO review and the first trial.

## North-star impact

This eval probes XSH's typed metadata boundary — a capability no current eval
covers: fetching a tree with the fs stream API, trusting a typed permission
field (`owner_executable`) over a guessed name, and finding the `hidden: true`
option so the result matches the oracle's dotfile set. It is the XSH analogue
of the classic sysadmin "list executable files in a tree"
(`find -type f -perm -u+x | sort`). A successful run teaches whether the
handbook/API make filesystem metadata fields and stream options discoverable
and composable, and whether an agent avoids a subprocess fallback to `find`.
The owner/group/other distinction plus a hidden-file fixture raise the failure
bar above a trivial "is-executable" or hard-coded listing, so evidence points
at general ergonomics rather than a task trick.

## Known risks

- **Hidden-file default**: `fs.files` skips dotfiles unless `hidden: true`, so
  an agent that does not read the stream options will fail the hidden-file
  fixture. This is intended as a correctness dimension, but could surface as a
  repeated handbook need; the manager should classify it as generalizable
  guidance ("include dotfiles via `hidden: true`") only after a replay.
- **Oracle portability**: the oracle relies on BusyBox `find -perm -u+x`
  semantics (owner-execute bit). Verified working on the gym base image; it
  should stay pinned to that base. The evaluator supplies a controlled fixture
  rather than ambient `/usr/share`, which has only one executable and would
  make the case vacuous.
- **Path-string contract**: byte-exact output depends on emitting the full
  root-prefixed path string as `find` does; the dry run confirmed identical
  output but `Path(...)` casts carry an informational lint warning that must
  not be treated as an error.
- **Missing checks**: the in-container evaluator subprocess-restriction scan
  and review-heading check are harness-owned and were not re-run here; they are
  the same shared mechanism used by the other approved evals.

## Review path

Promoted eval path on approval: `evals/task-findexec/` (new id, verified absent
under `evals/`). Evidence for the CTO decision: the staged package at
`runs/run-1785804030340/phases/04-eval-design/proposals/proposal-1/`, the
in-image byte-for-byte oracle matches in `dryrun/dryrun.log` (plus
`oracle*.txt`/`cand*.txt`), the passing `xsht check/fmt/lint` in the dev loop,
and this report. The CTO promotes the package and decides `Approved.` vs
`Draft.`; this proposal remains `Draft.` pending that review.
