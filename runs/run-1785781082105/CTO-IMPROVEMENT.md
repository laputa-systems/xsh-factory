# CTO factory improvement

## Status

pending-validation

`pending-validation` means the CTO has implemented this change. The next cycle
verifies the named metric or applies the safe inverse; no additional approval
is required.

## Change

Make the eval-worker environment boundary explicit. The role prompt now states
that task images are Alpine-based with BusyBox `sh`, not `bash`, and that XSH
uses `and`/`or` rather than shell `&&`/`||`. A native prompt-contract test keeps
this guidance from regressing.

Paths: `roles/eval-worker.md` and
`tests/tools_test.xsh::test_eval_worker_prompt_matches_task_image`.

## Baseline metric

The current `task-envcfg` worker incurred 9 tool errors; one was `bash: not
found` and another was a shell syntax error. Evidence:
`phases/01-eval/workers/eval-worker/task-envcfg-1/report.json` and the manager
report at `phases/01-eval/workers/eval-manager/task-envcfg/REPORT.md`.

## Target metric

The next eval-worker session has zero tool errors caused by invoking unavailable
`bash` or by using shell-only boolean syntax in an XSH probe.

## Validation

Run `XSH_MODULE_PATH=. xsht test` and the next paid eval cycle; inspect the
worker `tool_errors` array and manager classification for those exact causes.

## Revert condition

Revert the prompt addition if a later task image provides `bash` and the added
guidance causes a valid task workflow to fail, or if the next worker still
produces the same errors despite following the instruction. Preserve that
cycle's evidence before reverting.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted`
after running the named checks and linking the evidence before admitting more
paid work.
