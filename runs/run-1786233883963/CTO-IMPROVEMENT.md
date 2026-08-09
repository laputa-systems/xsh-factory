# CTO factory improvement

## Status

pending-validation

`pending-validation` means the CTO has already implemented this change. It is
not awaiting another approval; the next explicit cycle verifies the named
metric or applies the safe inverse.

## Change

`factory/tools/session-watch.xsh` now distinguishes ordinary agent inactivity
from the controller session state in which an assistant has completed tool
calls and Pi is awaiting the next provider completion. The watcher still
enforces the 120-second idle cap for genuine silence, but defers that pending
provider state to the existing role wall cap (300 seconds normally, 180 seconds
for the bounded retry). `tests/tools_test.xsh` supplies a synthetic JSONL
session ending in `toolResult` and proves that the watcher records the wall
limit rather than a false idle limit.

## Throughput requirement

Engineer implementation commits: `0`; fresh-engineer target: `0`. The CTO
reviewed both Open tickets before admission: `task-histogram-005` remains
blocked by its restriction boundary, and `task-histogram-006` by its missing
discriminating `filter` diagnostic replay. No eligible product row existed, so
this is an eval-only infrastructure failure, not a missed fresh-delivery cycle.

## Provider-health attribution

Telemetry was captured for all five workers: 70 assistant turns, `$0.04274082`,
no budget failure, no unknown cost, no retry event, and no provider error. The
primary manager and its recovery each produced the mandated initial reads, then
received no second assistant turn before the idle watcher stopped them. This is
a pending-provider lifecycle gap; it is not evidence of ordinary agent churn.

## Baseline metric

Run `run-1786231856321` used 94 turns and `$0.062499888`; its primary manager
read worker evidence before drafting because the role and assignment disagreed.
In this run, the primary manager made exactly the five admission reads and the
successful `task-colsum` manager immediately wrote its staged report, so the
prompt conflict is resolved. The primary manager's response gap after those
tool results left both reports `not-ready`.

## Target metric

On the next explicit organization cycle, a manager session ending in completed
tool results must not create an `idle limit exceeded` marker. Each manager must
either write/refine a contract-complete `REPORT.md` within its existing wall
cap or terminate with an explicit wall-limit outcome. The root report target is
`required_outputs.manager_report == true` for every phase.

## Validation

Run `xsht test --jobs 1`, then one later explicit qualified-image organization
request. Inspect each manager session's final message role and its
`SESSION-LIMIT` marker, the phase `required_outputs.manager_report` fields, and
the root outcome dimensions. The synthetic watcher test must remain green.

## Revert condition

Revert this branch of the watcher logic if a session ending in an ordinary
assistant or user message no longer receives the 120-second idle cutoff, or if
a pending-provider manager can exceed its existing 300/180-second wall cap.
The safe inverse restores the unconditional idle check and leaves the recorded
failed sessions intact.

## Next-cycle disposition

Pending validation. The prior prompt repair is validated for evidence order;
the next CTO verifies this controller-side pending-provider distinction before
admitting further paid work.
