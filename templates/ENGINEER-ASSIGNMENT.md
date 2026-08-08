# Controller-assigned engineer ticket

This is an immutable controller assignment for one implementation worker.
The controller, not the worker, selected the ticket, snapshot, worktree, and
branch.

## Assignment authority

- Ticket ID: `{{TICKET_ID}}`
- Ticket snapshot: `{{TICKET_PATH}}`
- Ticket snapshot SHA-256: `{{TICKET_SHA}}`
- Dedicated XSH worktree: `{{WORKTREE}}`
- Branch: `{{BRANCH}}`
- XSH base commit: `{{XSH_COMMIT}}`
- engineer report: `{{ENGINEER_REPORT}}`
- Factory root: `{{FACTORY_DIR}}`
- Run evidence root: `{{FACTORY_RUN_DIR}}`

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
{{TICKET_TEXT}}
<!-- CONTROLLER_TICKET_SNAPSHOT_END -->

## Factory context required before coding

The factory documents below are outside the XSH worktree. Before coding, use
the `read` tool on each exact absolute path. This is required so the session
JSONL proves that the worker consumed the current factory guidance:

- North star: `{{NORTH_STAR_FILE}}`
- Shared handbook: `{{HANDBOOK_FILE}}`

These are run-scoped snapshots of the checked-in factory guidance. Read them
as inputs; never edit them or any other factory file. A handbook improvement is
a CTO-owned promotion request, not part of an engineer product commit.

Then use the `read` tool on the product worktree's exact guidance files:

- Product agent guide: `{{XSH_AGENTS_FILE}}`
- XSH rationale: `{{XSH_RATIONALE_FILE}}`

## Implementation contract

Work only in `{{WORKTREE}}` on branch `{{BRANCH}}`. Do not edit XSH main, the
factory checkout, the run-scoped guidance snapshots, or the ticket diagnosis.
Make the smallest general XSH language, tooling, test, or
canonical-documentation change supported by the ticket. Run the narrowest
relevant checks, commit the product change on this branch, and leave the
worktree clean.

For ordinary product tickets, use `xsht lint --fix` for linting, then rerun the
relevant checks. If this ticket specifically targets lint, parsing, or
diagnostics, preserve the behavior under test and follow its explicit
acceptance procedure instead of auto-fixing away the evidence.

The controller has staged a fail-closed `not-ready` report at
`{{ENGINEER_REPORT}}`. Complete that file in place; do not spend turns
reconstructing its headings. Keep `## Result` as `not-ready` until the
acceptance checks, commit, and clean-worktree validation are complete.

Write `{{ENGINEER_REPORT}}` with these exact headings:

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
