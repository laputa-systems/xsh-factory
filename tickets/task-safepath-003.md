# Ticket task-safepath-003

## Status

Approved.

## CTO decision — throughput cycle 2026-08-08

- Decision: Approved for one bounded implementation and linked-replay cycle.
- Basis: The preceding `task-safepath-002` delivery passed correctness and
  replay, while the same replay produced a distinct, minimal residual
  `full_ir_function_blocker` for nested conditional statements inside `fold`.
- Scope: Extend the existing fold lowering path for the two stated conditional
  forms; no new syntax, stream surface, or unrelated diagnostic redesign.
- Evidence: `runs/run-1786162002471/phases/02-reeval-task-safepath-002/workers/eval-manager/task-safepath/REPORT.md`
  and the worker session/reproducer referenced by `task-safepath-003`.
- Admission: One engineer row is required; linked `task-safepath` replay and
  one independent eval remain the delivery gates.

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
- Shared handbook lineage: `runs/run-1786162002471/phases/02-reeval-task-safepath-002/lineage/handbook-approved.md`
- Manager run: `runs/run-1786162002471/phases/02-reeval-task-safepath-002/workers/eval-manager/task-safepath/REPORT.md`
- Executor run: `runs/run-1786162002471/phases/02-reeval-task-safepath-002` (workers/eval-worker/task-safepath-1)
- XSH baseline commit: `461fe36bfd0d1ca5670777e2ea1531f902e88558` (candidate under test `95878384b9d6bb66f5631d630dca4d306f95a3a0`)

## Observation

Under candidate commit `95878384` (the `task-safepath-002` fix for pipelines-in-
`fold`), a nested `if` **statement** — or a nested `if` used as a branch's
direct tail — inside a `fold { |acc, item| … }` block still fails the indexed-IR
build with the opaque `full_ir_function_blocker`, while the identical nested
`if` type-checks fine in a normal `proc` body. The agent was forced to rewrite
the natural stateful form into the `let`-hoist workaround:

```xsh
} else if seg == ".." {
  let popped = if parts.len() == 0 { parts } else { parts |> take(parts.len() - 1) |> collect() }
  let is_esc = acc.escaped or parts.len() == 0
  { parts: popped, escaped: is_esc }
}
```

This is a continuation of the exact `full_ir_function_blocker` defect family
that `task-safepath-002` set out to eliminate; that ticket's acceptance scope
(the `take`/`collect` pipeline in a fold) is now met, but a closely related
stateful conditional composition in `fold` still trips the opaque internal
error.

## Evidence

- Worker session:
  `runs/run-1786162002471/phases/02-reeval-task-safepath-002/workers/eval-worker/task-safepath-1/session.jsonl`
  — repeated `err[compact.indexed-build] ... full_ir_function_blocker` during
  systematic reduction (thinking/tool lines 51, 67, 77, 79, 81), including a
  minimal nested-`if`-statement-in-`fold` repro with no `take`/`collect`
  (line 81), and the confirmation that the same nested `if` compiles in a plain
  `proc` body (line 81/83 test).
- Artifact `.../task-safepath-1/safepath.xsh` uses the `let`-hoist workaround
  because the natural nested-`if`-statement form inside the `fold` fails to
  compile.
- Worker `report.json` (result `pass`) and the agent's `review.md` ("A nested
  `if` used as a statement (or as the direct tail-expression of a branch)
  inside a `fold` block fails the indexed IR build with `full_ir_function_blocker`
  … Workaround: hoist the nested conditional into a `let` binding.").

## Diagnosis or hypothesis

This is a reusable XSH compiler correctness/ergonomics defect, not task
confusion. `fold` is a composable stream stage the handbook teaches for stateful
accumulators (queues, dedup, pop-last); a stateful conditional that is valid in
a top-level `proc` is rejected only inside a `fold` block, and the diagnostic
still surfaces the implementation-internal name `full_ir_function_blocker`
rather than a located, human-readable "unsupported here" message. The
`task-safepath-002` fix lowered `fold`-tail `If` expressions whose branches end
in plain values, but interior nested conditional statements with statement
bodies (and the nested-`if`-as-branch-tail form) still route through the
blocker guard and fail opaquely. Any agent writing stateful per-element
transformations will hit this and be forced into a non-idiomatic rewrite,
harming composability and trustworthy diagnostics.

## North-star impact

Resolving this would make `fold` a dependable composition site for stateful
glue (accumulators with per-item branching) and convert an opaque
`full_ir_function_blocker` failure into either a supported compilation or a
clear, located diagnostic — extending the `task-safepath-002` win to the
conditional forms agents actually write. Falsification: a replay that writes a
nested conditional statement inside a `fold` block and runs it without a
workaround must compile and pass.

## Proposed XSH change

Extend the `task-safepath-002` fold lowering so nested conditional statements
(and nested `if` used as a branch's direct tail) inside a `fold` block lower
cleanly, or otherwise emit a located, named diagnostic instead of the opaque
`full_ir_function_blocker`. Do not claim the change is already implemented.

## API-surface justification

- Semantic capability affected: composing stateful, conditional statements
  inside a `fold` accumulator block — the core composability behavior the
  `task-safepath-002` fix already targets, extended to statement-form
  conditionals.
- Closest current behavior: the identical nested `if` compiles in a `proc`
  body and the pipeline/`if`-expression forms compile inside `fold`; only the
  nested statement conditional is rejected, so the restriction is a specific
  lowering gap, not a language rule the author can learn elsewhere.
- This is a correctness/compile defect for existing constructs, not a new
  builtin, keyword, or method; no new public API is proposed.
- Cost: an extension of the already-merged fold lowering path plus a regression
  test; no checker/registry change beyond the diagnostic wording.
- Falsification replay: a `task-safepath` (or validator-style) descendant must
  compile a nested conditional statement inside a `fold` block without the
  workaround and pass.

## Acceptance criteria

- A nested `if` statement (with statement bodies, e.g. `var` assignment) inside
  a `fold` block compiles and runs correctly.
- A nested `if` used as a branch's direct tail inside a `fold` block compiles
  and runs correctly.
- The opaque `full_ir_function_blocker` is gone for these cases; any genuinely
  unsupported in-block conditional now reports a located, named diagnostic.
- `xsht check`/`fmt`/`lint` accept the idiomatic stateful in-fold conditional.
- A `task-safepath` replay that writes the natural nested conditional in the
  fold (no `let`-hoist workaround) passes all correctness cases.

## Scope and non-goals

- Not changing the eval, harness, or oracle.
- Not adding new stream/method primitives; only making existing conditional
  composition work (or fail cleanly) inside `fold`.
- Not altering `abort`/quiet-exit behavior.

## Post-merge evaluation

The next `task-safepath` (or a validator-style) eval-manager replay must accept
the merged change when a nested conditional statement inside a `fold` block
compiles without an opaque error and all correctness cases pass, and reject it
otherwise.
