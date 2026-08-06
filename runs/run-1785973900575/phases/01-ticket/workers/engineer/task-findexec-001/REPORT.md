## Result

ready-for-review

## Branch

factory/task-findexec-001/1785973903595

## Commit

500a9a6a6dcc82b8ba70be4c2bd3e4afcf5ede50

## Files changed

- `src/sema/check/stream.rs` — check conditional `if`/`else` tails as value-producing stream block tails.
- `tests/xsh/stdlib/streams.xsh` — native regression coverage for `map`, `where`, and `each` conditional tails.
- `docs/SPEC.md` — document direct conditional tails in value stages.

## Tests

- `cargo test --test integration sema:: --no-fail-fast` — passed (97 tests).
- `cargo test --test integration runtime::coverage::xsh_native_tests --features native-tests -- --exact` — passed.
- `cargo test --test integration runtime::streams:: --no-fail-fast` — passed (7 tests).
- `git diff --check` — passed.
- Worktree status — clean after commit.

## North-star impact

XSH now uses one consistent value-expression model in stream blocks: conditional values can be written directly as `map`/`where` tails instead of requiring a bind-then-tail workaround. This improves learnability and reduces agent exploration while preserving explicit pipeline composition and existing `let` RHS behavior.

## Remaining risks

None.
