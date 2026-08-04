# CTO factory improvement

## Status

pending-validation

`pending-validation` means the CTO has already implemented this change. It is
not awaiting another approval; the next cycle verifies the named metric or
applies the safe inverse.

## Change

The prior cycle's controller improvement is now exercised by this run:
`run-cto.xsh` generated the complete run-scoped ticket inventory before
admission, and the controller correctly refused duplicate engineer dispatch
while `task-envcfg-003` still had an unmerged implementation branch. The
controller-owned inventory and dispatch contract remain in `factory_runtime.xsh`,
`run-organization.xsh`, `run-ticket.xsh`, and their native tests.

This run also exposed and fixed an over-narrow manager evidence contract in
`factory_control.xsh`: substantive tool-error accounting such as “Four nonzero
Pi tool results” is now accepted and covered by `tests/factory_control_test.xsh`.

It also exposed and fixed unsafe branch-provenance reconciliation in
`factory_runtime.xsh`: a historical branch pointing at an ancestor commit can
no longer mark a ticket merged; reconciliation now requires a passing engineer
report with the exact implementation commit.

## Baseline metric

The previous verification run dispatched two approved engineers concurrently
(`runs/run-1785789595047/phases/01-ticket/events.jsonl`). This run's inventory
shows the expected post-merge state—one ticket `Merged.`, one `Approved.` with
an existing branch—and the admission guard stopped duplicate work in the
first attempt. Evidence: `runs/run-1785795835208/CTO-TICKET-INVENTORY.md` and
the controller error recorded during admission.

## Target metric

The next organization cycle, after CTO review of the remaining parser branch,
must either merge/reconcile `task-envcfg-003` or record a concrete rejection;
it must not dispatch a duplicate engineer. With two newly approved tickets,
the inventory and controller-caused concurrent-start invariant must still
hold.

## Validation

Run `XSH_MODULE_PATH=. xsh run.xsh cycle-organization.md`. Check the generated
`CTO-TICKET-INVENTORY.md`, `report.json`, and `events.jsonl`; verify that an
existing implementation branch is reused or merged rather than dispatched a
second time, and that any new admissions have one controller-caused start per
approved ticket.

## Revert condition

If the next cycle dispatches a duplicate branch, omits the inventory, or loses
the controller-caused start events, mark this improvement reverted and repair
the admission/reconciliation path before paid work. Do not merge a product
branch without its targeted tests and linked replay.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted`
after running the named verification, and link the evidence before admitting
paid work.
