# Controller-assigned engineer ticket

This is an immutable controller assignment for one implementation worker.
The controller, not the worker, selected the ticket, snapshot, worktree, and
branch.

## Assignment authority

- Ticket ID: `task-findexec-001`
- Ticket snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785967719321/phases/01-ticket/tickets/task-findexec-001.md`
- Ticket snapshot SHA-256: `219406641ce1a1e02f99789257f66aa421e61677e196364fd81306f7c6236d3c`
- Dedicated XSH worktree: `/Users/josh/d/laputa-systems/xsh-factory/../.xsh-factory-worktrees/run-1785967719321/task-findexec-001`
- Branch: `factory/task-findexec-001/1785967720675`
- XSH base commit: `1cf4ad3d7ee5fde9b3160b11d8073cbd7ce5e7c4`
- engineer report: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785967719321/phases/01-ticket/workers/engineer/task-findexec-001/REPORT.md`
- Factory root: `/Users/josh/d/laputa-systems/xsh-factory`
- Run evidence root: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785967719321/phases/01-ticket`

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
# Ticket task-findexec-001

## Status

Approved.

## Change target

- `product`

## CTO review

- Review cycle: pre-cycle-1.
- Decision: Approved for one bounded engineer assignment.
- Basis: The source `task-findexec` trial produced a reproducible, general
  checker defect with complete API-surface justification, a live linked eval,
  and narrow acceptance criteria. The change removes an expression-position
  asymmetry without adding syntax, types, builtins, or runtime semantics.
- Admission evidence: `runs/run-1785960825554/phases/01-eval/workers/eval-manager/task-findexec/REPORT.md`
  and `runs/run-1785960825554/phases/01-eval/workers/eval-worker/task-findexec-1/run.json`.
- Assignment boundary: implement only first-class `if`/`else` tail
  acceptance, add focused native regression coverage and canonical product
  documentation as needed, and preserve existing `let` RHS behavior.
- Replay gate: linked `task-findexec` must pass correctness and restrictions
  without the bind-then-tail workaround; the independent eval must also
  produce a valid manifest.

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

- Eval: `task-findexec`
- Shared handbook lineage: `runs/run-1785960825554/phases/01-eval/lineage/handbook-approved.md`
- Manager run: `runs/run-1785960825554/phases/01-eval/workers/eval-manager/task-findexec/REPORT.md`
- Executor run: `runs/run-1785960825554/phases/01-eval/workers/eval-worker/task-findexec-1/`
- XSH baseline commit: `1cf4ad3d7ee5fde9b3160b11d8073cbd7ce5e7c4`

## Observation

In the pinned XSH build, a conditional used as a bare tail expression inside a
stream block is rejected. `map { |n| if c { a } else { b } }` fails at check
time with `err[check.map-tail]: map requires a tail value`, for both single-
and multi-line `if`/`else` bodies. The same `if`/`else` expression succeeds as
the right-hand side of a `let` binding (`let x = if c { a } else { b }`). The
eval-worker hit this repeatedly (tool-error turns 18, 19, 21) while building
the relative-path branch of `findexec.xsh`, and only after several probes
found the workaround of binding first (`let p = if ... {} else {}; p`).

## Evidence

- Worker session: `runs/run-1785960825554/phases/01-eval/workers/eval-worker/task-findexec-1/session.jsonl.bz2`
- Tool-error turns 18/19 (`err[check.map-tail]: map requires a tail value`
  against `findexec.xsh:7` `|> map { |e|`), turn 21 (`/tmp/iftest.xsh:3`
  `[1,2,3] |> map { |n|`), and the three `iftest*.xsh` single/multi-line
  probes in the record.
- Worker `review.md` "## XSH language proposals" first bullet and the session
  thinking at turns 55/57 documenting that `if` works only as a `let` RHS, not
  as a bare tail in a stream stage.
- Worker report.json `tool_errors` array (6 entries) and `run.json` (correctness
  pass, restrictions pass, protocol pass).

## Diagnosis or hypothesis

This is a language ergonomics asymmetry, not task-specific confusion: the
handbook itself teaches the `let line = if cond { a } else { b }` position, so
the agent reasonably expects the same `if`/`else` expression to be a valid tail
value of a `map`/`where` block. Rejecting it there forces an awkward
bind-then-name idiom and consumed several exploratory turns. A uniform
if-expression usable in any expression or tail position generalizes to every
eval that builds a value conditionally inside a pipeline, so the fix is not a
recipe for this task alone.

## North-star impact

A uniform if-expression improves learnability (one mental model for
conditionals everywhere) and agent efficiency (removes the bind-then-tail
workaround that blocks pipeline authoring). Evidence of generalization: after
the change, a fresh copy of this eval and any predicate-heavy eval
(`task-histogram`, `task-tags`) should complete the same conditional pipeline
without a "map requires a tail value" error.

## Proposed XSH change
## API-surface justification

The semantic capability XSH should express is "a conditional that is itself a
value usable as any expression, including a stream block's tail." The closest
existing spelling is the `if`/`else` form as a `let` RHS; it is insufficient
because the checker does not accept the same form as a block tail, so a
branching pipeline requires an intermediate binding. This argues for a small
checker/parse rule — allow an `if`/`else` expression in tail position of a
stage block — rather than a new type or builtin. Implementation touches the
checker's tail/expression acceptance and its regression tests; no runtime or
records change is expected because the value semantics already exist behind the
`let` form. Ergonomic surface is unchanged; this removes an asymmetry rather
than adding a second spelling for an existing operation.

## Proposed XSH change

Make `if`/`else` a first-class expression so it is accepted in any expression
position, including a stream stage block's tail, matching its existing
acceptance as a `let` right-hand side. No new keyword is proposed; this is a
consistency fix in expression/tail parsing.

## Acceptance criteria

- `map { |n| if c { a } else { b } }` and the equivalent `where`/`each` tail
  pass `xsht check` without "map requires a tail value".
- A commit-message-size regression and a single-line `if`/`else` tail both
  pass.
- Existing behavior as a `let` RHS is unchanged.
- The `task-findexec` eval replays and completes without the bind-then-tail
  workaround.

## Scope and non-goals

- Not changing `if`/`else` semantics, evaluation, or types.
- Not addressing the separate `Path.relative_to` contract/`?`-rejection
  observation from this session (different ticket if confirmed).
- No new boolean or control-flow spelling.

## Post-merge evaluation

The linked `task-findexec` eval-manager replay will re-run this eval on the
XSH commit containing the change and confirm the conditional pipeline builds
without a tail error and still matches the `find ... | sort` oracle.
<!-- CONTROLLER_TICKET_SNAPSHOT_END -->

## Factory context required before coding

The factory documents below are outside the XSH worktree. Before coding, use
the `read` tool on each exact absolute path. This is required so the session
JSONL proves that the worker consumed the current factory guidance:

- North star: `/Users/josh/d/laputa-systems/xsh-factory/NORTH-STAR.md`
- Shared handbook: `/Users/josh/d/laputa-systems/xsh-factory/runtime/handbook.md`

Then use the `read` tool on the product worktree's exact guidance files:

- Product agent guide: `/Users/josh/d/laputa-systems/xsh-factory/../.xsh-factory-worktrees/run-1785967719321/task-findexec-001/AGENTS.md`
- XSH rationale: `/Users/josh/d/laputa-systems/xsh-factory/../.xsh-factory-worktrees/run-1785967719321/task-findexec-001/docs/CHAPTER-01-why-xsh.md`

## Implementation contract

Work only in `/Users/josh/d/laputa-systems/xsh-factory/../.xsh-factory-worktrees/run-1785967719321/task-findexec-001` on branch `factory/task-findexec-001/1785967720675`. Do not edit XSH main, the
factory main tree, or the ticket diagnosis. Make the smallest general XSH
language, tooling, test, or canonical-documentation change supported by the
ticket. Run the narrowest relevant checks, commit the product change on this
branch, and leave the worktree clean.

The controller has staged a fail-closed `not-ready` report at
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785967719321/phases/01-ticket/workers/engineer/task-findexec-001/REPORT.md`. Complete that file in place; do not spend turns
reconstructing its headings. Keep `## Result` as `not-ready` until the
acceptance checks, commit, and clean-worktree validation are complete.

Write `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785967719321/phases/01-ticket/workers/engineer/task-findexec-001/REPORT.md` with these exact headings:

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
