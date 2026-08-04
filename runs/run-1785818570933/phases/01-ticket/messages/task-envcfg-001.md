# Controller-assigned engineer ticket

This is an immutable controller assignment for one implementation worker.
The controller, not the worker, selected the ticket, snapshot, worktree, and
branch.

## Assignment authority

- Ticket ID: `task-envcfg-001`
- Ticket snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785818570933/phases/01-ticket/tickets/task-envcfg-001.md`
- Ticket snapshot SHA-256: `e0ac0289f6e0441978a411c32f9b84b163f50c04630f73dfcd724650426d1912`
- Dedicated XSH worktree: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785818570933/phases/01-ticket/worktrees/task-envcfg-001`
- Branch: `factory/task-envcfg-001/1785818571444`
- XSH base commit: `97edb51c621260d61a00034ea7ed0742adacbb80`
- engineer report: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785818570933/phases/01-ticket/workers/engineer/task-envcfg-001/REPORT.md`
- Factory root: `/Users/josh/d/laputa-systems/xsh-factory`
- Run evidence root: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785818570933/phases/01-ticket`

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
# Ticket task-envcfg-001

## Status

Approved.

## CTO review

- Review cycle: `pre-cycle-17858185373`
- Decision: Approved for this organization cycle.
- Basis: The deliberate-validation failure workaround was independently
  reproduced by both `task-envcfg` workers, is a general structured-error gap,
  and has focused acceptance criteria plus a linked replay. It is distinct
  from the deferred handbook-only boolean/operator guidance.
- Assignment boundary: Add the smallest canonical deliberate-error primitive
  that propagates through `?`; preserve existing validator semantics and add
  focused native coverage and canonical product documentation. Do not address
  boolean operators, module-shadow guidance, or unrelated env APIs.

## Merge record

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-envcfg`
- Shared handbook lineage: `runs/run-1785816263612/phases/03-eval/lineage/handbook-approved.md` (snapshot `97c5d804c42c7742c9edfea4480163828d864279391d391df77aa60ee4a40e83`); candidate `handbook-candidate.md`
- Manager run: `runs/run-1785816263612/phases/03-eval/workers/eval-manager/task-envcfg/REPORT.md`
- Executor run: `runs/run-1785816263612/phases/03-eval/workers/eval-worker/task-envcfg-1/` and `task-envcfg-2/`
- XSH baseline commit: `5e0c679344458c4f39bf3f368a6d63a4c51aa01f`

## Observation

`task-envcfg` requires a deliberate nonzero exit (with no partial output file)
when `CFG_PORT` is present but not a byte-exact decimal integer. The build has
no generic error constructor, so both eval-workers (trial 1 turn 14, trial 2)
reached the same workaround: route an unrelated typed conversion to failure
inside the validation branch, e.g. `let _ = "not-a-port".parse_int()?`. Both
`review.md` files name the missing deliberate-error primitive as the top
reusable language proposal.

## Evidence

- Session JSONL: `workers/eval-worker/task-envcfg-1/session.jsonl.bz2` (tool errors turns 11/14/16/37), `task-envcfg-2/session.jsonl.bz2` (tool errors turns 9/13).
- Artifacts: `task-envcfg-1/envcfg.xsh`, `task-envcfg-2/envcfg.xsh` (both use the sentinel `parse_int` idiom).
- Reviews: `task-envcfg-1/review.md` (XSH language proposals) and `task-envcfg-2/review.md` (XSH language proposals) independently request a `fail`/`Error(...)` constructor.
- Evaluator: both `run.json` files pass all 10 cases (see `tool_errors` arrays).
- Handbook note at `handbook-approved.md:83-87` documents the absence of a generic `Error(...)` constructor and tells agents not to use an unrelated host failure — yet that is the only documented action available for a byte-exact validation contract where no typed conversion matches.

## Diagnosis or hypothesis

A deliberate validation failure is a normal, reusable systems-glue pattern
("reject this input, exit nonzero, don't write anything"). Forcing an
unrelated `parse_int` on a sentinel literal to fabricate the failure is opaque,
fragile, and directly contradicts the handbook's own "do not use an unrelated
host failure" guidance. This is a general ergonomics gap, not task-specific
confusion: it appears in any config/args-validation boundary, and it was
reproduced independently by two separate sessions.

## North-star impact

XSH's north star calls for structured errors and making expected failures
visible. A first-class deliberate-error primitive (`fail`/`Error(...)` that
propagates through `?` with the standard error family) would let programs
reject malformed input clearly instead of abusing a correlation-free parse
error. Evidence that it generalizes: it removes the sentinel workaround in any
eval that gates on a loud nonzero exit, and it makes the `?` propagation lesson
transfer cleanly to validation boundaries.

## Proposed XSH change

Add a generic deliberate-error mechanism that propagates through postfix `?`
with the existing error family — e.g. a `fail("...")` primitive or an
`Error(...)`/`Err(...)` constructor — replacing the sentinel typed-conversion
idiom. Keep it a word/constructor that works in expression position inside an
`if`/guard, and does not require the current hacky `let _ = "sentinel".parse_int()?`.

## Acceptance criteria

- A program can reject a bad value and exit nonzero with no output file using only the new primitive (no unrelated typed conversion).
- The `task-envcfg` malformed and empty-port failure controls still pass.
- A focused unit test verifies the new primitive propagates through `?` and exits nonzero.
- `xsht check`/`lint` accept the canonical form.

## Scope and non-goals

- Out of scope: changing the semantics or strictness of `env.int`/`parse_int` validators (that is a separate contract decision: `env.int` rejects only non-numeric runs and stays lenient about sign/whitespace/hex).
- Out of scope: the `&&`/`||` word-form friction (handled as a handbook candidate in this cycle, not a product ticket).

## Post-merge evaluation

Replay `task-envcfg` (and ideally `task-ecount`/`task-tags`) against a merged
commit to confirm the deliberate-error idiom is accepted and pass rates are
unchanged or improved.

<!-- CONTROLLER_TICKET_SNAPSHOT_END -->

## Factory context required before coding

The factory documents below are outside the XSH worktree. Before coding, use
the `read` tool on each exact absolute path. This is required so the session
JSONL proves that the worker consumed the current factory guidance:

- North star: `/Users/josh/d/laputa-systems/xsh-factory/NORTH-STAR.md`
- Shared handbook: `/Users/josh/d/laputa-systems/xsh-factory/runtime/handbook.md`

Then use the `read` tool on the product worktree's exact guidance files:

- Product agent guide: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785818570933/phases/01-ticket/worktrees/task-envcfg-001/AGENTS.md`
- XSH rationale: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785818570933/phases/01-ticket/worktrees/task-envcfg-001/docs/CHAPTER-01-why-xsh.md`

## Implementation contract

Work only in `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785818570933/phases/01-ticket/worktrees/task-envcfg-001` on branch `factory/task-envcfg-001/1785818571444`. Do not edit XSH main, the
factory main tree, or the ticket diagnosis. Make the smallest general XSH
language, tooling, test, or canonical-documentation change supported by the
ticket. Run the narrowest relevant checks, commit the product change on this
branch, and leave the worktree clean.

The controller has staged a fail-closed `not-ready` report at
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785818570933/phases/01-ticket/workers/engineer/task-envcfg-001/REPORT.md`. Complete that file in place; do not spend turns
reconstructing its headings. Keep `## Result` as `not-ready` until the
acceptance checks, commit, and clean-worktree validation are complete.

Write `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785818570933/phases/01-ticket/workers/engineer/task-envcfg-001/REPORT.md` with these exact headings:

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
