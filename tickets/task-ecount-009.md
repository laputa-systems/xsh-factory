# Ticket task-ecount-009

## Status

Merged.

## Change target

- `product`

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

- Implementation branch: `factory/task-ecount-009/1785809030662`
- Implementation commit: `95dd3b643588c290d035d2d99a28d0839001d731`
- Detected at XSH commit: `5e0c679`
- Implementation run: `runs/run-1785809029885`

## CTO merge decision

- Decision: Merged after engineer validation and linked `task-ecount` replay.
- Merge commit: `5e0c679`.
- Evidence: `runs/run-1785809029885/phases/02-reeval-task-ecount-009/report.json`.

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

- Worker session: `runs/run-1785805967215/phases/02-reeval-task-ecount-007/workers/eval-worker/task-ecount-1/session.jsonl`:
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
