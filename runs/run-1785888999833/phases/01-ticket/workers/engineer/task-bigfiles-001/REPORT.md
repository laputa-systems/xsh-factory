## Result

ready-for-review

## Branch

factory/task-bigfiles-001/1785889000406

## Commit

e5d29c7ec8b4411dc749fd3e44bf472d641ad9f4

## Files changed

- `crates/xsh-registry/src/reference.rs` — display `sort-by` options before its block argument.
- `crates/xsht/tests/api.rs` — regression coverage for the corrected API signature.

## Tests

- `cargo test -p xsht --test api api_stream_sort_by_shows_options_before_block` — passed.
- `cargo test -p xsh-registry --lib` — passed (8 tests).
- `cargo test -p xsh --lib modules::signature` — passed.
- `cargo test -p xsht --test api` — passed (29 tests).
- `cargo build --bin xsh && cargo build --bin xsht` — passed.
- `git diff --check` — passed.
- Worktree clean after commit.

## North-star impact

The `xsht api language:stream.sort-by` reference now presents the accepted named-option-before-block order, so users and agents can learn the syntax without being directed toward the rejected form. The change preserves the existing grammar and runtime behavior while making the explicit boundary between options and block arguments truthful and test-protected.

## Remaining risks

The checker still reports the existing generic unresolved-name diagnostic when a named option is placed after a block; this implementation takes the accepted API-signature option from the ticket. A later diagnostic-focused change could add a corrective hint without changing grammar.
