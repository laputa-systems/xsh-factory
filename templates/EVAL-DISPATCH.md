# Controller dispatch

## Cycle

- Mode: `eval`
- Selected eval: `{{EVAL_ID}}`
- Trial count: `{{TRIAL_COUNT}}`
- New eval proposals: `{{NEW_EVAL_COUNT}}`
- XSH commit: `{{XSH_COMMIT}}`
- Shared handbook snapshot: `{{HANDBOOK_SNAPSHOT}}`

## Ordered children

1. Role: `eval-manager`
   - Worker ID: `{{EVAL_ID}}`
   - Eval ID: `{{EVAL_ID}}`
   - System prompt: `{{FACTORY_DIR}}/roles/eval-manager.md`
   - Message: `{{MANAGER_MESSAGE}}`
   - Command:
     `FACTORY_PARENT_ID=director FACTORY_MODE=eval FACTORY_EVAL_ID={{EVAL_ID}} FACTORY_WORKER_ID={{EVAL_ID}} xsh "{{RUN_AGENT}}" -- eval-manager {{EVAL_ID}} "{{FACTORY_DIR}}/roles/eval-manager.md" "{{MANAGER_MESSAGE}}"`

{{DESIGNER_ROW}}
