## Result

ready-for-review

## Branch

factory/task-safepath-001/1786144489462

## Commit

630d14261ce5cf0160bf9809e79e2fca12922c70

## Files changed

- `crates/xsh-registry/src/reference.rs` — registered `language.core.abort` documentation.
- `crates/xsh-registry/src/examples.rs` — attached the canonical abort example.
- `docs/snippets/api/core-abort.xsh` — added a quiet validation-exit example.
- `docs/SPEC.md` — documented abort as deliberate, non-tracebacking termination.
- `tests/xsh/run.xsh` — added regression coverage for status, stdout, empty stderr, and unreachable code.

## Tests

- `cargo build -p xsh -p xsht --bin xsh --bin xsht` — passed.
- `cargo test -p xsh-registry --lib` — passed (8 tests).
- `cargo test --test integration runtime::process:: --no-default-features` — passed (24 tests).
- `cargo test -p xsh --test integration runtime::coverage::xsh_native_tests --features native-tests -- --exact` — passed.
- `cargo test -p xsh --test integration runtime::coverage::runnable_xsh_corpus_is_formatted_and_lints_without_warnings` — passed.
- `target/debug/xsht check tests/xsh/run.xsh` and `target/debug/xsht check docs/snippets/api/core-abort.xsh` — passed.
- `target/debug/xsht lint tests/xsh/run.xsh docs/snippets/api/core-abort.xsh` — passed.
- Direct runtime smoke test `abort(7)` — exited 7 with empty stdout and stderr.
- `git diff --check` and clean-worktree validation — passed.

## North-star impact

Makes the existing explicit `abort(status)` capability discoverable and trustworthy for systems-glue validation boundaries. Agents and users can now find the canonical API entry and example, distinguish deliberate quiet termination from `Result` propagation, and rely on regression coverage that preserves the requested status while keeping stderr free of a traceback.

## Remaining risks

The runtime abort implementation already existed on the assigned baseline; this change documents and locks down its quiet-exit contract rather than changing runtime internals. A future replay should verify the exact safe-path oracle behavior across its full escape-case matrix.
