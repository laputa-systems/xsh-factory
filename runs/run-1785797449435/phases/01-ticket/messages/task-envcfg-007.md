# Controller-assigned engineer ticket

This is an immutable controller assignment for one implementation worker.
The controller, not the worker, selected the ticket, snapshot, worktree, and
branch.

## Assignment authority

- Ticket ID: `task-envcfg-007`
- Ticket snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785797449435/phases/01-ticket/tickets/task-envcfg-007.md`
- Ticket snapshot SHA-256: `1f946ab847d5b9676f154666f7352c18995a64cf9b3edfd310c6062f91659dcd`
- Dedicated XSH worktree: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785797449435/phases/01-ticket/worktrees/task-envcfg-007`
- Branch: `factory/task-envcfg-007/1785797450137`
- XSH base commit: `84fe556cb48feb747d6b575e4925dbdc5848ecdb`
- engineer report: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785797449435/phases/01-ticket/workers/engineer/task-envcfg-007/REPORT.md`
- Factory root: `/Users/josh/d/laputa-systems/xsh-factory`
- Run evidence root: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785797449435/phases/01-ticket`

You are an implementation worker, not a ticket selector. Implement only the
ticket identified above and inlined below. Do not search for open tickets,
choose another ticket, or broaden this assignment. Do not create or modify a
ticket assignment. If the ticket ID, worktree, branch, or snapshot is missing
or conflicts with the runner's `FACTORY_TICKET_ID` or `FACTORY_WORKDIR`, stop
and report the assignment problem; do not guess.

The snapshot path is retained for provenance. The inlined snapshot below is
the controller's authoritative task input, so no ticket-discovery read is
required. Relative links in that snapshot resolve from the factory root above,
not from the XSH product worktree; use exact paths under that root if linked
evidence needs to be consulted.

## Ticket snapshot

<!-- CONTROLLER_TICKET_SNAPSHOT_BEGIN -->
# Ticket task-envcfg-007

## Status

Approved.

## CTO review

- Review cycle: `pre-cycle-1785796761` (2026-08-03)
- Decision: Approved for the next two-engineer ticket cycle.
- Basis: The check-pass/runtime-fail split is reproduced three times, affects
  every compact CLI entry point, and has a small testable acceptance contract
  for check-time feedback plus spread-form regression coverage.
- Assignment boundary: align entry-point validation and diagnostics; preserve
  valid spread-form execution and do not change unrelated `main` effects.

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-envcfg` (`evals/task-envcfg/EVAL.md`)
- Shared handbook lineage: `runs/run-1785789595047/phases/03-eval/lineage/handbook-approved.md` (approved `97c5d804…`; candidate `handbook-candidate.md` with main-spread and `and`/`or` operator notes)
- Manager run: `runs/run-1785789595047/phases/03-eval/workers/eval-manager/task-envcfg/REPORT.md`
- Executor run: `runs/run-1785789595047/phases/03-eval/workers/eval-worker/task-envcfg-1` (trial 1)
- XSH baseline commit: `d2d87d2575c45343abfbcfe378f6ade4065043cf`

## Observation

`xsht check` accepts a `main` entry signature that the runtime cannot run.
Declaring `proc main(argv: List[Str]) [env, error] { ... }` (without the spread
parameter) passes `xsht check` with `rc=0`, but invoking `xsh SCRIPT` fails at
run time with a non-obvious message:

```text
err[runtime.compact-unsupported-main]: proc main could not run in the compact runtime
  /tmp/pi.xsh:1:1
  proc main(argv: List[Str]) [env, error] {
  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```

The error text says nothing about the spread parameter being required, so the
worker spent several discovery iterations (testing `error`-effect removal,
other effect sets, even an empty `[]` main) before realizing the runtime
expects the spread form `main(...argv: List[Str])`. The working signature is
`proc main(...argv: List[Str]) [fs, env, error]`, which the worker confirmed
runs cleanly.

## Evidence

- Worker session: `runs/run-1785789595047/phases/03-eval/workers/eval-worker/task-envcfg-1/session.jsonl.bz2` — turn 36 (`/tmp/pi.xsh` with `main(argv: List[Str]) [env, error]` passes `xsht check` then `xsh` reports `runtime.compact-unsupported-main`), turn 43 (`/tmp/m3.xsh` repeats it), turn 55 (`/tmp/mt.xsh` even with `[]` effects still reports it), turn 58 (worker concludes "The spread `...` is required", runs with spread `[env, error]` and it works).
- Worker review: `runs/run-1785789595047/phases/03-eval/workers/eval-worker/task-envcfg-1/review.md`, section `## XSH language proposals`: "`proc main` must use the spread parameter form `(...argv: List[Str])`. Declaring `main(argv: List[Str])` passes `xsht check` but fails at runtime with `runtime.compact-unsupported-main`, which is a non-obvious link between the entry signature and the chosen runtime."
- Quantitative: trial passed 10/10 (`run.json` `correctness.all_exact: true`, `restrictions.passed: true`), so the gap did not block the eval; it cost the worker roughly turns 36–58 (~20 tool calls / several thinking blocks) to discover the spread requirement.

## Diagnosis or hypothesis

`xsht check` validates types and effects but does not validate the entry-point
shape against the compact runtime that `xsh SCRIPT` actually uses. The
resulting check-pass / run-fail split is a general correctness and ergonomics
defect: an agent writing any CLI entry-point script can get a green `xsht
check`, believe the program is valid, and only learn at run time that the
signature is unusable, with an error message that does not explain why. This is
not an envcfg-specific recipe: every eval that writes a `main` entry point
(task-tags, task-ecount, task-envcfg, and future glue tasks) pays the same
surprise on the first wrong guess. It is distinct from the open task-envcfg-004
ticket (about missing per-type `xsht api` index queries); this ticket is about
the entry-signature check/runtime mismatch.

## North-star impact

The north star asks for clear, learnable boundaries and fewer repeated
discoveries. A checker that reports success for a program the runtime cannot
run undermines trust in the toolchain and forces trial-and-error, exactly the
sludge XSH exists to remove. Fixing it means an agent's `xsht check` result is
a reliable signal for the entry point it will actually run, in every eval.
Evidence of generalization: after the change, any eval's worker that declares
`main(argv: List[Str])` (non-spread) should see `xsht check` reject it with a
constructive message naming the spread form, instead of passing check and
failing only at run time.

## Proposed XSH change

Smallest candidate, one of:

1. Make `xsht check` (or the runtime's static entry validation) reject a non-spread
   `main` parameter with a message like "main must use the spread form
   `(...argv: List[Str])`", so the failure is caught at check time, or
2. Keep the signature valid but improve the runtime message
   `runtime.compact-unsupported-main` to name the expected spread form.

Prefer (1): it moves the failure earlier and makes `xsht check` a trustworthy
gate for entry-point shape.

## Acceptance criteria

- A script declaring `proc main(argv: List[Str])` (single non-spread
  parameter) makes `xsht check` report a clear "use spread form" error rather
  than passing.
- `proc main(...argv: List[Str]) [fs, env, error]` still passes `xsht check`
  and runs under `xsh`.
- A replay of `task-envcfg` on the merged change shows the worker getting
  immediate check-time feedback on the spread requirement (no
  `runtime.compact-unsupported-main` run-time round-trip) and still passes all
  10 correctness cases byte-for-byte.

## Scope and non-goals

- No change to spread-parameter semantics, effects, or the runtime execution
  model.
- Not an envcfg shortcut; the entry-signature validation must apply to any
  `main` in any eval.
- Does not cover per-type `xsht api` index queries (task-envcfg-004) or the
  empty-signature defect (task-ecount-001); those remain separate tickets.

## Post-merge evaluation

The `task-envcfg` eval-manager will run a controlled replay against the merged
XSH commit using the current approved handbook lineage, verify the worker
receives check-time feedback on the spread form instead of a run-time
`compact-unsupported-main` round-trip, confirm all 10 oracle cases still pass,
and record acceptance or rejection in that run's manager report.

<!-- CONTROLLER_TICKET_SNAPSHOT_END -->

## Factory context required before coding

The factory documents below are outside the XSH worktree. Before coding, use
the `read` tool on each exact absolute path. This is required so the session
JSONL proves that the worker consumed the current factory guidance:

- North star: `/Users/josh/d/laputa-systems/xsh-factory/NORTH-STAR.md`
- Shared handbook: `/Users/josh/d/laputa-systems/xsh-factory/runtime/handbook.md`

Then use the `read` tool on the product worktree's exact guidance files:

- Product agent guide: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785797449435/phases/01-ticket/worktrees/task-envcfg-007/AGENTS.md`
- XSH rationale: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785797449435/phases/01-ticket/worktrees/task-envcfg-007/docs/CHAPTER-01-why-xsh.md`

## Implementation contract

Work only in `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785797449435/phases/01-ticket/worktrees/task-envcfg-007` on branch `factory/task-envcfg-007/1785797450137`. Do not edit XSH main, the
factory main tree, or the ticket diagnosis. Make the smallest general XSH
language, tooling, test, or canonical-documentation change supported by the
ticket. Run the narrowest relevant checks, commit the product change on this
branch, and leave the worktree clean.

The controller has staged a fail-closed `not-ready` report at
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785797449435/phases/01-ticket/workers/engineer/task-envcfg-007/REPORT.md`. Complete that file in place; do not spend turns
reconstructing its headings. Keep `## Result` as `not-ready` until the
acceptance checks, commit, and clean-worktree validation are complete.

Write `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785797449435/phases/01-ticket/workers/engineer/task-envcfg-007/REPORT.md` with these exact headings:

```markdown
## Result

ready-for-review

## Branch

<branch name>

## Commit

<commit hash>

## Files changed

<short list>

## Tests

<commands and results>

## North-star impact

<how this improves XSH or agent use>

## Remaining risks

<known limitations, or None.>
```

Change `## Result` to `ready-for-review` only when the branch is committed, the worktree is
clean, and the relevant checks passed. Do not merge the branch or update the
ticket status; the deterministic controller records it for CTO review.
