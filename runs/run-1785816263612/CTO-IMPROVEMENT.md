# CTO factory improvement

## Status

validated

`pending-validation` means the CTO has already implemented this change. It is
not awaiting another approval; the next cycle verifies the named metric or
applies the safe inverse.

## Change

Two controller/runtime fixes that unblocked and repaired the host-side agent
stack when the factory is launched from inside a Pi session and when an
approved ticket is replayed from a reused branch.

1. `run-agent.xsh` now clears `PI_PACKAGE_DIR` and `PI_STANDALONE_BINARY` from
   every child agent environment. XSH's `process.command_argv(..., env:)`
   merges over the inherited environment, so a factory launched from a
   standalone-embedded Pi session leaked those harness variables into host-side
   agent launches (manager/designer/director/engineer); `pi` then resolved a
   partial embedded package lacking `dist/modes/interactive/theme/dark.json`
   and crashed interactive theme init (ENOENT) before starting, leaving empty
   `not-ready` reports. Eval-workers were unaffected (self-contained Pi in
   Docker). Native test added in `tests/tools_test.xsh`
   (`test_run_agent_clears_pi_harness_env`).
2. `run-organization.xsh` gates the linked candidate replay on the right
   evidence in reuse mode. In reuse mode no engineer worker report exists (the
   branch is reused, not re-implemented), so `ticket_worker_pass(...)` returned
   `false` and short-circuited `run_child(...)`, and the linked candidate
   re-evaluation was never dispatched (empty phase dir, missing report). The
   controller now uses `phase_run_pass(primary_phase, "report.json")` as the
   precondition in reuse mode and the engineer worker report otherwise. Native
   assertions added in `tests/tools_test.xsh`
   (`test_organization_reuses_existing_branch_without_duplicate_dispatch`).

## Baseline metric

- Host-side agent reliability: in `runs/run-1785813489101` and
  `runs/run-1785813921392` the eval-manager and eval-designer reports were left
  as the empty `not-ready` template because their Pi sessions crashed at theme
  init (manager `workers/.../stderr.log`: `ENOENT
  .../dist/modes/interactive/theme/dark.json`), with no `session.jsonl.bz2`.
- Reuse-mode replay reliability: in `runs/run-1785812767635`,
  `runs/run-1785813489101`, and `runs/run-1785813921392` the
  `02-reeval-task-ecount-008` phase produced no `report.json` (empty phase
  dir), so the linked candidate replay never ran and the organization run was
  reported `fail`.

## Target metric

- A full organization cycle under an embedded-Pi session completes with a
  non-empty eval-manager report (a real `workers/eval-manager/<eval>/session.jsonl.bz2`
  and REPORT.md `## Result: pass`) and a real eval-designer report.
- A single-approved-ticket organization cycle reusing an existing branch
  produces a populated `phases/02-reeval-<ticket>/report.json` (linked replay
  actually dispatched) with `result` reflecting the evaluator, not `missing`.

## Validation

- `XSH_MODULE_PATH=. xsht test` passes (43 tests, including the two new
  source-assertion tests).
- In this cycle `runs/run-1785816263612`:
  - `phases/03-eval/workers/eval-manager/task-envcfg/REPORT.md` is a real
    `pass` report; `phases/04`/manager/designer sessions are non-empty.
  - `phases/02-reeval-task-ecount-008/report.json` exists with `result: fail`
    (the evaluator's timing gate), i.e. the replay was dispatched.
- Next cycle: run `XSH_MODULE_PATH=. xsht test`; confirm no `not-ready`
  manager/designer report from a full host-side session and no `missing`
  reeval phase report, then mark this record `validated`.

## Revert condition

- If a host-side agent again crashes reading
  `dist/modes/interactive/theme/dark.json` under `$PI_PACKAGE_DIR`, the
  `run-agent.xsh` clearing was ineffective (verify empty-string env is honored
  and `pi` still resolves its installed package); safe inverse is to restore
  full inherited env and instead unset the variables at the top-level launcher.
- If a reuse-mode replay regresses because the phase report is treated as
  sufficient when the branch is actually dirty/unvalidated, tighten
  `phase_run_pass` in reuse mode to also require the captured patch; safe
  inverse is to revert to `ticket_worker_pass` for reuse.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` (after the
named check) or `reverted` (with the safe inverse) before admitting paid work.
