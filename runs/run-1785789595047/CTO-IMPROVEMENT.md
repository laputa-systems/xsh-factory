# CTO factory improvement

## Status

pending-validation

`pending-validation` means the CTO has already implemented this change. It is
not awaiting another approval; the next cycle verifies the named metric or
applies the safe inverse.

## Change

Added controller-owned CTO ticket inventory and engineer dispatch. `run-cto.xsh`
and `factory_runtime.xsh` enumerate every ticket and persist JSON/Markdown
inventory before organization admission; `run-organization.xsh` invokes that
inventory automatically. `run-ticket.xsh` now launches both admitted engineers
directly and the director reconciles their reports instead of discovering or
dispatching workers. The contract is covered by `tests/factory_control_test.xsh`
and `tests/tools_test.xsh`, with operator documentation in `README.md` and
`CTO.md`.

## Baseline metric

The prior completed cycle admitted no engineers because CTO ticket review was
not surfaced to the controller (`runs/run-1785787490432/CTO-REPORT.md`). The
first attempted verification then showed the director spending turns before
starting work (`runs/run-1785789119635`).

## Target metric

Every organization run must write `CTO-TICKET-INVENTORY.json` and
`CTO-TICKET-INVENTORY.md` before admission. When two tickets are approved,
the lifecycle ledger must contain two controller-caused
`20-ticket-*-started` events and two engineer reports, with no director
worker-dispatch event.

## Validation

This cycle already demonstrated the target in
`runs/run-1785789595047/CTO-TICKET-INVENTORY.md` and
`runs/run-1785789595047/events.jsonl`: 10 Open tickets were surfaced, 2
approved tickets were admitted, and both engineer workers started and passed.
The next organization cycle must repeat those inventory and dispatch
invariants; native validation is `XSH_MODULE_PATH=. xsht test`.

## Revert condition

If a run lacks either inventory file, the inventory counts disagree with the
ticket files, or an approved ticket lacks a controller-caused engineer-start
event, mark this improvement reverted and restore director-owned dispatch only
after recording the failure. Do not merge product branches based on that run.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted`
after running the named verification, and link the evidence before admitting
paid work.
