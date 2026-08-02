- Ticket: `{{TICKET_ID}}`
  - Source: `tickets/{{TICKET_ID}}.md`
  - Worktree: `{{WORKTREE}}`
  - Branch: `{{BRANCH}}`
  - Base commit: `{{XSH_COMMIT}}`
  - Assignment: `messages/{{TICKET_ID}}.md`
  - Assignment SHA-256: `{{ASSIGNMENT_SHA}}`
  - Command: `FACTORY_PARENT_ID=director FACTORY_TICKET_ID={{TICKET_ID}} FACTORY_ASSIGNMENT_SHA={{ASSIGNMENT_SHA}} FACTORY_WORKDIR="{{WORKTREE}}" xsh "{{RUN_AGENT}}" -- engineer {{TICKET_ID}} "{{FACTORY_DIR}}/roles/engineer.md" "{{ASSIGNMENT_FILE}}"

