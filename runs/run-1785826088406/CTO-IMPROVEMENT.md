# CTO factory improvement

## Status

validated

## Change

The engineer provenance path implemented before this cycle was exercised by a
real organization run. `run-ticket.xsh` amended the Luna engineer commit only
after validation, verified the trailers from Git, updated the report hash, and
emitted the provenance event with assignment, report, session, and patch
hashes. The durable implementation is in `factory_runtime.xsh`,
`run-ticket.xsh`, and `tests/tools_test.xsh`.

## Baseline metric

Before this change, engineer commits had no factory identity or session
statistics attached. The prior reference implementation `91e0eaa` had to be
correlated manually with run evidence.

## Target metric

Every accepted engineer row produces a commit whose trailers, controller event,
worker report, and portable patch identify the same amended commit and evidence
chain; no accepted row may pass provenance validation without those links.

## Validation

Run `runs/run-1785826088406` provides the first production-cycle evidence:
commit `2d423c166b9c06aee44b9f4e720554ebeee1216b` contains the Luna model,
28 turns, 62 tool calls, 2 tool errors, `$0.030574945`, report/session/assignment
hashes, and patch hash. The matching event is
`phases/01-ticket/events.jsonl:75-ticket-task-envcfg-002-provenance`, and its
patch hash matches `patches/task-envcfg-002.diff`. `XSH_MODULE_PATH=. xsht test`
passes 44 tests, including synthetic missing-evidence, dirty-worktree,
verification, idempotency, patch, and cleanup cases.

## Revert condition

If a future accepted engineer row has a trailer, event, report, or patch hash
that does not match its corresponding evidence, or if a valid clean commit is
rejected solely by the provenance gate, stop ticket admission and revert the
provenance gate to the last tested implementation while preserving the failed
run evidence.

## Next-cycle disposition

Validated before closing this cycle. The next cycle should verify the same
chain on another engineer task and inspect `git show --format='%(trailers)'`
against the structured event and patch hash.
