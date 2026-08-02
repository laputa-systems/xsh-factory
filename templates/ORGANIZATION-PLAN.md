# Organization cycle plan

## Result

This is the controller-owned plan recorded before worker dispatch.

## Admission

- XSH base commit: `{{XSH_COMMIT}}`
- Selected ticket: `{{TICKET_ID}}`
- Ticket eval: `{{TICKET_EVAL_ID}}`
- Independent eval: `{{INDEPENDENT_EVAL_ID}}`
- Ticket policy: `{{TICKET_POLICY}}`

## Phase schedule

1. Start primary phase: `{{PRIMARY_MODE}}` at `{{PRIMARY_PHASE}}`
2. Start eval-design phase: `{{DESIGN_PHASE}}`
3. After ticket implementation passes, start re-evaluation at `{{REEVAL_PHASE}}`
4. Run independent eval at `{{INDEPENDENT_EVAL_PHASE}}` after the required
   ticket path

The re-evaluation phase is dispatched only after a ticket implementation phase
produces a validated clean worktree. The eval-design phase is independent and
overlaps the primary phase. The independent eval runs against XSH main after
the required ticket path. The eval-design phase is always controller-dispatched
once in this bounded cycle.
