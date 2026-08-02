2. Role: `eval-designer`
   - Worker ID: `{{WORKER_ID}}`
   - Eval ID: ``
   - System prompt: `{{FACTORY_DIR}}/roles/eval-designer.md`
   - Message: `{{DESIGNER_MESSAGE}}`
   - Working directory: `{{FACTORY_DIR}}`
   - Command:
     `FACTORY_PARENT_ID=director FACTORY_MODE=eval FACTORY_EVAL_ID= FACTORY_WORKER_ID={{WORKER_ID}} FACTORY_WORKDIR="{{FACTORY_DIR}}" xsh "{{RUN_AGENT}}" -- eval-designer {{WORKER_ID}} "{{FACTORY_DIR}}/roles/eval-designer.md" "{{DESIGNER_MESSAGE}}"`
