# CTO factory improvement

## Status

reverted

## Disposition

The prior request rotation selected `task-col2`, but that eval is now `Disabled.` and cannot satisfy the independent-eval manifest target. The current organization request has been corrected to select the next live untried approved eval, `task-groupsum`; the invalid selection is therefore safely reverted rather than validated.

## Evidence

- `evals/task-col2/EVAL.md` — `Disabled.`
- `cycle-organization.md` — current independent eval is `task-groupsum`.
- `XSH_MODULE_PATH=. xsht test` — 62 tests passed, including untried-eval selection and organization request policy tests.

## Change

The organization request now separates the linked ticket replay from the
independent-eval rotation: `cycle-organization.md` selects the next untried
approved eval (`task-col2`) while retaining `task-bigfiles` as the ticket's
linked replay. The cycle also produced a fresh engineer commit and the CTO
merged it into XSH main.

## Throughput requirement

The cycle produced one fresh, reviewable engineer implementation commit for
`task-bigfiles-001`: `e5d29c7ec8b4411dc749fd3e44bf472d641ad9f4`, subsequently
merged to XSH main. The linked replay passed. The independent `task-col2`
phase failed at the evaluator packaging boundary and did not produce a valid
trial manifest; this is an evaluator/infrastructure failure, not an engineer
failure.

## Provider-health attribution

Provider telemetry was present for all seven workers. Retries were zero and no
provider errors were reported; response timing was not populated. The three
observed tool errors are agent-side workflow errors, not provider-health
signals.

## Baseline metric

Prior run `runs/run-1785887678360/report.json`: zero engineer commits, 93
turns, and $0.074526. This organization run
`runs/run-1785888999833/report.json`: one engineer commit, 167 turns, and
$0.118816. The product phase and linked replay passed; the independent eval
failed because no `task-col2` evaluator manifest was generated.

## Target metric

The next organization cycle must preserve at least one merged engineer commit,
pass its linked replay, and make the independent eval produce a valid
`run.json` trial manifest with `required_outputs.required: true`. Target total
cost is at or below $0.118816 unless a second product result is delivered.

## Validation

Run `XSH_MODULE_PATH=. xsht test`, confirm the XSH checkout is clean, then run
`XSH_MODULE_PATH=. xsh run.xsh cycle-organization.md`. Inspect the root report
for `mode: organization`, `phases/01-ticket/report.json: result=pass`, a merged
XSH commit, and `phases/03-eval/report.json` with a valid task-col2 trial
manifest. Separately verify the promoted `evals/task-colsum/EVAL.md` package
before admitting it.

## Revert condition

If the independent eval again fails with no evaluator manifest, fix the
package-owned/controller evaluator wiring before further paid organization
work; do not revert the engineer product change. Revert the request rotation
only if it selects an unavailable or already-tried eval despite the
next-untried admission invariant.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted`
after the named verification and link the evidence before admitting paid work.
