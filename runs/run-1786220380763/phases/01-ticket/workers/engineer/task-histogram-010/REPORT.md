## Result

ready-for-review

## Branch

factory/task-histogram-010/1786220391269

## Commit

1231645ddce6a8aec37854109d57d3bbfd56691b

## Files changed

- `src/modules/text.rs`: trim surrounding whitespace in `parse_uint_positive` and add native boundary coverage.
- `tests/xsh/stdlib/methods.xsh`: cover script-level whitespace normalization.
- `docs/SPEC.md`: document normalization and retained validation boundaries.
- `crates/xsh-registry/src/signature/docs.rs`: expose the API contract in `xsht api` documentation.

## Tests

- `cargo test -p xsh --lib modules::text::tests::text_helpers_cover_script_methods` — passed.
- `cargo test -p xsh-registry --lib` — passed (8 tests).
- `cargo test -p xsht --test api` — passed (33 tests).
- `target/debug/xsht test tests/xsh/stdlib/methods.xsh` — passed.
- `target/debug/xsht check tests/xsh/stdlib/methods.xsh && target/debug/xsht lint tests/xsh/stdlib/methods.xsh` — passed.
- `git diff HEAD^ --check` — passed.
- The broader runnable-corpus gate was attempted but is currently blocked by pre-existing formatting and unresolved-name failures in unrelated files (`tests/xsh/stdlib/streams.xsh`, `core/tests/test-ifup.xsh`, `core/tests/test-ifdown.xsh`, and `tests/xsh/stdlib/fs.xsh`). No unrelated files were changed.

## North-star impact

`parse_uint_positive` now follows the existing unsigned parser's explicit whitespace-normalization contract, reducing caller guesswork while preserving rejection of zero, signs, malformed text, and overflow. The typed conversion remains composable for widths, ports, counts, and other system-glue boundaries.

A reusable parser-family normalization lesson was added to the supplied run-scoped handbook candidate; the approved snapshot and checked-in handbook were left unchanged.

## Remaining risks

The linked histogram replay is controller-owned and was not run in this product worktree; the existing replay evidence remains byte-exact. The broader corpus gate has unrelated baseline failures noted above. Otherwise None.
