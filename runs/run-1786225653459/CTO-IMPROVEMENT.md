# CTO factory improvement

## Status

validated

## Change

This run exposed a unit mismatch in the newly added manager inactivity
watchdog. `fs.metadata(path).modified` is epoch seconds in XSH, while
`time.now()` is epoch milliseconds. `factory/tools/session-watch.xsh` now
converts metadata seconds with `modified_epoch_ms` before comparing idle time.
The native regression `tests/tools_test.xsh::test_session_watch_idle_uses_epoch_milliseconds`
starts a harmless sleeper, runs the watcher with a one-second idle bound, and
asserts it does not fire before 500ms before terminating the sleeper.

## Throughput requirement

This was not a fresh-eligible cycle: the selected product row was a retained
engineer branch. It delivered zero commits. The replay's correctness and
protocol gates passed, but the package restriction gate failed because the
candidate artifact used `Path.lines()` without the evaluator-required typed
file-read surface. That is a legitimate product-quality rejection, not a
throughput count to paper over. The manager also failed infrastructure closeout
because the unit mismatch killed both manager attempts before they could fill
their reports.

## Provider-health attribution

Provider telemetry was present for three workers: one evaluator worker and two
manager attempts. The evaluator used 36 turns and cost `$0.018760`; manager
attempts used one turn each and cost `$0.001269` combined. No provider retry
events were reported. The manager failure is attributed to the local watchdog
unit bug, not provider health. The evaluator's three tool errors are retained
as worker friction and did not cause the restriction failure.

## Baseline metric

Before this repair, both manager attempts recorded
`eval-manager session idle limit exceeded: 178443996...ms >= 60s`, because a
seconds-valued mtime was subtracted from a millisecond epoch clock. Evidence:
the two `workers/eval-manager/*/SESSION-LIMIT` files and the phase
`report.json`, whose manager result remained `not-ready`.

## Target metric

The next retained replay must keep a healthy manager alive through its evidence
reads, complete a non-skeleton report within the 300-second normal bound or
the 180-second recovery bound, and preserve an exact acceptance decision. A
restriction failure must remain a product rejection; it must not be converted
to delivery by manager prose.

## Validation

Run `xsht test --jobs 1`, including
`test_session_watch_idle_uses_epoch_milliseconds`, then inspect the next phase
for absence of a premature `SESSION-LIMIT` idle marker and for a completed
manager report. Check the evaluator's correctness, restriction, protocol, and
manager gates independently before any retained merge.

## Revert condition

Revert the conversion only if a native or run-scoped case proves that XSH file
metadata is already epoch milliseconds on the supported runtime, or if the
watcher starts firing roughly 1000x too late. The safe inverse is to restore
the prior comparison only after measuring both clocks in the same fixture.

## Next-cycle disposition

Validated by the next retained replay's manager markers: the prior enormous
epoch-unit error is gone. The manager now recorded a normal
`60010ms >= 60s` idle timeout and a bounded `180026ms` recovery timeout. The
remaining issue was the 60-second threshold itself, which is addressed by the
next pending improvement.
