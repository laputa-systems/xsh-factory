# CTO factory improvement

## Status

pending-validation

## Change

The organization admission path was exercised with an explicitly approved,
non-API-surface ticket (`task-bigfiles-001`) and the request now declares its
organization mode and rotates its independent eval policy through the existing
request contract. The ticket was not silently left Open: its approval records
the evidence and linked replay gate in `tickets/task-bigfiles-001.md`.

## Throughput requirement

This cycle itself produced zero engineer commits because the checked-in
organization request was accidentally missing its required `organization`
mode marker and therefore dispatched the prior eval-only path. That request
defect was corrected before closeout. This is a throughput failure, not
successful product progress; the next cycle must use the corrected request and
produce a fresh engineer commit.

## Provider-health attribution

Provider telemetry was present for all three workers in
`report.json`; retries were zero and provider errors were unknown. The
observed tool errors are attributed to agent workflow and task friction, not
provider switching or retry health.

## Baseline metric

`runs/run-1785888600805/report.json`: 0 engineer commits, 81 assistant turns,
12 tool errors, and $0.047184 cost. The prior run
`runs/run-1785887678360/report.json` likewise had 0 engineer commits, 93 turns,
and $0.074526, but its organization request also failed to be an organization
request in practice.

## Target metric

The next organization cycle must dispatch at least one fresh engineer against
`task-bigfiles-001`, produce a reviewable commit, and pass its linked replay
with `required_outputs.required: true`, while keeping total cost at or below
$1.00.

## Validation

Run `XSH_MODULE_PATH=. xsh run.xsh cycle-organization.md`, then inspect the
root `report.json`: require `mode: organization`, a non-empty engineer list,
at least one engineer worker result of `pass`, and a passing linked replay.
Also run `XSH_MODULE_PATH=. xsht test` before admission.

## Revert condition

If the corrected request still produces no engineer phase or the controller
reports an eval-only mode despite `mode: organization`, stop and fix the
request/controller parsing boundary before spending another paid cycle. If an
engineer commit is produced but the linked replay fails for an unrelated
product reason, retain this request correction and diagnose the product change
instead of reverting it.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted`
after the named verification and link the evidence before admitting paid work.
