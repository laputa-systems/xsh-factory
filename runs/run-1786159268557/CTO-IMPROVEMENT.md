# CTO factory improvement

## Status

validated

The throughput package implemented before this cycle met its named validation
target. The admission postmortem was also closed by the deterministic ticket
normalization and regression test that allowed the next approved ticket to be
admitted.

## Change

The reusable factory changes are recorded in `factory/entrypoints/run-agent.xsh`,
`factory/controllers/organization.xsh`, `factory/controllers/reuse.xsh`,
`factory/runtime.xsh`, and `factory/tools/audit.xsh`. They provide run-scoped
handbook quarantine, overlap of independent and linked work, retained-branch
fast-path accounting, sibling salvage, and throughput metrics projected into
the existing run `report.json` rather than a new `throughput.json` schema.

The admission correction is in `tickets/task-render-001.md` and
`tests/factory_control_test.xsh`, with the rejected-at-admission evidence
preserved in [the postmortem](../run-1786159068132/POSTMORTEM.md).

## Throughput requirement

Met. The cycle produced one validated engineer implementation commit and
delivered it to XSH `HEAD`:
`461fe36bfd0d1ca5670777e2ea1531f902e88558`. The root report is `pass`, with
one admitted ticket, one fresh engineer row, one passing linked replay, and
one delivered ticket. The engineer dispatch recorded
`factory_source: unchanged`.

## Provider-health attribution

Provider telemetry was captured for all six workers. Retry counts are zero,
costs are known, and no provider-health failure is indicated. The `17` tool
errors are retained in the structured report and are agent/tool-use churn, not
an attribution to the provider.

## Baseline metric

The preceding paid implementation attempt,
[run-1786155403216](../run-1786155403216/report.json), delivered zero product
commits and ended with product/evaluator failure. It used one worker, `32`
assistant turns, and `$0.03418991`; its source-integrity guard correctly stopped
the contaminated downstream path. The admission-only postmortem
[run-1786159068132](../run-1786159068132/POSTMORTEM.md) then identified the
capitalization mismatch in the ticket admission marker.

## Target metric

The next paid organization cycle was required to deliver at least one
validated product commit, pass its linked replay, leave factory source
unchanged, and expose throughput counts in the existing root report.

## Validation

This cycle used the documented launcher once:

    XSH_MODULE_PATH=. xsh run.xsh templates/ORGANIZATION-REQUEST.md

Validation evidence is [report.json](report.json): `result: pass`, product,
evaluator, and infrastructure outcomes all `pass`,
`throughput.delivered_tickets: 1`, and the implementation commit reachable from
XSH `HEAD`. The linked replay and independent eval both have final passing
phase reports. The native factory suite was green before admission (`127/127`)
and the source-integrity and admission regressions are covered by the focused
factory tests.

## Revert condition

No revert condition fired. The safe inverse remains: if a future cycle reports
`factory source changed`, fails to deliver an admitted ticket, or cannot prove
the retained-branch merge base, disable the affected overlap/retained path and
retain the run-scoped guidance quarantine while repairing the failing native
regression.

## Next-cycle disposition

Validated by [run-1786159268557/report.json](report.json),
[CTO-PRODUCTIVITY-REPORT.md](CTO-PRODUCTIVITY-REPORT.md), and the final
lifecycle event `95-cycle-validated`. Retained-branch fast-path behavior was
not exercised by this one-ticket run; its deterministic contract remains
covered by native tests and should be measured when a retained branch is
available.
