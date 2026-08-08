# Controller-assigned engineer ticket

This is an immutable controller assignment for one implementation worker.
The controller, not the worker, selected the ticket, snapshot, worktree, and
branch.

## Assignment authority

- Ticket ID: `task-safepath-002`
- Ticket snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786162002471/phases/01-ticket/tickets/task-safepath-002.md`
- Ticket snapshot SHA-256: `55c621508b8ce1f34fe338ef590e833bfdbf544d22d1078d688277c9fcf0a8a9`
- Dedicated XSH worktree: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786162002471/task-safepath-002`
- Branch: `factory/task-safepath-002/1786162005661`
- XSH base commit: `461fe36bfd0d1ca5670777e2ea1531f902e88558`
- engineer report: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786162002471/phases/01-ticket/workers/engineer/task-safepath-002/REPORT.md`
- Factory root: `/Users/josh/d/laputa-systems/xsh-factory`
- Run evidence root: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786162002471/phases/01-ticket`

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
  `runs/run-1786144485305/phases/02-reeval-task-safepath-001/workers/eval-worker/task-safepath-1/session.jsonl.bz2`
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

<!-- CONTROLLER_TICKET_SNAPSHOT_END -->

## Factory context required before coding

The factory documents below are outside the XSH worktree. Before coding, use
the `read` tool on each exact absolute path. This is required so the session
JSONL proves that the worker consumed the current factory guidance:

- North star: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786162002471/phases/01-ticket/guidance/NORTH-STAR.md`
- Approved handbook snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786162002471/phases/01-ticket/guidance/handbook.md`
- Handbook candidate: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786162002471/phases/01-ticket/lineage/handbook-candidate.md`

The approved snapshot is a run-scoped copy of the checked-in handbook. Read it
as an input and never edit it or the checked-in handbook. If this ticket
produces a reusable lesson, add it to the run-scoped candidate path above; the
candidate is shared review input and is promoted only after CTO review. If no
handbook improvement is justified, leave the candidate unchanged.

Then use the `read` tool on the product worktree's exact guidance files:

- Product agent guide: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786162002471/task-safepath-002/AGENTS.md`
- XSH rationale: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786162002471/task-safepath-002/docs/CHAPTER-01-why-xsh.md`

## Implementation contract

Work only in `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786162002471/task-safepath-002` on branch `factory/task-safepath-002/1786162005661`. Do not edit XSH main, the
factory checkout, the approved handbook snapshot, or the ticket diagnosis.
Make the smallest general XSH language, tooling, test, or
canonical-documentation change supported by the ticket. Run the narrowest
relevant checks, commit the product change on this branch, and leave the
worktree clean.

For ordinary product tickets, use `xsht lint --fix` for linting, then rerun the
relevant checks. If this ticket specifically targets lint, parsing, or
diagnostics, preserve the behavior under test and follow its explicit
acceptance procedure instead of auto-fixing away the evidence.

The controller has staged a fail-closed `not-ready` report at
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786162002471/phases/01-ticket/workers/engineer/task-safepath-002/REPORT.md`. Complete that file in place; do not spend turns
reconstructing its headings. Keep `## Result` as `not-ready` until the
acceptance checks, commit, and clean-worktree validation are complete.

Write `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786162002471/phases/01-ticket/workers/engineer/task-safepath-002/REPORT.md` with these exact headings:

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
