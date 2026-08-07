# Cycle request: shared-image cache delivery

## Objective

Run one normal-intensity organization cycle with one approved product ticket
and one independent discovery eval. Verify that concurrent phase controllers
reuse the keyed shared XSH eval image after the first builder completes, while
the engineer produces a validated product commit.

## Bottleneck review

The eval controller now skips the product distribution and base-image builds
when the exact keyed image tag is already present. Preserve the shared build
lock for the first builder and verify cache-hit state in the phase evidence.

## Mode

- `organization`

## Eval admission

- Allow measured eval reuse: `no`

## Active evals

- `task-treecmp`

## Trial plan

- Count: `1`

## New eval proposals

- Count: `0`

## Approved tickets

- `task-safepath-001`

## Ticket policy

- Review every Open ticket before admission: `yes`
- Select the approved ticket above: `yes`
- Require the linked `task-safepath` replay to pass before delivery.
- Require API-surface justification and CTO approval for any new XSH API.

## Role overrides

Use the normal role defaults; no reduced-intensity overrides.

## Required outputs

- one validated engineer implementation row with amended commit provenance;
- linked `task-safepath` replay evidence;
- one independent `task-keyjoin` discovery evidence packet;
- cache-hit/build-state evidence for the shared image;
- run/phase reports, CTO briefing, productivity report, and improvement handoff.
