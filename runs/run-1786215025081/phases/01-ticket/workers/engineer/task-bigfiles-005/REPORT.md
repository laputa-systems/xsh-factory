## Result

ready-for-review

## Branch

factory/task-bigfiles-005/1786215040119

## Commit

b25b06dfd5bf6a4ae653ea6a4fccd4d54016312b

## Files changed

- `src/modules/text.rs`: strict decimal parser and native coverage.
- `src/runtime/eval.rs`, `src/runtime/eval/lower.rs`, `src/runtime/eval/lowered_ops.rs`: method lowering and runtime dispatch.
- `crates/xsh-registry/src/runtime_op.rs`, `crates/xsh-registry/src/signature/methods.rs`, `crates/xsh-registry/src/signature/docs.rs`: API registration and reference.
- `docs/SPEC.md`: canonical language contract.
- `tests/xsh/stdlib/methods.xsh`: acceptance coverage.

## Tests

- `cargo test -p xsh --lib modules::text::tests::text_helpers_cover_script_methods` — passed.
- `target/debug/xsht check tests/xsh/stdlib/methods.xsh` — passed.
- `target/debug/xsht lint tests/xsh/stdlib/methods.xsh` — passed.
- `cargo test -p xsh-registry --lib` — passed (8 tests).
- `cargo test --test integration sema::checker_accepts_str_parse_float --no-default-features` — passed.
- `cargo test --test integration runtime::coverage::xsh_native_tests --no-default-features` — 312 passed, 3 pre-existing unrelated fixture failures (`test-ifup`, `test-ifdown`, `fs.xsh`); the new methods test passed.
- `git diff --check` — passed.
- Worktree clean after commit.

## North-star impact

Adds a discoverable, typed `Str.parse_int_decimal()` Result surface that rejects radix prefixes, signs, whitespace, separators, leading zeros, and overflow while preserving lenient `parse_int()`. This lets systems-glue programs express byte-exact numeric boundaries with one composable `?` failure path instead of a digit check plus sentinel-invalid workaround.

## Remaining risks

The full native corpus remains blocked by unrelated baseline fixture failures in `core/tests/test-ifup.xsh`, `core/tests/test-ifdown.xsh`, and `tests/xsh/stdlib/fs.xsh`; the focused parser, API, semantic, and new native acceptance checks pass.
