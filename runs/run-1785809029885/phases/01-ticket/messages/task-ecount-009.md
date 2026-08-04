# Controller-assigned engineer ticket

This is an immutable controller assignment for one implementation worker.
The controller, not the worker, selected the ticket, snapshot, worktree, and
branch.

## Assignment authority

- Ticket ID: `task-ecount-009`
- Ticket snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785809029885/phases/01-ticket/tickets/task-ecount-009.md`
- Ticket snapshot SHA-256: `3c630c90a574a0ff7e3f8252101ac5e5c0f9ce266398b073b3f17fdeb485fb65`
- Dedicated XSH worktree: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785809029885/phases/01-ticket/worktrees/task-ecount-009`
- Branch: `factory/task-ecount-009/1785809030662`
- XSH base commit: `e8f64a244af1727f64b4ee368441d04ca820d774`
- engineer report: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785809029885/phases/01-ticket/workers/engineer/task-ecount-009/REPORT.md`
- Factory root: `/Users/josh/d/laputa-systems/xsh-factory`
- Run evidence root: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785809029885/phases/01-ticket`

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
# Ticket task-ecount-009

## Status

Approved.

## CTO review

- Review cycle: `post-cycle-1785805967215` (2026-08-03)
- Decision: Approved for the next two-engineer ticket cycle.
- Basis: The linked manager reproduced a general `?`-inside-stream-closure
  internal IR failure on the merged baseline candidate; this is a direct
  product trust defect with a focused regression boundary.
- Assignment boundary: Make postfix `?` inside a stream-stage closure compile
  and propagate normally, or replace the internal IR failure with a precise
  source-local diagnostic; preserve existing closure and stream behavior.

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-ecount` (`evals/task-ecount/EVAL.md`)
- Shared handbook lineage: `runs/run-1785805967215/phases/02-reeval-task-ecount-007/lineage/handbook-approved.md`
- Manager run: `runs/run-1785805967215/phases/02-reeval-task-ecount-007/workers/eval-manager/task-ecount/REPORT.md`
- Executor run: `runs/run-1785805967215/phases/02-reeval-task-ecount-007/workers/eval-worker/task-ecount-1` (trial 1)
- XSH baseline commit: `26c9922b41d21939d1740fa48347283326f76a86` (task-ecount-007 candidate under replay)

## Observation

Postfix `?` (error propagation) inside a stream-stage closure is rejected not
with a clear diagnostic but with an internal compiler error:

```text
err[compact.indexed-build]: indexed IR could not encode `full_ir_function_blocker`
  ecount.xsh:14:43
  proc main(...argv: List[Str]) [fs, error] {
                                            ^ indexed IR could not encode `full_ir_function_blocker`
```

The error is attributed to the enclosing `proc` line, not to the offending
closure, so there is no source-local diagnostic. The worker hit this while
trying to extract an extension inside a `map` block:

```xsh
let exts = strs
  |> map { |s| (s.split(".") |> last())?.lower() }
  |> collect()
```

The workaround (read the element via `List.get(index, fallback)` without `?`)
compiled cleanly, so the runtime supports the underlying operation — only the
`?`-inside-closure form fails, and it fails at the IR build stage with no
useful location.

## Evidence

- Worker session: `runs/run-1785805967215/phases/02-reeval-task-ecount-007/workers/eval-worker/task-ecount-1/session.jsonl.bz2`:
  - line 99: `err[compact.indexed-build] ... full_ir_function_blocker` from the `map { |s| (s.split(".") |> last())?.lower() }` closure in `ecount.xsh`.
  - line 101: the worker isolates the trigger in `t2.xsh` and the identical `full_ir_function_blocker` returns at the `proc main` line.
  - worker review `review.md`, section `## XSH language proposals`: "Using postfix `?` ... inside a stream-stage closure ... is rejected not with a clear diagnostic but with an internal compiler error ... no source mapping. The workaround (read the element via `List.get(index, fallback)` without `?`) compiled cleanly."
- Manager host probe on the same candidate commit (`26c9922b`):
  ```xsh
  let exts = strs |> map { |s| (s.split(".") |> last())?.lower() } |> collect()
  ```
  `xsht check` returns the identical `full_ir_function_blocker` at the `proc main` line.
- Quantitative metrics: `run.json` `result: pass`, `correctness.exact_output: true`; the eval still passed because the worker worked around the blocker with `List.get`/`Path.ext`, so the defect is the unusable `?`-in-closure form, not the eval result.

## Diagnosis or hypothesis

The runtime supports `last()`/`split`/comparison fine; the failure is specific
to postfix `?` appearing inside a stream-stage block. The compact indexed-IR
builder cannot encode the closure that contains a `?`-propagating tail and
emits `full_ir_function_blocker` with no source mapping, located on the
`proc` line. This is the same internal blocker family seen in task-ecount-002
(positional optional arguments), task-ecount-006 (direct module-stream
`collect()`), and task-ecount-007 (`fold`), but with a distinct, reproducible
trigger that the task-ecount-007 fold fix does not cover: a `?` inside any
ordinary `map`/`where`/`each` block. Any eval or user pipeline that wants to
propagate an expected failure inside a stream-stage closure hits this and gets
an opaque IR error instead of a learnable diagnostic, forcing a workaround or
a discovery loop.

## North-star impact

The north star asks for explicit boundaries, no "repeated discoveries", and
agents that reach correct solutions without trial-and-error. A postfix `?`
that is documented as the standard error-propagation idiom but crashes the
compiler with an unlocated internal IR error when placed inside a stream
block violates the trust the factory exists to build. Making `?` inside a
stream-stage closure either work (propagate the Result failure as a normal
error) or emit a normal type/check diagnostic naming the closure and the
limitation would remove the workaround loop. Evidence of generalization: any
pipeline eval using `?` in a stream block (task-ecount, task-tags,
task-envcfg, or a future port) would benefit; a replay should show no
`full_ir_function_blocker` for `?`-in-closure and either correct propagation
or a located diagnostic.

## Proposed XSH change

Smallest candidate, one of:

1. Support postfix `?` inside a stream-stage closure by lowering the closure
   tail through the error-propagating path (analogous to the
   `lower_tail_stmt_as_expr` fix applied to `fold` in task-ecount-007), so the
   `Result` failure propagates as a normal error; or
2. Reject `?` inside a stream-stage block at check time with a clear
   diagnostic naming the closure and the limitation, and never emit
   `full_ir_function_blocker` / `compact.indexed-build` with a wrong source
   location.

In both cases add a regression test for `?` inside a `map` block and confirm
`xsht check` and `xsh` agree (no checker-accepts / runtime-crashes or
runtime-crashes-after-check-accepts split).

## Acceptance criteria

- `s |> map { |x| (x.split(".") |> last())? } |> collect()` either compiles
  and propagates the failure, or is rejected at check time with a diagnostic
  that names the stage/closure — never `err[compact.indexed-build]` /
  `full_ir_function_blocker` and never an error located at the `proc` line.
- `xsht check` and `xsh` agree on the `?`-in-closure form.
- The `List.get(index, fallback)` and `Path.ext` workarounds continue to
  behave as before.
- A replay of `task-ecount` on the merged change still byte-for-byte matches
  the `fd | awk | sort | uniq -c | sort -n` oracle and passes the timing gate.

## Scope and non-goals

- No change to stream ordering, sort semantics, or `group-by` behavior.
- Not an ecount shortcut; the fix must generalize to every `?`-in-stream-stage
  use.
- The root `full_ir_function_blocker` family is shared with task-ecount-002,
  task-ecount-006, and task-ecount-007; this ticket tracks the `?`-in-closure
  trigger specifically and may share a root cause with those, to be fixed
  together only if the IR blocker is unified.
- No change to the shared agent handbook inside XSH; the factory lineage owns
  the agent-facing handbook.

## Post-merge evaluation

The `task-ecount` eval-manager will run a controlled replay against the merged
XSH commit using the current approved handbook lineage, verify the
`?`-in-closure behavior and diagnostics described in the acceptance criteria,
and record acceptance or rejection in that run's manager report.

<!-- CONTROLLER_TICKET_SNAPSHOT_END -->

## Factory context required before coding

The factory documents below are outside the XSH worktree. Before coding, use
the `read` tool on each exact absolute path. This is required so the session
JSONL proves that the worker consumed the current factory guidance:

- North star: `/Users/josh/d/laputa-systems/xsh-factory/NORTH-STAR.md`
- Shared handbook: `/Users/josh/d/laputa-systems/xsh-factory/runtime/handbook.md`

Then use the `read` tool on the product worktree's exact guidance files:

- Product agent guide: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785809029885/phases/01-ticket/worktrees/task-ecount-009/AGENTS.md`
- XSH rationale: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785809029885/phases/01-ticket/worktrees/task-ecount-009/docs/CHAPTER-01-why-xsh.md`

## Implementation contract

Work only in `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785809029885/phases/01-ticket/worktrees/task-ecount-009` on branch `factory/task-ecount-009/1785809030662`. Do not edit XSH main, the
factory main tree, or the ticket diagnosis. Make the smallest general XSH
language, tooling, test, or canonical-documentation change supported by the
ticket. Run the narrowest relevant checks, commit the product change on this
branch, and leave the worktree clean.

The controller has staged a fail-closed `not-ready` report at
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785809029885/phases/01-ticket/workers/engineer/task-ecount-009/REPORT.md`. Complete that file in place; do not spend turns
reconstructing its headings. Keep `## Result` as `not-ready` until the
acceptance checks, commit, and clean-worktree validation are complete.

Write `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785809029885/phases/01-ticket/workers/engineer/task-ecount-009/REPORT.md` with these exact headings:

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
