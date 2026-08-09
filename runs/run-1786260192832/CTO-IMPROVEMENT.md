# CTO factory improvement

## Status

validated

## Change

Validated the sequential five-read manager admission contract introduced by
the preceding closeout. The assignment template, retry template, role guide,
and native static contract all prohibit parallel or batched admission reads.

## Throughput requirement

No eligible product ticket existed, so the zero engineer rows are intentional.
This run restores the factory capability required to maintain future supply:
a discovery worker can now reach a durable manager decision instead of losing
its evidence at the report boundary.

## Provider-health attribution

The worker and manager both captured provider telemetry with zero retries and
no provider errors. The manager completed normally; no provider issue is
attributed.

## Baseline metric

`run-1786257836059/phases/03-supply-eval` had two one-turn manager attempts,
each issuing all five admission reads in one batch and leaving `not-ready`.
The phase failed `required_outputs.manager_report`.

## Target metric

The next real manager session makes the five reads separately, reaches a draft
after the fifth result, and produces `required_outputs.manager_report: true`.

## Validation

Validated in `runs/run-1786260192832/phases/01-eval`: the `task-iniget`
manager used 15 turns, wrote a complete report, and the phase passed every
required output. Its raw `session.jsonl.bz2` records separate admission-read
actions before the report draft.

## Revert condition

If a future manager that follows the sequential sequence leaves `not-ready`,
replace retry-time free-form drafting with a controller-generated structured
draft for manager refinement. Do not add further read-order prose.

## Next-cycle disposition

Keep this improvement validated. Continue discovery rotation until a strong
reproducible observation creates an Open ticket that CTO can review for
approval; do not use the ticket buffer as a status quota.
