# Director assignment: ticket implementation

Read `{{FACTORY_DIR}}/NORTH-STAR.md`, `{{RUN_DIR}}/CYCLE-REQUEST.md`,
`{{RUN_DIR}}/PROVENANCE.md`, `{{RUN_DIR}}/TICKET-DISPATCH.md`, and
`{{FACTORY_DIR}}/roles/pi-session-briefing.md`. This is a
`ticket-implementation` cycle; do not launch an eval-manager, eval-worker,
or eval-designer.

The controller admitted the complete ticket set and created one immutable
assignment file per ticket. The dispatch table is the only worker list. For
each row, launch exactly one `xsh-swe` through the shared runner with that
row's exact ticket ID, worktree, assignment file, and assignment SHA-256. Do
not discover tickets, search the ticket directory, select a different ticket,
create a second worker for a row, or launch a worker absent from the table:

```sh
FACTORY_PARENT_ID=director FACTORY_TICKET_ID=<exact-ticket-id> \
FACTORY_ASSIGNMENT_SHA=<exact-assignment-sha> \
FACTORY_WORKDIR=<exact-worktree> \
xsh "{{RUN_AGENT}}" -- xsh-swe <exact-ticket-id> \
  "{{FACTORY_DIR}}/roles/xsh-swe.md" <exact-assignment-file>
```

The assignment inlines the controller-selected ticket and is the worker's
sole ticket authority. The runner rejects a mismatched or already-claimed
assignment before starting Pi. Wait for each child, inspect its session report
and `SWE-REPORT.md`, and do not merge any branch.

Finish `{{RUN_DIR}}/DIRECTOR-REPORT.md` with exactly these headings:

```markdown
## Result

pass or fail

## Cycle

mode, base commit, and admitted ticket count

## Children

one row per ticket with branch, commit, and report paths

## Required-output status

assignment, session, report, branch, commit, clean-worktree, and cost checks

## North-star impact

what the implementations advance and what remains for user review
```

Branches remain pending user review. Do not alter ticket diagnosis or status.
