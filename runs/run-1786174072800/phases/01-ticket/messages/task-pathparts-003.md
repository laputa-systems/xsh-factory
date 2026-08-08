# Controller-assigned engineer ticket

This is an immutable controller assignment for one implementation worker.
The controller, not the worker, selected the ticket, snapshot, worktree, and
branch.

## Assignment authority

- Ticket ID: `task-pathparts-003`
- Ticket snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786174072800/phases/01-ticket/tickets/task-pathparts-003.md`
- Ticket snapshot SHA-256: `ac37a1e61c1f68bdac7e2d5e808fb69298372b7d90f73b808ad6e830510fef14`
- Dedicated XSH worktree: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786174072800/task-pathparts-003`
- Branch: `factory/task-pathparts-003/1786174073904`
- XSH base commit: `e4059a21ae8942fa07a0e8e61bac971ed703237c`
- engineer report: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786174072800/phases/01-ticket/workers/engineer/task-pathparts-003/REPORT.md`
- Factory root: `/Users/josh/d/laputa-systems/xsh-factory`
- Run evidence root: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786174072800/phases/01-ticket`

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
# Ticket task-pathparts-003

## Status

Approved.

## CTO decision — pre-cycle-7

- Decision: Approved for one fresh engineer row.
- Basis: The prerequisite `task-pathparts-002` delivery and the repaired
  audit/reconciliation boundary both passed in
  `runs/run-1786170696452`. The remaining observation is focused and
  reproducible: `xsht lint` flags locals read only inside display-string
  interpolation, despite the handbook recommending display strings for exact
  output. The ticket has isolated acceptance criteria and a second
  output-composing replay requirement.
- Scope: Fix lint reference collection for display-string interpolation and add
  the smallest regression coverage. Preserve display-string semantics,
  `+`-concatenation behavior, and the task contract; do not revisit the
  path-constructor advisory.

## CTO review

- Review cycle: post-cycle-4.
- Decision: Deferred; do not approve or dispatch yet.
- Basis: The lint false positive is strong, reproducible product evidence,
  but the current approved `task-pathparts-002` branch must be replayed and
  delivered first; admit this follow-on only after the corrected aggregation
  boundary is validated and the proposed read-analysis fix has an isolated
  acceptance run.
- Next evidence: Require a focused display-string lint regression and a
  second output-composing replay before approval.

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

- Eval: `task-pathparts`
- Shared handbook lineage: `runs/run-1786167293099/phases/02-reeval-task-pathparts-002/lineage/handbook-approved.md`
- Manager run: `runs/run-1786167293099/phases/02-reeval-task-pathparts-002/workers/eval-manager/task-pathparts/`
- Executor run: `runs/run-1786167293099/phases/02-reeval-task-pathparts-002/workers/eval-worker/task-pathparts-1/`
- XSH baseline commit: `9bbc473af32e20e7bb3fa9b967a51acd89eb5200`

## Observation

`xsht lint` reports `warn[lint.unused-local]` (and exits with code 1) for a
local variable that IS read inside a display-string (`f"..."`) interpolation.
In `task-pathparts` the worker wrote `print f"dir=$dir"` where `dir` is a
local binding that the f-string interpolates. Lint flags `dir` as an unused
local ("binding is never read") and exits nonzero, even though the variable is
plainly used and the program runs correctly. The handbook explicitly
recommends display strings for composing exact dynamic output, so the tool's
own documented idiom hard-fails its own quality check.

## Evidence

- Session `task-pathparts-1/session.jsonl.bz2`, turns 13 and 16: running
  `xsht lint` on `proc main(...argv: List[Str]) { ... print f"dir=$dir"; ... }`
  produced
  `warn[lint.unused-local]: unused local variable dir ... binding is never read`
  and `Command exited with code 1`, for each of `dir`, `name`, and `ext`.
- The same session verified the workaround: rewriting as
  `let ld = "dir=" + dir; print $ld` makes `xsht lint` exit 0. So the
  concatenation form is accepted while the display-string form is not.
- The program's runtime output was correct for every case, confirming the
  f-string interpolation reads the variable and the lint warning is a false
  positive.
- The worker's `review.md` (field `## xsht friction`) records the same finding
  independently.
- No invalid `xsht api` discovery query is implicated; the false positive is a
  lint read-analysis behavior, not agent error.

## Diagnosis or hypothesis

This is a general XSH ergonomics/trust defect, not task-specific confusion.
The handbook's own guidance ("Use a display string `f"host=${host} port=${port}"`
to compose exact dynamic text") leads an agent straight into a lint failure
because the unused-local analysis does not count a read inside an f-string
template as a use of the interpolated binding. Any program that composes output
from a local value through a display string and then reuses that same value
elsewhere (or alone) can be flagged. This is the same class of internally
inconsistent surface as the lint/restriction tension in `task-pathparts-002`:
a documented, correct idiom fails the factory's own visible check, so the agent
must guess a workaround (here, `+` concatenation) that the handbook does not
teach as the preferred form. The `+` workaround is not wrong, but the lint
should not hard-fail the documented display-string idiom on a false positive.

## North-star impact

The north star targets ergonomics ("fewer guesses, workarounds, ... repeated
discoveries") and trustworthy, learnable surfaces. A lint that reports an
unused-local false positive on the handbook-recommended display-string form
forces agents to discover a non-obvious workaround and erodes trust in the
tool's guidance. Fixing the read-analysis so f-string interpolation counts as a
read lets agents follow the documented idiom without a workaround. Evidence of
generalization: a second eval whose solution composes output via display
strings passing `xsht lint` without the concatenation workaround, plus the
replay in `## Post-merge evaluation`.

## Proposed XSH change

Fix `xsht lint`'s unused-local read analysis so that a local binding
interpolated inside a display string (`f"...$name..."`) is counted as a read
(the name is dereferenced in the template). The smallest change is in the
lint's reference collection for the `f"..."` AST node, mirroring how it already
treats `$name` dereferences in print/expression position. Keep the `+`
concatenation spelling as an accepted alternative; do not change the
display-string semantics, the language, or the runtime.

## Acceptance criteria

- `xsht lint` reports no `unused-local` for a local that is read only inside a
  display-string interpolation, and exits 0 on such a program.
- `xsht lint` still reports `unused-local` for a genuinely unused local (no
  false negatives).
- The `task-pathparts` solution can be written with `print f"dir=$dir"` (or
  equivalent display strings) and pass `xsht check`, `fmt`, and `lint` without
  the concatenation workaround.
- Eval contract, fixture cases, and oracle are unchanged.

## Scope and non-goals

- No change to display-string language semantics, `print`, or the runtime.
- No change to the `task-pathparts` task contract, fixture cases, or oracle.
- Does not overlap the `task-pathparts-002` path-constructor lint advisory,
  which is a separate severity/exit-code change; this ticket targets the
  unused-local read-analysis itself.

## Post-merge evaluation

Replay `task-pathparts` against the merged build and record whether the worker
can compose the three output lines with display strings and pass
`xsht check`/`fmt`/`lint` without the `+` workaround, and whether a second
output-composing eval confirms the same. The linked eval-manager records
accept/reject.

<!-- CONTROLLER_TICKET_SNAPSHOT_END -->

## Factory context required before coding

The factory documents below are outside the XSH worktree. Before coding, use
the `read` tool on each exact absolute path. This is required so the session
JSONL proves that the worker consumed the current factory guidance:

- North star: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786174072800/phases/01-ticket/guidance/NORTH-STAR.md`
- Approved handbook snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786174072800/phases/01-ticket/guidance/handbook.md`
- Handbook candidate: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786174072800/phases/01-ticket/lineage/handbook-candidate.md`

The approved snapshot is a run-scoped copy of the checked-in handbook. Read it
as an input and never edit it or the checked-in handbook. If this ticket
produces a reusable lesson, add it to the run-scoped candidate path above; the
candidate is shared review input and is promoted only after CTO review. If no
handbook improvement is justified, leave the candidate unchanged.

Then use the `read` tool on the product worktree's exact guidance files:

- Product agent guide: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786174072800/task-pathparts-003/AGENTS.md`
- XSH rationale: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786174072800/task-pathparts-003/docs/CHAPTER-01-why-xsh.md`

## Implementation contract

Work only in `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786174072800/task-pathparts-003` on branch `factory/task-pathparts-003/1786174073904`. Do not edit XSH main, the
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
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786174072800/phases/01-ticket/workers/engineer/task-pathparts-003/REPORT.md`. Complete that file in place; do not spend turns
reconstructing its headings. Keep `## Result` as `not-ready` until the
acceptance checks, commit, and clean-worktree validation are complete.

Write `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786174072800/phases/01-ticket/workers/engineer/task-pathparts-003/REPORT.md` with these exact headings:

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
