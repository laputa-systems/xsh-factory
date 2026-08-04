# Eval-designer assignment

Read `/Users/josh/d/laputa-systems/xsh-factory/NORTH-STAR.md`, `/Users/josh/d/laputa-systems/xsh-factory/FACTORY.md`,
`/Users/josh/d/laputa-systems/xsh-factory/runtime/handbook.md`,
`/Users/josh/d/laputa-systems/xsh-factory/roles/eval-designer.md`, and the cycle request. The
controller has dispatched exactly one new proposal row. Do not redesign an
approved eval or invent additional proposals.

Use `/Users/josh/d/laputa-systems/xsh-factory/evals/task-tags/EVAL.md` and its `runtime/` directory as
the minimal structural reference. Keep the task no harder than ecount and
prefer a small practical systems-administration or programming capability.
The factory-wide handbook is `/Users/josh/d/laputa-systems/xsh-factory/runtime/handbook.md`; proposed
evals must not create an eval-local handbook.

Keep this proposal small and bounded. Read only the current cycle request,
the factory mission/contracts, the shared handbook, and task-tags before
choosing the task. Do not scan historical `runs/`, Git history, `.dist`, or
the XSH source tree. Do not write a custom runner, helper language, shell
wrapper, or Docker orchestration; reuse the existing task-tags executor shape
and make only task-specific edits. Use at most two exact `xsht api` queries.
After two focused scaffold corrections, stop and report `not-ready`; do not
spend the remaining session debugging an infrastructure design. Create the
required report early and finish within the controller's hard turn and
wall-clock bounds.

Stage the proposal under `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785722327478/phases/04-eval-design/proposals/proposal-1/` and preserve
the scaffolding and dry-run evidence there. Do not mark it Approved and do not
modify an approved eval. Write `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785722327478/phases/04-eval-design/workers/eval-designer/proposal-1/REPORT.md` with:

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
