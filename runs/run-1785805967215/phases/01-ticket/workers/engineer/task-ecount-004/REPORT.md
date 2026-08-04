# Engineer report

## Result

ready-for-review

## Branch

factory/task-ecount-004/1785805967997

## Commit

c4f5fa1c56d6e302f6d392c4d19aed0f24faacf7

## Files changed

- `src/sema/check/stream.rs` — accept `Type::Any` (and records whose fields are `Any`) in `is_sortable_key_type`/`is_sortable_record_key_type`, matching the runtime comparator.
- `tests/sema.rs` — new checker test `checker_accepts_sort_by_any_typed_record_fields_from_map_get` covering the map-block and list-comprehension `sort-by` over `Any`-typed record fields from `Map.get`.
- `tests/xsh/stdlib/streams.xsh` — new native test `test_sort_by_map_accumulator_any_typed_fields` asserting the runtime output matches the checker-accepted program.
- `docs/SPEC.md` — sort/sort-by contract now documents that statically-`Any`/unknown keys are accepted because the runtime sorts the actual supported scalar, and that non-orderable values still fail loudly.

## Tests

- `cargo test --test integration "sema::checker_"` → 91 passed, 0 failed.
- `cargo test -p xsh --test integration runtime::coverage::xsh_native_tests --features native-tests -- --exact` → ok (full native-test gate, includes new streams test).
- `./target/debug/xsht test streams` → 27 passed, 0 failed.
- `./target/debug/xsht check /tmp/sortprog.xsh` on the exact map-accumulator + list-comprehension pattern → accepts (no `check.stream-sort`), runtime prints/sorts correctly (verified via the native test).
- Full `cargo test --test integration runtime::` shows 2 pre-existing failures (`runtime::collections::fs_walk_streams_lazily_and_short_circuits_take_first_any_and_break` and `runtime::coverage::runnable_xsh_corpus_is_formatted_and_lints_without_warnings`); both were confirmed to fail identically on the base commit with these changes stashed, so they are unrelated to this change.

## North-star impact

Aligns the checker with the runtime on what can sort, so the common
`map.empty()` → `Map.get(k, fallback)` → record → `sort-by` pipeline (and its
list-comprehension form) type-checks the first time. This removes a
trial-and-error loop where `xsht check` rejected a program `xsh` ran correctly,
with a diagnostic that never named the real `Any` key type. Genuinely
non-orderable values still fail loudly at runtime, preserving the explicit
loud-failure boundary from task-ecount-003 and keeping the language composable
for any eval or user script that counts into a map and then sorts.

## Remaining risks

None. Runtime sort ordering, stability, and the loud-failure gate are
unchanged; the checker now accepts `Any` keys the same way the runtime sorts
their concrete values. A non-orderable `Any` value is still caught at runtime by
`lowered_sort_key_orderable`.
