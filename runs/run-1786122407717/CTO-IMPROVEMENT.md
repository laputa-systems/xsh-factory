# CTO factory improvement

## Status

validated

`pending-validation` means the CTO has already implemented this change. It is
not awaiting another approval; the next cycle verifies the named metric or
applies the safe inverse.

## Change

Make `factory/runtime.xsh::compress_run_sessions` idempotent when rewriting
session references. Existing `session.jsonl.bz2` and
`session.jsonl.events.jsonl.bz2` references are protected before raw-session
references are rewritten; the regression is covered by
`tests/tools_test.xsh::test_compressed_session_rewrite_is_idempotent`.

## Throughput requirement

- Reviewable engineer implementation commits: `0`
- Admitted tickets: `0`
- Classification: throughput failure caused by missing eval-worker evidence,
  not by an eligible ticket being skipped. All five Open tickets were
  explicitly deferred pending fresh replay evidence.

## Provider-health attribution

The eval-manager recorded provider telemetry with zero retries; the eval-worker
never produced a session, so worker effort and provider health for the product
trial are unknown. The failure is the session-archive rewrite contract, not a
provider switch or agent-efficiency finding.

## Baseline metric

Run `run-1786122407717` spent `$0.007256304` on 11 manager turns over about
7 minutes, but produced zero eval-worker sessions and a manager report pointing
at `session.jsonl.bz2.bz2`; see
`phases/01-eval/events.jsonl` and the phase `report.json`.

## Target metric

The next eval trial must produce a worker session, worker report, and evaluator
manifest with no `.bz2.bz2` references; target zero missing-session failures
from session archival before manager admission.

## Validation

`xsht test tests/tools_test.xsh` passes 52/52, including the new idempotence
test. The next paid replay must additionally show a persisted
`workers/eval-worker/task-bigfiles-1/session.jsonl.bz2`, `report.json`, and
`run.json` in its phase report.

## Revert condition

If the next replay still emits `.bz2.bz2` or fails to persist the worker session
despite the archive rewrite passing its native test, revert this rewrite and
repair the session path contract with a focused fixture before another paid
cycle.

## Next-cycle disposition

Validated by `xsht test` (112/112), including the focused archive-rewrite
regression. The next paid replay remains the end-to-end falsification target.
