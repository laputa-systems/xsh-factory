# Organization cycle plan

## Result

This is the controller-owned plan recorded before worker dispatch.

## Admission

- XSH base commit: `{{XSH_COMMIT}}`
- Selected ticket: `{{TICKET_ID}}`
- Linked eval: `{{EVAL_ID}}`
- Ticket policy: `{{TICKET_POLICY}}`

## Ordered phases

1. Primary phase: `{{PRIMARY_MODE}}` at `{{PRIMARY_PHASE}}`
2. Re-evaluation phase: `{{REEVAL_PHASE}}`
3. Eval-design phase: `{{DESIGN_PHASE}}`

The re-evaluation phase is dispatched only after a ticket implementation phase
produces a validated clean worktree. The eval-design phase is always
controller-dispatched once in this bounded cycle.
