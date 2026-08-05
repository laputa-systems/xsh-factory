# Controller-assigned engineer ticket

This is an immutable controller assignment for one implementation worker.
The controller, not the worker, selected the ticket, snapshot, worktree, and
branch.

## Assignment authority

- Ticket ID: `task-bigfiles-001`
- Ticket snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785888999833/phases/01-ticket/tickets/task-bigfiles-001.md`
- Ticket snapshot SHA-256: `37b32b6332b55ab457009bff7d067ae7a379e31cb6d99a0c9f68f109aaa55310`
- Dedicated XSH worktree: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785888999833/phases/01-ticket/worktrees/task-bigfiles-001`
- Branch: `factory/task-bigfiles-001/1785889000406`
- XSH base commit: `a67599b7865707d0ddbfdaf04bd1620f511556b8`
- engineer report: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785888999833/phases/01-ticket/workers/engineer/task-bigfiles-001/REPORT.md`
- Factory root: `/Users/josh/d/laputa-systems/xsh-factory`
- Run evidence root: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785888999833/phases/01-ticket`

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
# Ticket task-bigfiles-001

## Status

Approved.

## CTO review

- Review cycle: pre-cycle organization request.
- Decision: Approved for implementation in the next organization cycle.
- Basis: `task-bigfiles` independently reproduced a general named-option/block
- diagnostic and API-signature mismatch, then passed all nine evaluator cases.
- The ticket has a live linked eval, bounded diagnostics/API-display scope,
- explicit acceptance criteria, and the required API-surface justification.
- It adds no new builtin, keyword, constructor, type, method, or syntax form.
- Admission evidence: `runs/run-1785887678360/workers/eval-manager/task-bigfiles/REPORT.md`
- and `runs/run-1785887678360/workers/eval-worker/task-bigfiles-1/run.json`.
- Replay gate: the linked `task-bigfiles` replay must pass the existing
- byte-exact evaluator and confirm the flag-placement discovery loop is removed.


## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-bigfiles`
- Shared handbook lineage: `runs/run-1785887678360/lineage/handbook-approved.md`
- Manager run: `runs/run-1785887678360/workers/eval-manager/task-bigfiles/REPORT.md`
- Executor run: `runs/run-1785887678360/workers/eval-worker/task-bigfiles-1/`
- XSH baseline commit: `a67599b7865707d0ddbfdaf04bd1620f511556b8`

## Observation

The eval-worker needed a descending sort and first wrote
`sort-by { |e| e.size } --desc`. The checker rejected it as
`err[check.unresolved-name]` on `--desc`; the same misleading error recurred
on a second attempt and on the first attempt was masked by downstream
type-mismatch and stream-input errors. The correct form, discovered by trial
and error, is `sort-by --desc { |e| e.size }`. The `xsht api
language:stream.sort-by` signature is displayed as
`sort-by(block, --desc: Bool = false)`, which lists the block first and gives
no hint that the named option must precede the block — so the displayed
signature disagrees with the accepted call syntax.

## Evidence

- Executor session: `runs/run-1785887678360/workers/eval-worker/task-bigfiles-1/session.jsonl.bz2.bz2` — `sort-by ... --desc` produces `err[check.unresolved-name]` (twice); the flags-before-block form passes `xsht check`.
- Executor report: `runs/run-1785887678360/workers/eval-worker/task-bigfiles-1/report.json` — 27 assistant turns, 34 tool calls, 18 thinking blocks, reasoning 2319 tokens.
- Worker `review.md` `## xsht friction` documents the flag-placement discovery and the misaligning API signature.
- Evaluator manifest: `runs/run-1785887678360/workers/eval-worker/task-bigfiles-1/run.json` — all nine cases byte-exact; the solution is correct.

## Diagnosis or hypothesis

This is a general tooling/ergonomics defect, not task-specific confusion.
Placing a named option after a block argument is a natural mistake, and the
checker answers with a generic `unresolved-name` the user cannot map back to
flag placement, while the API display signature `sort-by(block, --desc: Bool =
false)` reinforces the wrong order. The same failure mode is reproducible for
any call that takes both a named option and a block/positional argument, so
fixing the diagnostic or the signature presentation removes repeated agent
friction beyond this eval.

## North-star impact

Resolving this improves XSH learnability and ergonomics: agents and humans
stop guessing flag placement and stop reading a misleading `unresolved-name`
mirror. The north-star test is whether a later eval with a descending sort or
any named-option-plus-block call completes without the flag-placement
re-discovery loop, and whether `xsht check`/`xsht api` surfaces a helpful
message instead of `unresolved-name`.

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

Choose the smallest surface area that does not add a new spelling: either
(a) make the checker emit a targeted diagnostic when a named option follows
the block/positional argument (e.g. "`--desc` is a named option and must
precede the block argument"), and/or (b) present the `sort-by` (and similar
stage) API signature with options before the block so the displayed syntax
matches the accepted call order. Do not assert the change is implemented.

## Acceptance criteria

- `xsht check` on `sort-by { |e| e.size } --desc` reports a flag-placement
  error with a corrective hint, or the `xsht api` signature shows
  `sort-by(--desc: Bool = false, block)` matching the accepted order.
- The eval-worker task-bigfiles session completes a descending sort without
  the unresolved-name flag-placement loop.
- No change to byte-exact output contracts of existing evals.

## Scope and non-goals

Do not add a new keyword or a second spelling of `sort-by`; keep the existing
flags-before-arguments grammar. Out of scope: any runtime or sort-by
behavior change.

## Post-merge evaluation

Replay `task-bigfiles` against the updated XSH commit and confirm the worker
no longer re-discovers `--desc` placement; also spot-check `task-ecount` or
another stream-stage eval for the same diagnostic.

<!-- CONTROLLER_TICKET_SNAPSHOT_END -->

## Factory context required before coding

The factory documents below are outside the XSH worktree. Before coding, use
the `read` tool on each exact absolute path. This is required so the session
JSONL proves that the worker consumed the current factory guidance:

- North star: `/Users/josh/d/laputa-systems/xsh-factory/NORTH-STAR.md`
- Shared handbook: `/Users/josh/d/laputa-systems/xsh-factory/runtime/handbook.md`

Then use the `read` tool on the product worktree's exact guidance files:

- Product agent guide: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785888999833/phases/01-ticket/worktrees/task-bigfiles-001/AGENTS.md`
- XSH rationale: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785888999833/phases/01-ticket/worktrees/task-bigfiles-001/docs/CHAPTER-01-why-xsh.md`

## Implementation contract

Work only in `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785888999833/phases/01-ticket/worktrees/task-bigfiles-001` on branch `factory/task-bigfiles-001/1785889000406`. Do not edit XSH main, the
factory main tree, or the ticket diagnosis. Make the smallest general XSH
language, tooling, test, or canonical-documentation change supported by the
ticket. Run the narrowest relevant checks, commit the product change on this
branch, and leave the worktree clean.

The controller has staged a fail-closed `not-ready` report at
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785888999833/phases/01-ticket/workers/engineer/task-bigfiles-001/REPORT.md`. Complete that file in place; do not spend turns
reconstructing its headings. Keep `## Result` as `not-ready` until the
acceptance checks, commit, and clean-worktree validation are complete.

Write `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785888999833/phases/01-ticket/workers/engineer/task-bigfiles-001/REPORT.md` with these exact headings:

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
