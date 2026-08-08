# Ticket task-safepath-004

## Status

Open.

## Change target

- `product`

Factory changes are CTO-owned. Do not create a factory-target ticket for
engineer dispatch; report the infrastructure change to the CTO instead.

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-safepath`
- Shared handbook lineage: `runs/run-1786163685229/phases/02-reeval-task-safepath-003/lineage/handbook-approved.md`
- Manager run: `runs/run-1786163685229/phases/02-reeval-task-safepath-003/workers/eval-manager/task-safepath/REPORT.md`
- Executor run: `runs/run-1786163685229/phases/02-reeval-task-safepath-003` (workers/eval-worker/task-safepath-1)
- XSH baseline commit: candidate under test `7e9814fe774ceeb9e587ae95c967944548706701`

## Observation

Inside a `for` loop that reassigns a mutable Str accumulator with `var`, Str
concatenation via `+` is rejected with the opaque, mislocated runtime error
`lowered expression expected Int` (reported at `1:1`), while the identical
`+`-of-Str expression is accepted in a `let` initializer. Reassigning with a
display string (`stack = f"${stack}${seg}"`) works. The diagnostics give no hint
that the problem is `+` on Str in this position.

## Evidence

- Worker session:
  `runs/run-1786163685229/phases/02-reeval-task-safepath-003/workers/eval-worker/task-safepath-1/session.jsonl`
  — the `err[runtime.error]: lowered expression expected Int ... probe2.xsh:1:1`
  error recurs ~10 times while the agent tried `stack = stack + seg` in a
  `for` loop, and the same `+` on Str is confirmed accepted in expression /
  `let` position.
- Artifact `.../task-safepath-1/safepath.xsh` works around the defect with a
  display string (`f"${stack}/${seg}"`) after the `+` form failed.
- Worker `review.md` ("Str concatenation via `+` fails inside a `var`
  reassignment in a `for` loop with the opaque runtime error `lowered
  expression expected Int`, even though the same `+` expression is accepted in
  a `let` initializer.").
- Worker `report.json` (result `pass`; 49 turns, 58 tool calls, 2 tool errors)
  and `run.json` (all correctness cases pass, candidate==oracle sha).

## Diagnosis or hypothesis

This is an XSH compiler/type-lowering inconsistency, not task confusion. The
handbook teaches `+`-of-Str as a valid composition form in expression/`let`
position (agents are directed to it repeatedly). Rejecting the same operator's
result type in a mutable `var` reassignment inside a loop, and surfacing an
opaque, mislocated `lowered expression expected Int` with no located
"unsupported here" hint, forces every mutable Str accumulator — a common
systems-glue shape (label building, path/queue accumulation, report lines) —
into a non-obvious rewrite. The diagnostic is an ergonomics and
trustworthiness regression independent of this task.

## North-star impact

Resolving it would make mutable Str accumulation inside loops compose the way
the handbook already teaches, and would convert an opaque, mislocated
`lowered expression expected Int` into either supported lowering or a located,
named diagnostic. Evidence of generalization: a replay of any Str-accumulator
loop (task-safepath or a validator-style eval) that writes `var x = x + frag`
must either compile and pass, or report a located message that names the
unsupported `+`-on-Str-in-mutable-reassignment position.

## Proposed XSH change
## API-surface justification

For any new builtin, keyword, constructor, type, method, or syntax form, state:

- the semantic capability that existing XSH cannot express;
- the closest existing spelling and why it is insufficient;
- whether a desugaring, type-directed rule, declared error family, or library
  API would solve the problem with less surface area;
- the implementation and maintenance cost, including checker, runtime, API
  registry, documentation, and test changes; and
- the evidence and falsification replay required before approval.

An ergonomic shortcut that merely gives a second spelling to an existing
operation is not sufficient justification for product admission.

## Proposed XSH change

The primary ask is a bug-fix alignment of `+`-of-Str lowering: `var x = x +
frag` in a loop body should lower to the same Str result type as the identical
expression in a `let` initializer (which is already supported and taught). No
new builtin, keyword, method, or syntax is proposed; this is making an existing
taught operator behave consistently across syntactic positions. At minimum,
fix the diagnostic so a genuinely unsupported `+` combination in this position
reports a located, named "unsupported here" message instead of the opaque,
mislocated `lowered expression expected Int`. Do not claim the change is
already implemented.

## Acceptance criteria

- `var x = x + frag` (Str + Str) inside a loop body compiles and produces the
  expected concatenated value, matching the `let`-initializer behavior the
  handbook teaches.
- A syntactically invalid `+` combination in the same position, if any remains,
  reports a located, named diagnostic rather than `lowered expression expected
  Int` at `1:1`.
- `xsht check`/`fmt`/`lint` accept the idiomatic mutable Str accumulator.
- A `task-safepath` (or validator-style) replay that writes the natural
  `+`-based Str accumulator (no `f"..."` rewrite) passes all correctness cases.

## Scope and non-goals

- Not changing the eval, harness, oracle, or `abort`/quiet-exit behavior.
- Not adding new string/list primitives (a `List.pop`/drop-last improvement is
  a separate concern tracked elsewhere).

## Post-merge evaluation

The next `task-safepath` (or a validator-style) eval-manager replay must accept
the merged change when a `+`-based mutable Str accumulator in a loop compiles
and passes all correctness cases, and reject it otherwise.
