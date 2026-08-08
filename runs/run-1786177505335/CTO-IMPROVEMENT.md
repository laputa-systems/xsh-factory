# CTO factory improvement

## Status

pending-validation

`pending-validation` means the CTO has already implemented this change. It is
not awaiting another approval; the next cycle verifies the named metric or
applies the safe inverse.

## Change

The eval controller now copies `lineage/handbook-approved.md` to
`lineage/handbook-candidate.md` before manager dispatch, making an unchanged
handbook decision safe by construction. Eval managers now use medium thinking,
24 maximum turns, and an 1,800-second wall ceiling. The assignment and role
prompts explicitly prioritize structured evidence and early report completion.
The exact changes are in `factory/controllers/eval.xsh`, `factory/control.xsh`,
`templates/EVAL-MANAGER-ASSIGNMENT.md`, and `roles/eval-manager.md`.

## Throughput requirement

The cycle produced one fresh and one retained reviewable engineer commit but
zero delivered commits. Because eligible product tickets existed, this is a
throughput failure. The corrective change is the manager-bound and lineage
hardening above.

## Provider-health attribution

Provider telemetry was captured. The pathparts manager had one successful
provider retry; the histogram manager had no provider error, but both sessions
hit the controller wall watcher. Attribute the failure to the factory ceiling,
not provider health.

## Baseline metric

Prior cycle: one delivered commit, $0.172625, 144 turns; see its structured
`report.json` and productivity report. Current baseline: zero delivered from
two admitted tickets, $0.187124, 178 turns; see this run's `report.json`.

## Target metric

At least one delivered engineer commit, with all linked replay required-output
flags true and no `SESSION-LIMIT` marker for an otherwise valid manager report.

## Validation

Run the next request through `run.xsh`; check `throughput.delivered_tickets`,
each linked phase's `required-outputs.json`, and the absence of manager
`SESSION-LIMIT` markers. `XSH_MODULE_PATH=. xsht test` already passes 131/131.

## Revert condition

If a manager still reaches the 1,800-second ceiling or the next cycle delivers
zero despite valid replay evidence, classify the change as insufficient and
reduce the manager assignment to structured-only evidence with a smaller turn
budget before the following cycle. Do not revert the safe candidate staging;
it removes an independent lineage defect.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted`
after running the named verification, and link the evidence before admitting
paid work.
