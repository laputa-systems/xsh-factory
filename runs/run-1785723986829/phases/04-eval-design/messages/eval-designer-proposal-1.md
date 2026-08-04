# Eval-designer assignment

Read `/Users/josh/d/laputa-systems/xsh-factory/NORTH-STAR.md`, `/Users/josh/d/laputa-systems/xsh-factory/FACTORY.md`,
`/Users/josh/d/laputa-systems/xsh-factory/runtime/handbook.md`,
`/Users/josh/d/laputa-systems/xsh-factory/../xsh/AGENTS.md` and relevant product docs/source,
`/Users/josh/d/laputa-systems/xsh-factory/roles/eval-designer.md`, and the cycle request. The
controller has dispatched exactly one new proposal row. Do not redesign an
approved eval or invent additional proposals.

The adjacent XSH checkout is available for unrestricted inspection. Use it to
verify current language contracts, APIs, diagnostics, and native test patterns.
Do not modify that checkout: product changes remain an engineer/user decision.

Use `/Users/josh/d/laputa-systems/xsh-factory/evals/task-tags/EVAL.md` and its `runtime/` directory as
the minimal structural reference. Keep the task no harder than ecount and
prefer a small practical systems-administration or programming capability.
The factory-wide handbook is `/Users/josh/d/laputa-systems/xsh-factory/runtime/handbook.md`; proposed
evals must not create an eval-local handbook.

Keep this proposal small and bounded. Read the current cycle request, the
factory mission/contracts, the shared handbook, the product guide and
relevant product docs/source, and task-tags before choosing the task. Do not
scan historical `runs/` or Git history. Do not write a custom runner, helper
language, shell wrapper, or Docker orchestration; reuse the existing task-tags
executor shape and make only task-specific edits. Use at most two exact
`xsht api` queries. After two focused scaffold corrections, stop and report
`not-ready`; do not spend the remaining session debugging an infrastructure
design. Create the required report headings and stage `EVAL.md`, runtime
task/artifact files, executor, and evaluator before beginning the dry run.
The dry run validates a materialized proposal; it is not a substitute for
staging one. Finish within the controller's hard turn and wall-clock bounds.

Stage the proposal under `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785723986829/phases/04-eval-design/proposals/proposal-1/` and preserve
the scaffolding and dry-run evidence there. Do not mark it Approved and do not
modify an approved eval. Write `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785723986829/phases/04-eval-design/workers/eval-designer/proposal-1/REPORT.md` with:

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
