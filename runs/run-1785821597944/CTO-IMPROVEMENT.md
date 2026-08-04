# CTO factory improvement

## Status

validated

## Change

Changed engineer defaults in `factory_control.xsh` to
`openai/gpt-5.6-luna` with a 0.35 USD budget and 220-turn ceiling. The role
default assertions are in `tests/factory_control_test.xsh`, and the operator
summary is documented in `README.md`.

## Baseline metric

The prior DeepSeek engineer in
`runs/run-1785818570933/phases/01-ticket/workers/engineer/task-envcfg-001/report.json`
reached 160 turns and 0.238560 USD without a commit or patch.

## Target metric

An engineer assigned the same bounded language task should produce a clean,
reviewable commit before the new ceiling, without a `SESSION-LIMIT` marker.

## Validation

`runs/run-1785821597944/phases/01-ticket/workers/engineer/task-envcfg-001/REPORT.md`
records `openai/gpt-5.6-luna` session evidence through the raw session, commit
`91e0eaa`, a clean branch, and 81 turns at 0.104068 USD. The native factory
suite also passes: 43 tests.

## Revert condition

If two comparable Luna engineer assignments fail to produce reviewable output
within 220 turns or 0.35 USD, revert the engineer model and ceilings to the
previous defaults and record the evidence.

## Next-cycle disposition

Validated before the next paid cycle. The model change improved implementation
throughput, but product acceptance still requires the API-discovery repair and
replay tracked by `task-envcfg-002`.
