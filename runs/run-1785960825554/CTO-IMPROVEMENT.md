# CTO factory improvement

## Status

pending-validation

## Change

The evaluator infrastructure now uses the direct `ProcessStatus` returned by
`process.run` in the package evaluators that had this defect:
`task-findexec`, `task-propsort`, `task-render`, `task-setdiff`, and
`task-trim`. The audit compiler also accepts the package evaluator's concise
`correctness.exact` field in addition to `passed` and `all_exact`.

Native regression coverage in `tests/tools_test.xsh` executes a direct
`process.run` fixture, checks the affected evaluators for invalid nested
`.status` access, and audits a manifest using `correctness.exact`.

## Throughput requirement

Zero engineer implementation commits were produced. This was an intentional
eval-only cycle: the previously Open tickets remained blocked by their
recorded factory ownership, retired eval, API-quality, or replay conditions.
The cycle nevertheless produced a valid product signal and one new
product-ticket recommendation, `task-findexec-001`.

## Provider-health attribution

Provider telemetry was present for both workers. Retries were zero; provider
errors and response timing were unknown. The earlier evaluator crash was a
factory contract defect, not provider instability.

## Baseline metric

The prior verification run, `runs/run-1785960125254/report.json`, had a valid
worker `run.json` but failed the phase audit because its concise
`correctness.exact` field was not recognized. The original failure was
`runs/run-1785958228987`, where `task-findexec` crashed on
`missing-field: status`. Both runs produced no engineer commits.

## Target metric

A fresh organization cycle must produce a passing evaluator phase with a
populated `run.json`, a passing audit, and no evaluator contract error. The
next paid organization cycle should dispatch an engineer only if
`task-findexec-001` or another product ticket passes the CTO approval and
replay gates.

## Validation

Validated by `XSH_MODULE_PATH=. xsht test` (`81 passed; 0 failed`) and
`runs/run-1785960825554/report.json`: product, evaluator, and infrastructure
outcomes are all `pass`; `required_outputs.required` is `true`; and the
worker evaluator produced `run.json` with `correctness.exact=true`.

## Revert condition

If a future package evaluator again crashes on a direct `process.run` result,
or if the audit rejects a valid package manifest using `correctness.exact`,
restore the affected contract only after adding a focused native regression
fixture. Do not revert the fixes merely because a candidate artifact fails its
own correctness or restriction gate.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted`
after the named native and fresh-cycle checks, linking the evidence before
admitting paid work.
