# Organization run {{RUN_ID}}

## Result

{{RESULT}}

## North-star status

This bounded cycle connects approved ticket implementation, pre-merge
re-evaluation, and an optional eval-design proposal without allowing a worker
to select its own work.

## Admission

- Request: `CYCLE-REQUEST.md`
- Ticket: `{{TICKET_ID}}`
- Ticket eval: `{{TICKET_EVAL_ID}}`
- Independent eval: `{{INDEPENDENT_EVAL_ID}}`
- XSH base commit: `{{XSH_COMMIT}}`

## Phase schedule

1. Primary phase: `{{PRIMARY_MODE}}` is `{{PRIMARY_STATE}}` at `{{PRIMARY_PHASE}}`
2. Eval design: `{{DESIGN_STATE}}` at `{{DESIGN_PHASE}}` (overlaps the primary phase when requested)
3. Ticket re-evaluation: `{{REEVAL_STATE}}` at `{{REEVAL_PHASE}}` (waits for the primary patch)
4. Independent eval: `{{INDEPENDENT_EVAL_STATE}}` at `{{INDEPENDENT_EVAL_PHASE}}` (overlaps ticket implementation)

## Required outputs

- Primary phase report: `{{PRIMARY_REPORT_STATE}}`
- Re-evaluation phase report: `{{REEVAL_REPORT_STATE}}`
- Independent eval phase report: `{{INDEPENDENT_EVAL_REPORT_STATE}}`
- Eval-design phase report: `{{DESIGN_REPORT_STATE}}`
- Patch artifact: `{{PATCH_ARTIFACT}}`
- Worktree lifecycle: `{{WORKTREE_STATE}}`
- Aggregate cost report: `{{COST_STATE}}`
- Deterministic audit: `{{AUDIT_STATE}}`
- CTO briefing: `{{CTO_STATE}}`

Each phase retains its own `RUN.md`, `AUDIT.md`, provenance, session reports,
and raw worker evidence. Product branches and eval proposals remain pending
user review.
