# Controller-assigned engineer ticket

This is an immutable controller assignment for one implementation worker.
The controller, not the worker, selected the ticket, snapshot, worktree, and
branch.

## Assignment authority

- Ticket ID: `task-envcfg-005`
- Ticket snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785783248621/phases/01-ticket/tickets/task-envcfg-005.md`
- Ticket snapshot SHA-256: `8896d83b259bb84a163c68696aab6e71242f56811d2611992ef6fb7118f5ce23`
- Dedicated XSH worktree: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785783248621/phases/01-ticket/worktrees/task-envcfg-005`
- Branch: `factory/task-envcfg-005/1785783248954`
- XSH base commit: `51b035a705f856d0bd3ead3cddf1557523d1d30e`
- engineer report: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785783248621/phases/01-ticket/workers/engineer/task-envcfg-005/REPORT.md`
- Factory root: `/Users/josh/d/laputa-systems/xsh-factory`
- Run evidence root: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785783248621/phases/01-ticket`

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
# Ticket task-envcfg-005

## Status

Approved.

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-envcfg` (`evals/task-envcfg/EVAL.md`)
- Shared handbook lineage: `runs/run-1785781082105/phases/01-eval/lineage/handbook-approved.md` (approved `c7c9dd9a…`; candidate `c7c9dd9a…` with one added Environment section)
- Manager run: `runs/run-1785781082105/phases/01-eval/workers/eval-manager/task-envcfg/REPORT.md`
- Executor run: `runs/run-1785781082105/phases/01-eval/workers/eval-worker/task-envcfg-1` (trial 1)
- XSH baseline commit: `51b035a705f856d0bd3ead3cddf1557523d1d30e`

## Observation

A stream-stage closure that contains a `let` binding fails to compile in the
gym compact runtime with the opaque error `err[compact.indexed-build]:
indexed IR could not encode 'full_ir_function_blocker'`, while the identical
closure written as a single expression compiles. The task-envcfg worker needed
a strict decimal check on `CFG_PORT` bytes and repeatedly hit this blocker
(probes `/tmp/dig3.xsh`, `/tmp/dig4.xsh`, `/tmp/s3.xsh`, `/tmp/s4.xsh`) before
discovering that only single-expression closures are encoded:

```text
$ xsht check /tmp/dig3.xsh
err[compact.indexed-build]: indexed IR could not encode `full_ir_function_blocker`
  /tmp/dig3.xsh:1:32
  pure is_digits(s: Str) -> Bool {
                                 ^ indexed IR could not encode `full_ir_function_blocker`
```

The failing closure form (multi-statement with a local binding):

```text
range(0, n) |> all { |i| let b = s.byte_at(i, -1); b >= 48 and b <= 57 }
```

The single-expression workaround that compiles and that the shipped candidate
uses:

```text
range(0, n) |> all { |i| s.byte_at(i, -1) >= 48 and s.byte_at(i, -1) <= 57 }
```

The single-expression form re-evaluates `byte_at` and is more verbose; the
agent reached it only after several failed probes and documented it in
`review.md` as a language blocker.

## Evidence

- Worker session: `runs/run-1785781082105/phases/01-eval/workers/eval-worker/task-envcfg-1/session.jsonl.bz2` — structured tool errors at turns 69 and 70 (both `full_ir_function_blocker` on the closure-with-`let` form); worker thinking blocks ~48–64 show it isolating the trigger (capturing a `Str` works, multi-statement closure with `let` does not) and confirming the single-expression closure compiles.
- Worker review: `runs/run-1785781082105/phases/01-eval/workers/eval-worker/task-envcfg-1/review.md`, section `## XSH language proposals` — "Stream-stage blocks containing a `let` fail to compile with `indexed IR could not encode full_ir_function_blocker` … Only single-expression closures are encoded."
- Worker report: `runs/run-1785781082105/phases/01-eval/workers/eval-worker/task-envcfg-1/report.json` (9 tool errors; the two closure-`let` probes are among them).
- Quantitative metrics: trial passed all ten cases; 95 assistant turns, 96 tool calls, 9 tool errors, 74 thinking blocks, $0.0762.

## Diagnosis or hypothesis

This is a distinct trigger of the same compact-IR limitation documented in
`task-ecount-002` (positional optional-argument calls). There the blocker
surfaced on the `proc main` signature line for a positional optional argument;
here it surfaces at the closure body when a stream-stage closure binds a local
with `let`. Both are the `full_ir_function_blocker` path in the compact
indexed IR, but the user-facing condition (closure statements beyond a single
expression) is not covered by `task-ecount-002`'s scope, which explicitly
excludes stream-stage/closure semantics. This is a general ergonomics/correctness
defect: any agent writing a stream-stage closure that needs a local binding
hits an opaque IR error instead of a clear parse/type message, and incurs
repeated failed probes before discovering the single-expression restriction.

## North-star impact

The north-star goal is explicit, learnable boundaries and fewer repeated
discoveries. A stream closure is a core composition idiom; silently limiting
it to single-expression bodies forces agents to either flatten logic into one
expression or fall back to re-evaluated method calls, obscuring the real
language boundary. Making a multi-statement closure compile (or, if
intentionally unsupported, emitting a clear "closure bodies in this build may
contain only one expression" diagnostic that names the construct) would let an
agent write digit/range validation simply and trust that the compact runtime
matches the handbook. Evidence of generalization: any eval using a stream
closure with a local binding would compile or receive a readable message.

## Proposed XSH change

Smallest candidate, one of:

1. Support multi-statement stream-stage closure bodies (with local `let`
   bindings) in the compact indexed IR so
   `range(0, n) |> all { |i| let b = s.byte_at(i, -1); b >= 48 and b <= 57 }`
   compiles and behaves identically to the single-expression form; or
2. If multi-statement closures are intentionally unsupported in the compact
   runtime, emit a diagnostic that names the construct (e.g. "closure body in
   this build must be a single expression; hoist the `let` binding out of the
   closure") instead of `full_ir_function_blocker`.

No change to single-expression closure semantics.

## Acceptance criteria

- `xsh` (and `xsht check`) either accepts the multi-statement closure form or
  rejects it with a readable message naming the closure/local-binding
  construct, with a correct exit status and no `full_ir_function_blocker`
  text.
- A single-expression closure over the same stream still compiles and yields
  identical results.
- Applies to at least `all`/`filter`-style stream stages with a local binding,
  not just the envcfg digit check.
- `xsht api language:stream` text matches the actually accepted closure forms.

## Scope and non-goals

- No change to stream runtime sequencing or result semantics for the accepted
  single-expression form.
- Not an envcfg shortcut; the diagnostic or support must generalize to stream
  closures generally.
- Distinct from `task-ecount-002` (positional optional-argument calls); if the
  fixed root cause is confirmed common, the two tickets may be reconciled by
  the CTO but each must keep its acceptance criteria verifiable.

## Post-merge evaluation

The `task-envcfg` eval-manager will run a controlled replay against the merged
XSH commit using the current approved handbook lineage, verify the
closure-body behavior described in the acceptance criteria, and record
acceptance or rejection in that run's manager report.

<!-- CONTROLLER_TICKET_SNAPSHOT_END -->

## Factory context required before coding

The factory documents below are outside the XSH worktree. Before coding, use
the `read` tool on each exact absolute path. This is required so the session
JSONL proves that the worker consumed the current factory guidance:

- North star: `/Users/josh/d/laputa-systems/xsh-factory/NORTH-STAR.md`
- Shared handbook: `/Users/josh/d/laputa-systems/xsh-factory/runtime/handbook.md`

Then use the `read` tool on the product worktree's exact guidance files:

- Product agent guide: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785783248621/phases/01-ticket/worktrees/task-envcfg-005/AGENTS.md`
- XSH rationale: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785783248621/phases/01-ticket/worktrees/task-envcfg-005/docs/CHAPTER-01-why-xsh.md`

## Implementation contract

Work only in `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785783248621/phases/01-ticket/worktrees/task-envcfg-005` on branch `factory/task-envcfg-005/1785783248954`. Do not edit XSH main, the
factory main tree, or the ticket diagnosis. Make the smallest general XSH
language, tooling, test, or canonical-documentation change supported by the
ticket. Run the narrowest relevant checks, commit the product change on this
branch, and leave the worktree clean.

The controller has staged a fail-closed `not-ready` report at
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785783248621/phases/01-ticket/workers/engineer/task-envcfg-005/REPORT.md`. Complete that file in place; do not spend turns
reconstructing its headings. Keep `## Result` as `not-ready` until the
acceptance checks, commit, and clean-worktree validation are complete.

Write `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785783248621/phases/01-ticket/workers/engineer/task-envcfg-005/REPORT.md` with these exact headings:

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
