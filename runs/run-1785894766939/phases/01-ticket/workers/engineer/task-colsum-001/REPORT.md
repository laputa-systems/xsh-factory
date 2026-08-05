## Result

ready-for-review

## Branch

factory/task-colsum-001/1785894767724

## Commit

5f46267067991d5af1d988732e5c2f6f5de5ad04

## Files changed

- `src/sema/check/call.rs`
- `src/runtime/eval.rs`
- `src/runtime/eval/indexed/full.rs`
- `src/runtime/eval/lower.rs`
- `src/runtime/eval/lowered_run/indexed_run.rs`
- `tests/xsh/stdlib/test.xsh`
- `docs/SPEC.md`

## Tests

- `cargo test --test integration sema:: --no-default-features` — 96 passed.
- `cargo test --test integration runtime::coverage::xsh_native_tests --no-default-features` — passed.
- Manual `error.fail("missing header")` propagation — exit status 3, empty stdout.
- `git diff --check` — passed.

## North-star impact

Adds a documented, explicit `error.fail(message)` result for deliberate validation rejection, replacing conversion-error workarounds while preserving Result and `?` propagation semantics. This makes validation control flow clearer and more learnable for systems-glue scripts and agents.

## Remaining risks

The linked nine-case evaluator replay and an independent fail-on-condition eval still need controller/CTO replay. The new form uses the existing generic `Error` runtime family with the stable `validation` kind and is intentionally limited to a string message.
