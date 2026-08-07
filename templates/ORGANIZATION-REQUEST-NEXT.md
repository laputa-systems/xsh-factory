# Cycle request: next organization signal

## Objective

Run one bounded organization cycle after the delivery-boundary hardening.
Review every remaining Open ticket before admission. All current Open tickets
remain deferred pending their named focused or cross-eval evidence, so no
engineer ticket is admitted in this cycle. Use the next untried Approved eval
to restore fresh product signal and identify whether any existing ticket has
reached its approval gate.

## Bottleneck review

The current assembly-line bottleneck is eval signal -> CTO approval: six Open
tickets have durable review markers, but none has the replay evidence required
for engineer admission. The corrective action is one fresh `task-ecount` trial,
the next untried Approved eval under coded selection policy. A future cycle may
approve a ticket only after its named evidence gate is satisfied.

## Mode

- `organization`

## Eval admission

- Allow measured eval reuse: `no`
- Select the next untried Approved eval: `task-ecount`

## Active evals

- `task-ecount`

## Trial plan

- Count: `1`

## New eval proposals

- Count: `0`
- The checked-in eval portfolio is at the coded cap of 30.

## Approved tickets

- None.

## Ticket policy

- Review all open tickets before selection: `yes`
- Select the first two approved tickets after review: no eligible tickets.
- Do not approve the Open tickets until each named focused or cross-eval gate
  is satisfied and recorded in its checked-in ticket.
- Require API-surface justification and CTO approval for any new XSH API
  proposal.

## Role overrides

Use the normal role defaults from `factory/control.xsh` and
`factory/entrypoints/run-agent.xsh`.

## Required outputs

- one fresh `task-ecount` worker/evaluator/manager evidence packet;
- structured worker reports and raw Pi sessions;
- a run-level `report.json` covering every worker;
- a `## North-star impact` section in each narrative role report;
- one `CTO-IMPROVEMENT.md` handoff with a measurable next-cycle validation;
- one `CTO-PRODUCTIVITY-REPORT.md` comparing this cycle with the prior cycle;
- a `CTO-REPORT.md` briefing generated from structured evidence.
