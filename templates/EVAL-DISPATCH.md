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

2. Optional role: `eval-designer`
   - Dispatch status: `{{DESIGNER_STATUS}}`
   - Worker ID: `{{DESIGNER_WORKER}}`
   - System prompt: `{{FACTORY_DIR}}/roles/eval-designer.md`
   - Message: `{{DESIGNER_MESSAGE}}`
   - Command:
     `FACTORY_PARENT_ID=director FACTORY_MODE=eval FACTORY_EVAL_ID= FACTORY_WORKER_ID={{DESIGNER_WORKER}} xsh "{{RUN_AGENT}}" -- eval-designer {{DESIGNER_WORKER}} "{{FACTORY_DIR}}/roles/eval-designer.md" "{{DESIGNER_MESSAGE}}"`
