## Result

ready-for-review

## Branch

factory/task-envcfg-001/1785821598567

## Commit

91e0eaa46014ea1dba60a5faebdead98db38cc9f

## Files changed

- `src/sema/check/call.rs`
- `src/runtime/eval.rs`
- `src/runtime/eval/indexed/full.rs`
- `src/runtime/eval/lower.rs`
- `src/runtime/eval/lowered_run/indexed_run.rs`
- `tests/xsh/run.xsh`
- `docs/SPEC.md`

## Tests

- `cargo check -q` — passed.
- `cargo build -q --bin xsh --bin xsht` — passed.
- `cargo test -q --test integration sema:: --no-default-features` — 96 passed.
- `cargo test -q --test integration syntax:: --no-default-features` — 98 passed.
- `cargo test -q --test integration runtime::coverage::xsh_native_tests --features native-tests -- --exact` — passed; 327 passed, 6 skipped.
- `target/debug/xsht check tests/xsh/run.xsh` and `target/debug/xsht lint tests/xsh/run.xsh` — passed.
- `git diff --check` — passed.

## North-star impact

Adds the smallest reusable `fail(message)` expression for deliberate validation rejection. It returns the standard `Result[Unit, Error]` validation failure, propagates through `?`, exits nonzero at the script boundary, and avoids sentinel conversions or unrelated host failures. The canonical specification and focused native regression test make the boundary explicit for people and agents.

## Remaining risks

The deliberate failure uses the generic `Error` family with kind `validation`; callers that need a nominal domain-specific error family still need a declared error constructor. The broader corpus gate remains affected by pre-existing formatting and documentation-snippet lint failures unrelated to this change.
