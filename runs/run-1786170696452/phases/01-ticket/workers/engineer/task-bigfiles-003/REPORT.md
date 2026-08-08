## Result

ready-for-review

## Branch

factory/task-bigfiles-003/1786170697772

## Commit

e4059a21ae8942fa07a0e8e61bac971ed703237c

## Files changed

- `src/runtime/value.rs` — reject reads of stat-derived fields on `stat=false` entries with `metadata-unavailable`.
- `tests/xsh/stdlib/fs.xsh` — regression coverage for positional all-zero metadata case and direct children.
- `docs/SPEC.md`, `docs/STREAMS.md` — document the explicit metadata boundary.

## Tests

- `target/debug/xsht test tests/xsh/stdlib/fs.xsh` — 10 passed.
- `target/debug/xsht test --exact tests/xsh/stdlib/fs.xsh::test_fs_tree_metadata_install_and_locking` — passed.
- `target/debug/xsht test --exact tests/xsh/stdlib/fs.xsh::test_fs_files_recurses_with_raw_walk_and_preserves_entry_ext` — passed.
- `target/debug/xsht check tests/xsh/stdlib/fs.xsh` — passed.
- `target/debug/xsht lint tests/xsh/stdlib/fs.xsh` — passed.
- `cargo test -p xsh --lib runtime::value --no-default-features` — 8 passed.
- `cargo test --test integration runtime::modules` — 34 passed, 2 ignored.
- `cargo test --test integration runtime::coverage::xsht_test_lists_and_filters_native_tests` — passed.
- `git diff --check` — passed.
- The full corpus formatting gate was attempted; it reports pre-existing formatting drift in `tests/xsh/stdlib/streams.xsh`, unrelated to this change. The changed `fs.xsh` was formatted and passes its focused check.

## North-star impact

Unstatted filesystem entries no longer turn unknown sizes, modes, or permission flags into plausible zero/false values. Agents and users now receive an explicit runtime boundary and can correct a mistaken `stat=false` call, preserving trustworthy metadata reports without changing the meaning of real zero-byte files. The run-scoped handbook candidate was updated with this reusable filesystem metadata lesson.

## Remaining risks

The diagnostic is a runtime error rather than a warning, so programs intentionally using `stat=false` must avoid stat-derived fields or request `stat=true`. Existing callers that depended on zero placeholders will need to handle the explicit error.
