# Focused histogram replay request

## Objective

Run the focused replay required by the five Open `task-histogram` tickets.
The replay must exercise the current XSH `HEAD`, preserve the approved
handbook lineage, and provide evidence for the named fold-with-print and
related checker observations before any engineer ticket is Approved.

## Bottleneck review

The current bottleneck is evidence-to-ticket approval. No ticket is admitted
in this replay; the CTO will review the manager's result and update at most two
ticket records only after their acceptance gates pass.

## Mode

- `organization`

## Eval admission

- Allow measured eval reuse: `yes`
- Reuse rationale: the five ticket records explicitly require a focused
  `task-histogram` replay before engineer admission.

## Active evals

- `task-histogram`

## Trial plan

- Count: `1`

## New eval proposals

- Count: `0`
- The checked-in eval portfolio is at the coded cap of 30.

## Approved tickets

- None; the replay supplies the evidence needed for the next CTO review.

## Ticket policy

- Review all open tickets before selection: `yes`
- Select the first two approved tickets after review: `no`
- Approve eligible Open tickets before engineer dispatch: `required`

## Role overrides

Use the normal role defaults; no reduced-intensity overrides.

## Required outputs

- one complete `task-histogram` worker/evaluator evidence packet;
- manager classification of each ticket-relevant observation;
- run/phase reports, CTO briefing, productivity report, and improvement
  handoff.
