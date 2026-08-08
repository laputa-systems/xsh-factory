# Controller-assigned engineer ticket

This is an immutable controller assignment for one implementation worker.
The controller, not the worker, selected the ticket, snapshot, worktree, and
branch.

## Assignment authority

- Ticket ID: `task-bigfiles-004`
- Ticket snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786191275308/phases/01-ticket/tickets/task-bigfiles-004.md`
- Ticket snapshot SHA-256: `877964577d8d7304df70671fac0821a2237645fb0f90bf441500305e78605584`
- Dedicated XSH worktree: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786191275308/task-bigfiles-004`
- Branch: `factory/task-bigfiles-004/1786191276307`
- XSH base commit: `c77b01a3e2fb676cc57cdeddbb7575be7723aa32`
- engineer report: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786191275308/phases/01-ticket/workers/engineer/task-bigfiles-004/REPORT.md`
- Factory root: `/Users/josh/d/laputa-systems/xsh-factory`
- Run evidence root: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786191275308/phases/01-ticket`

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
# Ticket task-bigfiles-004

## Status

Approved.

## CTO review — cycle-12 queue

- Decision: Approved for a later fresh implementation cycle, after the
  retained `task-bigfiles-002` branch is delivered.
- Basis: The linked replay produced one strong, reproducible API-reference
  observation: `fs.files` and `fs.walk` silently omit dot entries by default,
  while the contract does not state the default. The queue has high open-ticket
  pressure and this is the next unused focused product identity with a live
  linked eval, but cycle 12 must first validate the repaired delivery gate.
- Scope: Document `hidden: false` and dot-entry omission for `api:fs.files` and
  `api:fs.walk`; do not change runtime behavior.
- Required acceptance: a fresh engineer reference change passes focused native
  tests, and a linked replay selects the intended hidden behavior from the
  contract without relying on a fixture experiment.

## Change target

- `product`

Factory changes are CTO-owned. Do not create a factory-target ticket for
engineer dispatch; report the infrastructure change to the CTO instead.

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `fdeee37e911f820865dc617a14d61ec8e111c603`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-bigfiles`
- Shared handbook lineage: `runs/run-1786185105660/phases/02-reeval-task-bigfiles-002/lineage/handbook-approved.md`
- Manager run: `runs/run-1786185105660/phases/02-reeval-task-bigfiles-002/workers/eval-manager/task-bigfiles/REPORT.md`
- Executor run: `runs/run-1786185105660/phases/02-reeval-task-bigfiles-002/workers/eval-worker/task-bigfiles-1/session.jsonl.bz2`
- XSH baseline commit: `fdeee37e911f820865dc617a14d61ec8e111c603`

## Observation

The eval-worker wrote a recursively discovered regular-file report using
`fs.files(root, stat: true)?` and found that hidden dot entries were silently
omitted. A fixture containing `.hidden.txt`, run with and without
`hidden: true`, showed that the default `hidden=false` excludes dot entries;
only `fs.files(root, stat: true, hidden: true)` included them. The API purpose
and contract text do not state the `hidden` default or its dot-entry semantics.

## Evidence

- The worker session records the fixture probe and the final artifact's use of
  `hidden: true`.
- `xsht api api:fs.files` and `xsht api api:fs.walk` show a hidden option but
  do not state that its default is false or that dot entries are omitted.
- `/work/review.md` records the same reusable API-reference gap.
- All nine evaluator cases passed byte-for-byte after the worker selected
  `hidden: true`.

## Diagnosis or hypothesis

`fs.files` and `fs.walk` silently filter dot entries by default, and that
default is not documented. This is a general XSH learnability problem: a
recursive file-discovery program can look correct on visible-only trees and
quietly miss regular files on trees containing dot entries.

## North-star impact

Documenting the default and its dot-entry semantics makes recursive discovery
explicit and trustworthy, removing a silent behavior trap and the need for a
fixture experiment.

## Proposed XSH change

Add the `hidden` default and dot-entry filtering semantics to the `xsht api`
contracts for `fs.files` and `fs.walk`, with an API-reference regression test.
Do not change runtime behavior.

## API-surface justification

This is a documentation correction for an existing option, not a new builtin,
parser feature, evaluator change, or harness change.

## Acceptance criteria

- Both API entries state `hidden: false` and that dot entries are omitted.
- A reference test keeps that statement present.
- A linked replay reads the contract and selects the intended hidden behavior
  without relying on a fixture experiment, while all nine cases remain exact.

## Scope and non-goals

Out of scope: changing the default, traversal behavior, evaluator, harness, or
provider configuration.

## Post-merge evaluation

Replay `task-bigfiles` at the merged XSH commit and verify that the worker
selects the intended hidden behavior from the contract and remains byte-exact.

<!-- CONTROLLER_TICKET_SNAPSHOT_END -->

## Factory context required before coding

The factory documents below are outside the XSH worktree. Before coding, use
the `read` tool on each exact absolute path. This is required so the session
JSONL proves that the worker consumed the current factory guidance:

- North star: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786191275308/phases/01-ticket/guidance/NORTH-STAR.md`
- Approved handbook snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786191275308/phases/01-ticket/guidance/handbook.md`
- Handbook candidate: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786191275308/phases/01-ticket/lineage/handbook-candidate.md`

The approved snapshot is a run-scoped copy of the checked-in handbook. Read it
as an input and never edit it or the checked-in handbook. If this ticket
produces a reusable lesson, add it to the run-scoped candidate path above; the
candidate is shared review input and is promoted only after CTO review. If no
handbook improvement is justified, leave the candidate unchanged.

Then use the `read` tool on the product worktree's exact guidance files:

- Product agent guide: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786191275308/task-bigfiles-004/AGENTS.md`
- XSH rationale: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786191275308/task-bigfiles-004/docs/CHAPTER-01-why-xsh.md`

## Implementation contract

Work only in `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786191275308/task-bigfiles-004` on branch `factory/task-bigfiles-004/1786191276307`. Do not edit XSH main, the
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
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786191275308/phases/01-ticket/workers/engineer/task-bigfiles-004/REPORT.md`. Complete that file in place; do not spend turns
reconstructing its headings. Keep `## Result` as `not-ready` until the
acceptance checks, commit, and clean-worktree validation are complete.

Write `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786191275308/phases/01-ticket/workers/engineer/task-bigfiles-004/REPORT.md` with these exact headings:

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
