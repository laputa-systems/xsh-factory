# Controller-assigned engineer ticket

This is an immutable controller assignment for one implementation worker.
The controller, not the worker, selected the ticket, snapshot, worktree, and
branch.

## Assignment authority

- Ticket ID: `task-ecount-006`
- Ticket snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785804030340/phases/01-ticket/tickets/task-ecount-006.md`
- Ticket snapshot SHA-256: `b394f0387c4b80526b898f87bb09e6d65a3d1739a8e79c83f75ee3df16a790b4`
- Dedicated XSH worktree: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785804030340/phases/01-ticket/worktrees/task-ecount-006`
- Branch: `factory/task-ecount-006/1785804031017`
- XSH base commit: `5cee79306e2ce8c12fbd5b8575ff7accfcc5c82f`
- engineer report: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785804030340/phases/01-ticket/workers/engineer/task-ecount-006/REPORT.md`
- Factory root: `/Users/josh/d/laputa-systems/xsh-factory`
- Run evidence root: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785804030340/phases/01-ticket`

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
# Ticket task-ecount-006

## Status

Approved.

## CTO review

- Review cycle: `pre-cycle-1785803972` (2026-08-03)
- Decision: Approved for the next two-engineer ticket cycle.
- Basis: The direct module-stream `collect()` failure remains a reproducible
  checker/runtime compiler boundary on current XSH HEAD and is independently
  actionable even if it shares code with `task-ecount-002`.
- Assignment boundary: Make `fs.files(...) |> collect()` compile and run, or
  replace the internal IR blocker with a source-local diagnostic; preserve
  transformed-stream behavior and do not broaden into unrelated stream work.

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-ecount` (`evals/task-ecount/EVAL.md`)
- Shared handbook lineage: `runs/run-1785723986829/phases/03-eval/lineage/handbook-approved.md` (approved `c7c9dd9a…`; candidate `handbook-candidate.md`)
- Manager run: `runs/run-1785723986829/phases/03-eval/workers/eval-manager/task-ecount/session.jsonl.bz2`
- Executor run: `runs/run-1785723986829/phases/03-eval/workers/eval-worker/task-ecount-1` (trial 1)
- XSH baseline commit: `ea7dea2f2b436cce34262d7a02105cbb029243dd`

## Observation

Collecting a lazy filesystem stream directly from a module function — without
any transformation stage — fails compilation with a cryptic internal IR error,
even though the handbook documents `collect` as the standard terminal for a
lazy stream. Adding any transformation stage (`where`/`map`) before `collect()`
makes the identical program compile and run.

On the pinned image (XSH commit `ea7dea2`, `xsh-factory-task-ecount`):

```text
$ cat probe1.xsh
proc main() [fs, error] {
  let files = fs.files(p"/usr/share")?
  let all = files |> collect()
  print $all.len()
}
$ xsh probe1.xsh
err[compact.indexed-build]: indexed IR could not encode `full_ir_function_blocker`
  /tmp/probe.xsh:1:25
  proc main() [fs, error] {
                          ^ indexed IR could not encode `full_ir_function_blocker`

$ cat probe2.xsh
proc main() [fs, error] {
  let files = fs.files(p"/usr/share")?
  let all = files |> where .kind == "file" |> map { |e| e.path } |> collect()
  print $all.len()
}
$ xsh probe2.xsh
138
```

The error also occurs without `?` (`proc main() [fs] { let files = fs.files(...); let all = files |> collect(); ... }` fails the same way), so it is not the error-propagation path; it is the raw `collect()` of the module-produced stream.

## Evidence

- Worker session: `runs/run-1785723986829/phases/03-eval/workers/eval-worker/task-ecount-1/session.jsonl.bz2` — six occurrences of `err[compact.indexed-build]: indexed IR could not encode 'full_ir_function_blocker'` (tool results around lines 25–41); the controlled A/B probe (probe1 fails / probe2 prints `138`) isolates the trigger to the direct `|> collect()` with no preceding transformation stage.
- Worker review: `runs/run-1785723986829/phases/03-eval/workers/eval-worker/task-ecount-1/review.md`, section `## xsht friction` — "`fs.files(path)?` immediately followed only by `|> collect()` fails compilation with an internal error `compact.indexed-build: indexed IR could not encode 'full_ir_function_blocker'`. Adding any transformation stage (`where`/`map`) before `collect()` makes it compile. A misleading internal IR error instead of a useful message."
- Handbook contract: `runs/run-1785723986829/phases/03-eval/lineage/handbook-approved.md`, Streams and collections section — "The pipeline result is a lazy stream until a terminal such as collect is applied", making `module_stream |> collect()` the documented minimal pattern.

## Diagnosis or hypothesis

`compact.indexed-build: indexed IR could not encode 'full_ir_function_blocker'` is an internal compiler diagnostic leaking to the user for a program the handbook explicitly documents. The identical error text appears in open ticket `task-ecount-002` for a different trigger (positional optional arguments on `fs.files`/`fs.walk`); the two observations may share a root cause in the indexed-IR builder's handling of a module call whose result feeds a terminal directly. Regardless of shared root cause, each trigger is independently user-visible: agents following the handbook's stream example hit this on their first working program and spend several turns bisecting effects and stage order before discovering that any transformation stage works around it. This is a general ergonomics/correctness problem for any XSH program that consumes a module stream, not task-specific confusion.

## North-star impact

The handbook teaches `collect` as the terminal that materializes a lazy stream; the first program an agent writes from that guidance breaks with an internal IR error and no actionable message. Fixing this removes a misleading diagnostic, makes the documented pattern actually compile, and reduces wasted discovery turns for every filesystem/stream eval. Evidence of generalization: the same `fs.files(...) |> collect()` minimal program should compile (or produce a human-readable stage/type error) on any future stream task, and the worker session's A/B probe should become a regression test.

## Proposed XSH change

Investigate the `compact.indexed-build` path for a module-function stream piped directly into a terminal (no intervening transformation stage) and either (a) make it compile, or (b) replace the internal blocker message with the real type/stage diagnostic. Check whether the same indexed-IR blocker covers open ticket `task-ecount-002` (positional optional arguments) and fix both triggers in one root-cause fix if they share it. Add a regression test using the minimal `fs.files(p"/usr/share") |> collect()` program.

## Acceptance criteria

- `xsh` compiles and runs `fs.files(root) |> collect()` (with and without `?`, with `[fs]`/`[fs, error]` effects) and prints the expected count, OR `xsht check`/`xsh` reports a specific, actionable diagnostic at the offending statement (not `compact.indexed-build`).
- The two-line probe1 above no longer emits `full_ir_function_blocker`; it either runs or names the actual problem.
- `xsht check` and `xsh` agree on this program (no checker-accepts/runtime-fails split).
- Replay of `task-ecount` still passes byte-for-byte with the fix in place.

## Scope and non-goals

- Does not include redesigning `collect` or the stream terminal semantics.
- Does not include fixing the separate stream-stage signature gap (open ticket `task-ecount-001`), the positional-optional-argument trigger (open ticket `task-ecount-002`), or `sort-by` behaviors (open/approved tickets `task-ecount-003`/`004`), except where they share the same `compact.indexed-build` root cause and are fixed together.
- Handbook text is not changed here; a candidate idiom note lives in the run lineage `handbook-candidate.md`.

## Post-merge evaluation

The next `task-ecount` eval-manager replay (`runs/run-1785723986829/phases/03-eval` lineage, updated to the implementation commit) must confirm probe1 compiles or yields a real diagnostic, and that the full eval still passes byte-for-byte with the same oracle.

<!-- CONTROLLER_TICKET_SNAPSHOT_END -->

## Factory context required before coding

The factory documents below are outside the XSH worktree. Before coding, use
the `read` tool on each exact absolute path. This is required so the session
JSONL proves that the worker consumed the current factory guidance:

- North star: `/Users/josh/d/laputa-systems/xsh-factory/NORTH-STAR.md`
- Shared handbook: `/Users/josh/d/laputa-systems/xsh-factory/runtime/handbook.md`

Then use the `read` tool on the product worktree's exact guidance files:

- Product agent guide: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785804030340/phases/01-ticket/worktrees/task-ecount-006/AGENTS.md`
- XSH rationale: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785804030340/phases/01-ticket/worktrees/task-ecount-006/docs/CHAPTER-01-why-xsh.md`

## Implementation contract

Work only in `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785804030340/phases/01-ticket/worktrees/task-ecount-006` on branch `factory/task-ecount-006/1785804031017`. Do not edit XSH main, the
factory main tree, or the ticket diagnosis. Make the smallest general XSH
language, tooling, test, or canonical-documentation change supported by the
ticket. Run the narrowest relevant checks, commit the product change on this
branch, and leave the worktree clean.

The controller has staged a fail-closed `not-ready` report at
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785804030340/phases/01-ticket/workers/engineer/task-ecount-006/REPORT.md`. Complete that file in place; do not spend turns
reconstructing its headings. Keep `## Result` as `not-ready` until the
acceptance checks, commit, and clean-worktree validation are complete.

Write `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785804030340/phases/01-ticket/workers/engineer/task-ecount-006/REPORT.md` with these exact headings:

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
