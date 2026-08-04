# Eval-designer assignment

Read `/Users/josh/d/laputa-systems/xsh-factory/NORTH-STAR.md`, `/Users/josh/d/laputa-systems/xsh-factory/FACTORY.md`,
`/Users/josh/d/laputa-systems/xsh-factory/runtime/handbook.md`,
`/Users/josh/d/laputa-systems/xsh-factory/../xsh/AGENTS.md`,
`/Users/josh/d/laputa-systems/xsh-factory/roles/eval-designer.md`, and the cycle request.

The controller dispatched one new proposal row. Do not redesign an approved eval
or invent another proposal.

The adjacent XSH checkout is a reference. Do not modify it. Product changes
require an approved ticket, an isolated engineer worktree, and a CTO decision.

The task must be no harder than ecount. Use `evals/task-tags/EVAL.md` and its
`runtime/` directory as the structural reference. Proposed evals must consume
the shared `/Users/josh/d/laputa-systems/xsh-factory/runtime/handbook.md`.

## State machine

### 1. Select the task

Choose one small practical XSH capability. Replace the scaffold's `task-tags`
ID before API queries or dry-run work. Use a new valid `task-*` ID. Change
`Disabled.` to `Draft.`.

Do not scan `runs/`, Git history, or factory controllers. Do not write a custom
runner, helper language, shell wrapper, or Docker orchestration. Use at most two
exact `xsht api` queries.

### 2. Materialize the package

Edit `EVAL.md`, `runtime/task.md`, `runtime/artifact.md`, `executor.xsh`, and
`evaluator.xsh` under `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785876949561/phases/04-eval-design/proposals/proposal-1/`.

Include the task contract, artifact name, oracle, hidden cases, agent boundary,
metrics, manager policy, and all required scaffolding. Keep the proposal as
`Draft.`. Do not modify an approved eval.

### 3. Check the package

After the package files exist, run the smallest available syntax or reference
check. Fix at most two focused scaffold errors.

If the evaluator is valid after the correction limit, stop discovery. Write the
report immediately. Do not build a localized evaluator, negative-control
harness, custom oracle runner, or candidate implementation.

If the package is incomplete, write `not-ready` and name the missing evidence.
Do not claim dry-run evidence that was not saved under the proposal.

### 4. Write the report

Write `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785876949561/phases/04-eval-design/workers/eval-designer/proposal-1/REPORT.md` with exactly
these headings:

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

the exact promoted eval path and the evidence for the CTO approval decision
```

Use `ready-for-review` only when the package and evidence are complete. Use
`not-ready` when required evidence is missing. The CTO review gate decides the
package status after the session.
