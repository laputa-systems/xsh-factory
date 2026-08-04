# Cycle request: standard organization

## Objective

Run one bounded organization cycle. Before invoking the controller, the CTO
must review every remaining `Open.` ticket for evidence, duplication, scope,
acceptance criteria, linked-eval availability, and resolved deferral conditions.
The CTO must write `Approved.` into each eligible ticket and record the evidence
in that ticket. Admit up to two explicitly approved tickets, or automatically
select the first two approved tickets after that review. Do not run an eval-only
cycle while an eligible Open ticket remains unapproved; the controller cannot
infer approval from a narrative review. If no ticket is eligible, record the
blocking reason for every Open ticket and run the selected eval. When tickets are admitted, immediately
re-evaluate its linked eval against the exact clean engineer worktree before merge,
then run the independent `task-bigfiles` eval against XSH main. Always produce
one small practical eval proposal for immediate CTO review and promotion.

## Bottleneck review

Before invoking `run.xsh`, identify the constrained assembly-line stage:
eval signal, ticket approval, engineer delivery, or replay/merge. Cite the
latest run evidence and choose one corrective action with a measurable target.
After the cycle, compare the result against that target. If eval signal is the
constraint, select a different approved eval rather than repeatedly spending on
the same saturated eval, unless the request records evidence for reuse.

## Mode

## Eval admission

- Allow measured eval reuse: `no`
- The controller must select the lexicographically first untried Approved eval
  when one exists. Set reuse to `yes` only with a written CTO rationale.

- Allow measured eval reuse: `no`
- The controller must select the lexicographically first untried Approved eval
  when one exists. Set reuse to `yes` only with a written CTO rationale.

## Active evals

- `task-bigfiles`

## Trial plan

- Count: `1`

## New eval proposals

- Count: `1`
- Difficulty: no harder than ecount; prefer a small practical programming or
  systems-administration task.

## Ticket policy

- Review all open tickets before selection: `yes`
- Select the first two approved tickets after review: `yes`
- Admission invariant: approve eligible Open tickets before invoking `run.xsh`; do not silently fall back to eval-only work
- Quality gate: do not dispatch a ticket whose proposed API addition lacks the
  `## API-surface justification` section and CTO approval. A design rejection
  or deliberate no-dispatch decision is valid quality progress and must not be
  overridden by throughput pressure.
- Throughput gate: when a quality-approved ticket is admitted, the cycle must
  produce at least one reviewable engineer implementation commit; otherwise
  classify it as a throughput failure and record corrective action.

## Role overrides

Use the defaults codified by `factory_control.xsh` and `run-agent.xsh`. Put any
deliberate override in the invocation with a role-specific setting.

## Required outputs

- one primary eval or ticket phase;
- at least one engineer implementation whenever an evidence-backed eligible
  Open ticket exists and the ticket has passed the API-surface quality gate;
  quality-deferred tickets must not be dispatched merely to satisfy throughput;
- one linked candidate re-evaluation per admitted ticket;
- one independent `task-bigfiles` eval when a ticket is admitted, distinct from
  the linked ticket replay;
- one eval-design proposal pending review;
- aggregate cost and per-phase reports under one parent run;
- one `CTO-IMPROVEMENT.md` factory-wide improvement handoff with a next-cycle
  validation or revert condition;
- one `CTO-PRODUCTIVITY-REPORT.md` comparing throughput and efficiency with the
  prior cycle;
- no worker-selected tickets, evals, merges, or approvals.
