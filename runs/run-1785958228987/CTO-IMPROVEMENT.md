# CTO factory improvement

## Status

pending-validation

## Change

The cycle-request contract now treats Markdown requests as templates under
`templates/`. `run.xsh` rejects request paths outside that directory, and the
organization controller persists the immutable request as
`runs/run-<id>/CYCLE-REQUEST.md`. All historical top-level `cycle-*.md` request
files were removed. Native coverage now reads the organization template.

## Throughput requirement

Zero reviewable engineer implementation commits were produced because every
Open ticket was correctly blocked: three are factory-owned, one links a
retired eval, and the remaining product observations retain explicit
quality/replay deferrals. This was an intentional eval-only cycle, but it is a
throughput failure rather than product progress. The cycle's evaluator also
failed before emitting a manifest due to a factory evaluator defect
(`missing-field: status`).

## Provider-health attribution

Provider telemetry was present for both workers. Retries were zero; provider
errors and response timing were unknown. The evaluator failure is therefore
infrastructure evidence, not provider-health evidence.

## Baseline metric

Prior run `runs/run-1785949651175/report.json` produced zero engineer commits,
one valid `task-svcstat` manifest, 75 turns, and `$0.052796`. This run
`runs/run-1785958228987/report.json` produced zero engineer commits, 36 turns,
`$0.023187366`, and zero evaluator manifests because the package evaluator
accessed an unavailable `status` field.

## Target metric

Before the next paid cycle, the evaluator boundary must produce a populated
manifest for a fresh `task-findexec` replay with no `missing-field: status`
startup/runtime failure. The request contract must pass a template-path test,
and the next organization cycle must either produce one engineer commit after
a ticket becomes eligible or explicitly retain the blocked-ticket decision.

## Validation

Run `XSH_MODULE_PATH=. xsht test`; verify no top-level `cycle-*.md` files exist;
run `XSH_MODULE_PATH=. xsh run.xsh templates/ORGANIZATION-REQUEST.md` only after
repairing the package evaluator; then inspect the root report for
`phases/01-eval` evaluator `run.json` and a non-empty manifest.

## Revert condition

If `run.xsh` accepts a request outside `templates/`, or a cycle again leaves a
request outside `runs/run-<id>/CYCLE-REQUEST.md`, revert the path-boundary
change and add a focused admission test before spending. If the evaluator
still reports `missing-field: status`, do not admit paid replay; repair the
package-owned evaluator contract and preserve this failed evidence.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted`
after the named request-boundary and evaluator checks, linking the evidence
before admitting paid work.
