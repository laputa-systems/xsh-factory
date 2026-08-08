## Result

ready-for-review

## Branch

factory/task-histogram-004/1786177507590

## Commit

d04e19f524cce28af9ccb2c37cc322b4da1ca7c3

## Files changed

- `src/sema/check/types.rs` — allow `?` in procedures declaring `error` regardless of return type.
- `src/runtime/eval/lowered_ops.rs` — convert propagated failures from plain-returning helpers into runtime errors at the procedure boundary.
- `tests/sema.rs` — checker regression for a value-returning `[error]` helper.
- `tests/xsh/implicit-result-return.xsh` — native acceptance and runtime failure coverage for `parse_uint`.
- `docs/SPEC.md` — canonical propagation contract.

## Tests

- `cargo test --test integration sema::checker_accepts_error_propagation_in_value_returning_proc` — passed.
- `cargo test --test integration sema:: -- --test-threads=1` — 100 passed.
- `target/debug/xsht test --exact tests/xsh/implicit-result-return.xsh::test_value_returning_error_helper` — passed.
- `cargo test --test integration runtime::coverage::xsh_native_tests` — passed.
- `target/debug/xsht lint tests/xsh/implicit-result-return.xsh` — passed with no diagnostics.
- `git diff --check` — passed.
- The runnable-corpus formatting gate still reports the pre-existing `tests/xsh/stdlib/streams.xsh: needs formatting`; the changed fixture was formatted and no longer reported.

## North-star impact

XSH helpers can now preserve a useful plain value return type while explicitly propagating expected conversion failures through the existing `error` effect and `?` syntax. This removes the need to inline validation into `main` or wrap every small helper in `Result`, making typed systems-glue composition clearer without changing runtime syntax or adding a new API.

## Remaining risks

The broader corpus formatting gate is blocked by the unrelated pre-existing formatting issue in `tests/xsh/stdlib/streams.xsh`.
