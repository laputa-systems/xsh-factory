## Result

ready-for-review

## Branch

factory/task-histogram-005/1786212466873

## Commit

2d255aa8297671339564f1f93587ec69c5f96cb5

## Files changed

- `src/modules/text.rs`
- `src/runtime/eval.rs`, `src/runtime/eval/lower.rs`, `src/runtime/eval/lowered_ops.rs`
- `crates/xsh-registry/src/runtime_op.rs`
- `crates/xsh-registry/src/signature/{methods,docs}.rs`
- `tests/xsh/stdlib/methods.xsh`
- `docs/SPEC.md`

## Tests

- `cargo test -p xsh --lib modules::text::tests::text_helpers_cover_script_methods` — passed.
- `cargo test -p xsh --lib modules::signature::tests::api_spec_adapter_exactly_mirrors_registry` — passed.
- `cargo test -p xsh-registry --lib` — passed (8 tests).
- `cargo test -p xsht --test api` — passed (32 tests).
- `cargo test --test integration libxsh_api` — passed (3 tests).
- `target/debug/xsht api method:Str.parse_uint` — exact API entry reported.
- `target/debug/xsht test tests/xsh/stdlib/methods.xsh` — passed.
- `cargo build -p xsh -p xsht --bin xsh --bin xsht` — passed.
- `git diff --check` — passed.
- `cargo test --test integration runtime::coverage::xsh_native_tests --features native-tests -- --exact` — failed only on three unrelated baseline fixtures (`core/tests/test-ifup.xsh`, `core/tests/test-ifdown.xsh`, `tests/xsh/stdlib/fs.xsh` unresolved names); 312 passed, 6 skipped.

## North-star impact

Adds a discoverable, typed `Str.parse_uint()` operation for strict non-negative decimal validation. Agents no longer need a regex-plus-empty-string forced-failure workaround, while signed input, radix prefixes, malformed input, and overflow remain explicit errors.

## Remaining risks

The full native corpus remains blocked by three unrelated baseline fixture failures listed above. `parse_uint` returns `Int` (matching the existing runtime integer representation) and accepts only decimal digits, as documented.
