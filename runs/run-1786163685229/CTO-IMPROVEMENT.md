# CTO factory improvement

## Status

validated

The adaptive queue-pressure change was revalidated in this cycle. It admitted
one approved ticket and one independent eval with no manual allocation choice.

## Change

`run.xsh` and `factory/controllers/organization.xsh` selected
`task-safepath-003` from the approved queue, while `factory/runtime.xsh` and
`factory/control.xsh` allocated one engineer and one eval. The approved-eval
fallback remains covered by `tests/tools_test.xsh`; the contract is documented
in `FACTORY.md`, `THROUGHPUT.md`, and the organization request template.
The manager also proposed a second `task-bigfiles` observation under the
already-merged `task-bigfiles-001` name; closeout preserved that terminal ticket
and staged the new observation as `task-bigfiles-002`.

## Throughput requirement

Met. The cycle produced and delivered one validated engineer commit,
`7e9814fe774ceeb9e587ae95c967944548706701`, from one admitted ticket. Its
linked replay and independent eval passed.

## Provider-health attribution

Provider telemetry was captured for all six workers. No provider-health failure
was indicated; the 24 tool errors remain agent/tool-use evidence.

## Baseline metric

The prior cycle, [run-1786162002471](../run-1786162002471/report.json), also
delivered one ticket but cost `$0.257258873` across 242 turns.

## Target metric

The next cycle must deliver at least one engineer commit whenever an approved
product ticket is ready. It must also validate the new read-only run-status
introspection tool before paid dispatch.

## Validation

Evidence is [report.json](report.json): `result: pass`, all outcome dimensions
pass, `throughput.admitted_tickets: 1`, `throughput.fresh_engineer_rows: 1`,
and `throughput.delivered_tickets: 1`. The adaptive queue event and product
`HEAD` `7e9814f` corroborate the allocation and delivery.

## Revert condition

The change is falsified if approved work is present but no engineer is
dispatched, if delivery conversion is below `1.0`, or if queue selection is
nondeterministic. The safe inverse is explicit admission with the same hard
concurrency bounds while repairing the native regression.

## Next-cycle disposition

Validated by [report.json](report.json), [CTO-REPORT.md](CTO-REPORT.md), and
the final lifecycle validation event. The cycle also surfaced
`task-safepath-004`, a strong next product candidate for the residual Str
accumulator lowering defect.
