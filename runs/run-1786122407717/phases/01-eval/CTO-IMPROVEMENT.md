# CTO factory improvement

## Status

pending-validation

`pending-validation` means the CTO has already implemented this change. It is
not awaiting another approval; the next cycle verifies the named metric or
applies the safe inverse.

## Change

Make `factory/runtime.xsh::compress_run_sessions` idempotent when rewriting
session references. Existing archive suffixes are protected before raw-session
references are rewritten; the regression is covered by
`tests/tools_test.xsh::test_compressed_session_rewrite_is_idempotent`.

## Throughput requirement

Zero engineer commits and zero eval-worker sessions; throughput failure was
caused by the session archive contract. No eligible ticket was skipped.

## Provider-health attribution

Manager telemetry recorded zero retries. Worker provider health is unknown
because the worker session was never persisted.

## Baseline metric

The worker trial failed with `session.jsonl.bz2.bz2` and produced no worker
report or evaluator manifest.

## Target metric

The next replay persists all three worker evidence artifacts and emits zero
double-compressed session paths.

## Validation

`xsht test tests/tools_test.xsh` passes 52/52; the next replay checks the
worker evidence paths in its phase report.

## Revert condition

Any next-replay `.bz2.bz2` path or missing worker session after this native test
fails the repair and requires a focused session-path fix.

## Next-cycle disposition

The next CTO must replace `pending-validation` with `validated` or `reverted`
after running the named verification, and link the evidence before admitting
paid work.
