## Result

ready-for-review

## Branch

factory/task-jsonfilter-001/1786138323873

## Commit

a248267612439dfcfa203fba583ac3e95d37f70c

## Files changed

- `crates/xsht/src/lint.rs`: suppress redundant-tail-return-binding for named record-schema annotations.
- `crates/xsht/tests/lint.rs`: regression coverage for function and map/block typed record bindings.
- `docs/SPEC.md`: documents why record-schema binding annotations are retained.

## Tests

- `cargo test -p xsht --test integration lint::linter_does_not_suggest_unparseable_tail_return_for_typed_records` — passed.
- `cargo test -p xsht --test integration lint:: -- --test-threads=1` — 53 passed.
- `cargo test -p xsht --test integration` — 98 passed.
- `git diff --check` — passed.
- Worktree clean after commit.

## North-star impact

The linter no longer recommends replacing a typed record binding with the invalid postfix `: Type` tail syntax. This keeps lint advice parseable and preserves the explicit typed boundary needed for heterogeneous or JSON-derived records, reducing agent edit/check loops while maintaining composability.

## Remaining risks

The fix intentionally targets named record-schema annotations. It does not add postfix type-cast syntax or alter parser behavior; other annotation forms remain governed by the existing checked-type safety rules.
