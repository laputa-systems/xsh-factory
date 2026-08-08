# CTO factory improvement

## Status

pending-validation

`pending-validation` means the CTO has implemented this change; the next cycle
must validate the named metrics before paid work is treated as stable.

## Change

`factory/tools/audit.xsh` now derives retained throughput from the persisted
`fast_path` field on direct phase reports instead of assuming a phase-name
prefix. This captures reuse when it occupies `01-ticket`. The eval-manager
default tool set in `factory/control.xsh` is now `read,write,edit`; the role
and assignment explicitly prohibit shell discovery. Tests cover the default
and the direct `01-ticket` fast-path projection.

## Throughput requirement

Cycle 9 delivered one retained engineer commit and passed all outcome gates.
The prior zero-delivery failure was repaired; this change targets the next
cost/latency bottleneck while preserving the one-commit requirement.

## Provider-health attribution

Telemetry was present for all managers. No provider errors or retries were
reported. The long manager sessions are attributed to agent exploration and
tool volume, not external provider health.

## Baseline metric

Cycle 9 manager reports used 19 and 22 tool calls, including `bash`/`ls`, and
the root throughput projection reported zero retained rows even though
`phases/01-ticket/report.json` had `fast_path=true`.

## Target metric

In the next cycle, both eval-manager reports must contain zero `bash`, `ls`,
`find`, and `grep` tools, and the organization report must show
`retained_rows=1` and `retained_fast_paths=1`, while delivering at least one
commit.

## Validation

Run `run.xsh templates/ORGANIZATION-REQUEST-CYCLE-10.md`. Check the root
`report.json` throughput fields, both manager `report.json` tool lists, every
linked `required-outputs.json`, and the final product commit.

## Revert condition

If the restricted manager cannot complete a valid report or the next cycle
shows a regression in delivery, restore the manager tool default to the prior
set while keeping the audit projection fix. If manager shell-tool rows remain,
shorten the assignment to a fixed structured evidence checklist before the
following cycle.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted`
after linking the cycle evidence.
