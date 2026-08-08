# Ticket task-safepath-002

## Status

Approved.

## CTO decision — throughput cycle 2026-08-07

- Decision: Approved for one bounded implementation and linked-replay cycle.
- Basis: The prior delivery cycle is closed with durable evidence, satisfying
  the ticket's explicit deferral condition. The linked `task-safepath` replay
  already reproduced the deterministic `full_ir_function_blocker` compiler
  defect, and the acceptance criteria are scoped to an existing stream/fold
  composition with a focused regression test.
- Scope: Fix or clearly diagnose the existing indexed-IR lowering defect; no
  new stream surface or task-contract change.
- Evidence: `runs/run-1786144485305/phases/02-reeval-task-safepath-001/workers/eval-manager/task-safepath/REPORT.md`
  and the closed delivery evidence in `runs/run-1786159268557/report.json`.
- Admission: One engineer row is required; linked `task-safepath` replay and
  independent `task-histogram` evaluation are the delivery gates.

## CTO review — 2026-08-07

- Decision: Deferred; retain Open pending a dedicated compiler-fix cycle.
- Evidence: The linked replay passed correctness and restrictions, while the
  manager reproduced the fold-contained stream failure as a deterministic
  `full_ir_function_blocker` compiler issue.
- Admission: Do not dispatch yet. Revisit after the factory closes the current
  delivery cycle and can reserve a replay that exercises the idiomatic
  in-fold pipeline.

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
- Shared handbook lineage: `runs/run-1786144485305/phases/02-reeval-task-safepath-001/lineage/handbook-approved.md`
- Manager run: `runs/run-1786144485305/phases/02-reeval-task-safepath-001/workers/eval-manager/task-safepath/REPORT.md`
- Executor run: `runs/run-1786144485305/phases/02-reeval-task-safepath-001` (workers/eval-worker/task-safepath-1)
- XSH baseline commit: `630d14261ce5cf0160bf9809e79e2fca12922c70`

## Observation

A stream pipeline embedded inside a `fold` block fails to compile with an
opaque IR-compaction error instead of a clean diagnostic. In
`task-safepath` the agent needed to remove a list's last element while folding
segments; the idiomatic in-block pipeline

```xsh
let popped = acc.parts |> take(acc.parts.len() - 1) |> collect()
```

inside the `fold` block produced

```
err[compact.indexed-build]: indexed IR could not encode `full_ir_function_blocker`
  safepath.xsh:1:31
  proc main(...argv: List[Str]) {
                                ^ indexed IR could not encode `full_ir_function_blocker`
```

The error points at the enclosing `proc` signature (`1:31`), not at the
offending pipeline, giving the agent no clue which construct is unsupported.
A minimal repro (`t4.xsh`) reproduced the same error deterministically, and it
was confirmed again in a further tiny script during the session.

## Evidence

- Worker session:
  `runs/run-1786144485305/phases/02-reeval-task-safepath-001/workers/eval-worker/task-safepath-1/session.jsonl`
  — structured tool error `err[compact.indexed-build] ... full_ir_function_blocker`
  at worker turn 23 (safepath.xsh) and again in the minimal repro turn (t4.xsh).
- Artifact `.../task-safepath-1/safepath.xsh` uses the workaround
  (reverse-scan-with-pending-count) because the in-fold stream idiom fails to
  compile.
- Reproducer `.../task-safepath-1/work/t4.xsh` isolates the failing construct
  (a `take`/`collect` pipeline inside a `fold` block).
- Worker `report.json` (result `pass`; 3 tool errors, of which this is one) and
  the agent's `review.md` ("A nested stream ... inside a `fold` block triggers
  `compact.indexed-build ... could not encode full_ir_function_blocker`").

## Diagnosis or hypothesis

This is a reusable XSH compiler/tooling correctness and ergonomics defect, not
task confusion. A `fold` is a normal composable stream stage the handbook
teaches; a nested pipeline that is valid at top level and in plain `if` blocks
silently fails to compile only inside a `fold` block, and the diagnostic points
at the wrong location (`proc` signature) with an implementation-internal name
(`full_ir_function_blocker`). Any agent writing stateful per-element
transformations (accumulators that themselves manipulate lists/streams) will
hit this and be forced into a non-idiomatic rewrite. This directly harms the
north-star goals of composability and trustworthy, explicit boundaries: a valid
composition is rejected with an opaque error.

## North-star impact

Fixing this would let accumulators inside `fold` blocks express list/stream
manipulation directly (e.g. "drop the last element") instead of requiring the
author to invent a workaround and re-derive it by trial and error. It would
make `fold` a dependable composition site for systems glue (queue/stack-style
accumulators, dedup, pop-last logic) and convert an opaque
`full_ir_function_blocker` failure into either a supported compilation or a
clear, located "not supported here" diagnostic. Stated falsification: a new
validator/tree-walking eval that folds an accumulating list through a stream
pipeline should compile and pass without the workaround.

## Proposed XSH change

Correct the indexed-IR lowerer so a stream pipeline composed inside a `fold`
block lowers cleanly (or, at minimum, emit a located, human-readable
"streams inside fold blocks are not supported" diagnostic instead of the
opaque `full_ir_function_blocker` at the `proc` span). Do not claim the change
is already implemented.

## API-surface justification

- Semantic capability affected: composing stream stages inside a `fold`
  accumulator block — a core composability behavior, not a new surface.
- Closest current behavior: the same pipeline compiles at top level and inside
  a plain `if` block, so the restriction is specific to the `fold` lowering,
  not a language rule the author can learn elsewhere.
- This is a correctness/compile defect for an existing construct, not a new
  builtin, keyword, or method; no new public API is proposed.
- Cost: lowerer/IR fix in the `compact`/indexed path plus a regression test;
  no checker or registry change beyond the diagnostic wording.
- Falsification replay: the linked `task-safepath` (or a `task-pathparts`
  descendant) must compile the in-fold `take`/`collect` idiom without the
  workaround and pass.

## Acceptance criteria

- A pipeline composed inside a `fold` accumulator block (e.g.
  `acc.parts |> take(n) |> collect()`) compiles and runs correctly.
- The opaque `full_ir_function_blocker` error is gone for these cases; any
  genuinely unsupported in-block stream now reports a located, named
  diagnostic.
- `xsht check`/`fmt`/`lint` accept the idiomatic in-fold pipeline.
- A `task-safepath` replay that uses the idiomatic pop-last pipeline in the
  fold passes all correctness cases.

## Scope and non-goals

- Not changing the eval, harness, or oracle.
- Not adding new stream/method primitives; only making existing composition
  work (or fail cleanly) inside `fold`.
- Not altering `abort`/quiet-exit behavior (task-safepath-001).

## Post-merge evaluation

The next `task-safepath` (or a validator-style) eval-manager replay must accept
the merged change when the in-fold stream pipeline compiles without an opaque
error and all correctness cases pass, and reject it otherwise.
