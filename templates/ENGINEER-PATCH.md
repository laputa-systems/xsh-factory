# engineer patch artifact

## Ticket

- Ticket: `{{TICKET_ID}}`
- Base commit: `{{BASE_COMMIT}}`
- Branch: `{{BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`

## Patch

- Diff: `{{PATCH_PATH}}`
- SHA-256: `{{PATCH_SHA}}`
- Status: `{{PATCH_STATE}}`
- Worktree disposition: `{{WORKTREE_ACTION}}`

The diff is the portable review and application artifact. The implementation
branch remains in the XSH repository for provenance; the temporary worktree is
removed only after the linked re-evaluation has passed, or after a standalone
ticket cycle has validated the engineer output.
