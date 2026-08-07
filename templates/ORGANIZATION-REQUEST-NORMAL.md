# Normal organization request

## Objective

Run one normal-intensity organization cycle. Review every remaining `Open.`
ticket before admission and approve only evidence-backed product work whose
deferral conditions are satisfied. If none qualifies, preserve the explicit
deferrals and run the next untried active eval; engineers must not infer work.

## Bottleneck review

The current bottleneck is eval signal -> reproducible ticket. All five Open
histogram tickets still require a fresh focused `task-histogram` replay before
engineer approval, so no ticket is admitted in this cycle. The next untried
approved eval is `task-colsum`, selected to restore independent evidence for
the next admission review.

## Mode

- `organization`

## Eval admission

- Allow measured eval reuse: `no`
- Select the lexicographically first untried Approved eval.

## Active evals

- `task-colsum`

## Trial plan

- Count: `1`

## New eval proposals

- Count: `0`
- The checked-in eval portfolio is at the coded cap of 30.

## Approved tickets

- None; all Open tickets have explicit checked-in deferral reasons.

## Ticket policy

- Review all open tickets before selection: `yes`
- Select the first two approved tickets after review: `yes`
- Approve eligible Open tickets before controller invocation: `required`
- Require API-surface justification and CTO approval for new XSH API proposals.

## Role overrides

Use the normal defaults codified by `factory/control.xsh` and
`factory/entrypoints/run-agent.xsh`; no reduced-intensity overrides.

## Required outputs

- up to two approved ticket implementations and linked replays when tickets
  are available;
- one independent active eval when tickets are admitted, otherwise one primary
  active eval;
- structured reports, raw sessions, run/phase reports, CTO briefing,
  `CTO-IMPROVEMENT.md`, and `CTO-PRODUCTIVITY-REPORT.md`.
