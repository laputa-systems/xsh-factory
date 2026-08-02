# Organization cycle plan

## Result

This is the controller-owned plan recorded before worker dispatch.

## Admission

- XSH base commit: `{{XSH_COMMIT}}`
- Selected ticket: `{{TICKET_ID}}`
- Ticket eval: `{{TICKET_EVAL_ID}}`
- Independent eval: `{{INDEPENDENT_EVAL_ID}}`
- Ticket policy: `{{TICKET_POLICY}}`

## Ordered phases

1. Primary phase: `{{PRIMARY_MODE}}` at `{{PRIMARY_PHASE}}`
2. Re-evaluation phase: `{{REEVAL_PHASE}}`
3. Independent eval phase: `{{INDEPENDENT_EVAL_PHASE}}`
4. Eval-design phase: `{{DESIGN_PHASE}}`

The re-evaluation phase is dispatched only after a ticket implementation phase
produces a validated clean worktree. When a ticket is admitted, the
independent eval runs against XSH main after the candidate replay. The
eval-design phase is always controller-dispatched once in this bounded cycle.
