# Cycle request template

Store cycle request templates under `templates/`. The controller copies the
selected immutable request into `runs/run-<id>/CYCLE-REQUEST.md`; do not keep
`cycle-*.md` request documents at repository top level.

# Cycle request

## Objective

Run the smallest complete organization cycle that proves the requested
factory path and produces evidence toward `NORTH-STAR.md`. Keep the cycle
cheap and preserve all worker evidence; do not create activity or tickets
without a corresponding product hypothesis. Before invoking `run.xsh`, the CTO
must review every `Open.` ticket, change each eligible ticket to `Approved.`,
and record the evidence and any deferral reason in the ticket. Never leave an
eligible ticket Open and silently substitute an eval-only cycle. When a ticket is admitted, run
its linked re-evaluation and independent active eval, while the independent
eval-design phase runs alongside the primary phase.

## Mode

- `organization`

## Eval admission

- Allow measured eval reuse: `no`
- The controller must select the lexicographically first untried Approved eval
  when one exists. Set reuse to `yes` only with a written CTO rationale.

## Active evals

- `task-bigfiles`

## Trial plan

- Count: `1`

## New eval proposals

- Count: `1`
- Difficulty: at least `ecount` difficulty: require at least two independent
- XSH data transformations or stateful aggregation, a meaningful failure
- control, and hidden cases that distinguish composition from a one-liner.
- Do not propose scalar/line projection tasks such as copying one field.

## Open-ticket work

- Dispatch tickets present at cycle start: `yes`
- Dispatch newly created tickets in this cycle: `no`

## Bottleneck review

- Required: identify the current assembly-line bottleneck before dispatch.
- Required: compare eval signal, ticket approval, engineer delivery, and
  replay/merge against the latest `CTO-PRODUCTIVITY-REPORT.md`.
- Required: choose one corrective action and a measurable next-cycle target.

## Ticket policy

- Review all open tickets before selection: `yes`
- Select the first two approved tickets after review: `yes`
- Approve eligible Open tickets before controller invocation: `required`
- Require at least one engineer implementation commit when a quality-approved
  ticket is admitted: `yes`
- Require API-surface justification and semantic-novelty review for new XSH
  API proposals: `yes`

## Role overrides

Use the defaults codified by `run.xsh` and `factory/entrypoints/run-agent.xsh`. Put any deliberate
environment override in the invocation, using names such as
`FACTORY_EVAL_MANAGER_MODEL` or `FACTORY_ENGINEER_THINKING`.

## Required outputs

- up to two approved ticket implementations and one linked pre-merge replay per
  ticket when tickets are available;
- one independent active eval when a ticket is available, otherwise one active
  eval as the primary phase;
- one substantive eval-design proposal meeting the difficulty gate pending review;
- structured worker reports and raw Pi sessions;
- a run-level `report.json` covering every worker;
- a `## North-star impact` section in each narrative role report;
- one `CTO-IMPROVEMENT.md` factory-wide improvement handoff with a measurable
  next-cycle validation or revert condition;
- one `CTO-PRODUCTIVITY-REPORT.md` with a critical throughput/efficiency
  comparison against the prior cycle;
- a `CTO-REPORT.md` briefing generated from the structured reports.
