## Result

ready-for-review

## Branch

factory/task-histogram-002/1785900055647

## Commit

aaa968c73fd7649f70a6a94e21f77a90bf6a778c

## Files changed

- `docs/SPEC.md` — documents concrete group-by key projection for sort-by.
- `tests/sema.rs` — checker coverage for Int, Str, Bool, and Path group keys.
- `tests/xsh/stdlib/streams.xsh` — native stream coverage for grouped Int key ordering.

## Tests

- `cargo test --test integration sema::checker_accepts_group_by_key_sort_by_for_scalar_keys` — passed.
- `cargo test --test integration runtime::streams::` — passed (7 tests).
- `cargo test --test integration sema::` — passed (97 tests).
- `target/debug/xsht check tests/xsh/stdlib/streams.xsh` — passed.
- `git diff HEAD^ --check` — passed.
- Worktree clean after commit.

## North-star impact

The existing `sort-by` surface now accepts and executes the canonical
`group-by` then `sort-by { |g| g.key }` composition for supported scalar keys,
so agents and users can use the documented aggregation path instead of a
Map/string-key workaround. The checker coverage makes the contract explicit
across the supported scalar family and preserves typed, composable stream
boundaries without adding syntax or APIs.

## Remaining risks

The linked histogram replay and independent `task-bigfiles` manifest are
controller/manager acceptance checks and were not available as local product
tests; they should be run against this commit before merge. The implementation
relies on the existing group-by projection typing, which is currently concrete
for the covered scalar expressions.
