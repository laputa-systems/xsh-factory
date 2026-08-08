# CTO factory improvement

## Status

pending-validation

`pending-validation` means the CTO has already implemented this change. It is
not awaiting another approval; the next cycle verifies the named metric or
applies the safe inverse.

## Change

Describe the concrete factory-wide code, prompt, controller, test, or policy
change and link the exact paths.

Cycle 24 exposed that linked replay processes were concurrent but their merge
loop waited in ticket-admission order. The factory now uses
`control.fresh_first_ticket_order` in `factory/controllers/organization.xsh`
and `runtime.adaptive_approved_tickets` in `factory/runtime.xsh` so fresh
approved work is selected and merged before retained branches. The controller
still runs every admitted replay and keeps correctness, restriction, manager,
patch, and provenance gates hard. A failed retained replay remains evidence
and keeps its branch for the next cycle. The retry path in
`factory/controllers/eval.xsh` overrides only retry manager wall time to 180
seconds. Native coverage is in `tests/factory_control_test.xsh` and
`tests/tools_test.xsh`.

## Throughput requirement

State whether the cycle produced at least one reviewable engineer
implementation commit. If not, classify the cycle as a throughput failure and
describe the corrective factory change; a passing eval-only cycle does not
satisfy this requirement when an eligible product ticket existed.

Yes. One fresh engineer commit was delivered (`26d59eb`). The overall cycle
still failed because the retained dupcheck replay did not close; this is a
quality/replay failure, not a zero-throughput cycle.

## Provider-health attribution

State whether provider telemetry was captured. Do not treat latency as an agent
regression when retry, provider-error, or response-timing evidence indicates an
external provider-health issue; if telemetry is missing, state `unknown`.

Telemetry was captured. Cycle 24 recorded provider retry/stream evidence in
the manager reports; the long closeout is attributed to manager/provider
latency and incomplete narrative recovery, not to the engineer's product
work.

## Baseline metric

State the prior-cycle measurement and evidence path.

Cycle 23 delivered zero tickets with one fresh engineer row:
`runs/run-1786202908216/report.json`.

## Target metric

State the measurable result expected in the next cycle.

At least one fresh engineer row and one delivered fresh commit; the fresh
delivery event must be emitted before any retained replay is finalized.

## Validation

State the exact next-cycle command, report field, or invariant that will be
checked.

Run the next request through `run.xsh`, then inspect
`data.throughput.fresh_engineer_rows`, `data.throughput.delivered_tickets`,
and `events.jsonl` ordering for the fresh delivery event versus retained
replay events. Focused checks pass: `xsht check`, all 31 factory control tests,
the adaptive-ticket test, the organization delivery contract, and the eval
retry contract.

## Revert condition

State the evidence that falsifies the change and the safe inverse action.

Falsify if a fresh ticket is selected behind a retained branch, if a fresh
replay fails to merge despite its own required outputs passing, or if replay
quality is bypassed. The safe inverse is to restore admission/merge order to
the prior selected-ticket order while retaining branches and reports.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted`
after running the named verification, and link the evidence before admitting
paid work.

Remain `pending-validation` until the next cycle proves the target. If the
fresh-first invariant holds with a delivered fresh commit and no gate bypass,
mark `validated`; otherwise mark `reverted` and preserve the failure evidence.
