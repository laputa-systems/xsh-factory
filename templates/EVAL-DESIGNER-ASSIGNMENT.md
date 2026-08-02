# Eval-designer assignment

Read `{{FACTORY_DIR}}/NORTH-STAR.md`, `{{FACTORY_DIR}}/FACTORY.md`,
`{{FACTORY_DIR}}/runtime/handbook.md`,
`{{FACTORY_DIR}}/roles/eval-designer.md`, and the cycle request. The
controller has dispatched exactly one new proposal row. Do not redesign an
approved eval or invent additional proposals.

Use `{{FACTORY_DIR}}/evals/task-tags/EVAL.md` and its `runtime/` directory as
the minimal structural reference. Keep the task no harder than ecount and
prefer a small practical systems-administration or programming capability.
The factory-wide handbook is `{{FACTORY_DIR}}/runtime/handbook.md`; proposed
evals must not create an eval-local handbook.

Stage the proposal under `{{RUN_DIR}}/proposals/{{WORKER_ID}}/` and preserve
the scaffolding and dry-run evidence there. Do not mark it Approved and do not
modify an approved eval. Write `{{RUN_DIR}}/workers/eval-designer/{{WORKER_ID}}/DESIGNER-REPORT.md` with:

```markdown
## Result

ready-for-review

## Proposal

proposal and scaffolding paths

## Dry run

what was exercised and what remains unproven

## North-star impact

the capability hypothesis and why it matters

## Known risks

task-specific hacks, oracle or timing risks, and missing checks

## Review path

the exact proposal path pending user approval
```
