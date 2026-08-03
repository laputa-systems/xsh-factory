# Eval-designer assignment

Read `{{FACTORY_DIR}}/NORTH-STAR.md`, `{{FACTORY_DIR}}/FACTORY.md`,
`{{FACTORY_DIR}}/runtime/handbook.md`,
`{{FACTORY_DIR}}/../xsh/AGENTS.md` and relevant product docs/source,
`{{FACTORY_DIR}}/roles/eval-designer.md`, and the cycle request. The
controller has dispatched exactly one new proposal row. Do not redesign an
approved eval or invent additional proposals.

The adjacent XSH checkout is available for unrestricted inspection. Use it to
verify a targeted language contract, API, diagnostic, or native test pattern
when the handbook and scaffold do not answer the question. It is a reference,
not a second exploration project.
Do not modify that checkout: product changes remain an engineer/user decision.

Use `{{FACTORY_DIR}}/evals/task-tags/EVAL.md` and its `runtime/` directory as
the minimal structural reference. Keep the task no harder than ecount and
prefer a small practical systems-administration or programming capability.
The factory-wide handbook is `{{FACTORY_DIR}}/runtime/handbook.md`; proposed
evals must not create an eval-local handbook.

Keep this proposal small and bounded. Read the current cycle request, the
factory mission/contracts, the shared handbook, the product guide and
relevant product docs/source, and task-tags before choosing the task. Do not
scan historical `runs/`, Git history, or factory controllers such as
`run-eval.xsh` and `evaluate_common.xsh`. Do not write a custom runner, helper
language, shell wrapper, or Docker orchestration: edit the controller-provided
task-tags scaffold and make only task-specific edits. Use at most two exact
`xsht api` queries. After two focused scaffold corrections, stop and report
`not-ready`; do not spend the remaining session debugging infrastructure.

The controller has already staged the task-tags proposal scaffold and a
fail-closed `REPORT.md` skeleton. Edit `EVAL.md`, the runtime task/artifact
files, executor, and evaluator before beginning the dry run. The dry run
validates a materialized proposal; it is not a substitute for staging one.
Finish the report immediately after the dry run, changing `## Result` to
`ready-for-review` only when the proposal and evidence are complete. Finish
within the controller's hard turn and wall-clock bounds.

Stage the proposal under `{{RUN_DIR}}/proposals/{{WORKER_ID}}/` and preserve
the scaffolding and dry-run evidence there. Do not mark it Approved and do not
modify an approved eval. Write `{{RUN_DIR}}/workers/eval-designer/{{WORKER_ID}}/REPORT.md` with:

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
