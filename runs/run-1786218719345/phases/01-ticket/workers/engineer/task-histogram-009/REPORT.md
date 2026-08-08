## Result

ready-for-review

## Branch

factory/task-histogram-009/1786218728914

## Commit

e6d3fd96f9fa654c0d1c9f434f83b6984a60c204

## Files changed

- `crates/xsh-registry/src/runtime_op.rs`
- `crates/xsh-registry/src/signature/{methods.rs,docs.rs}`
- `src/modules/text.rs`
- `src/runtime/eval.rs` and `src/runtime/eval/{lower.rs,lowered_ops.rs}`
- `docs/SPEC.md`
- `tests/xsh/stdlib/methods.xsh`

## Tests

- `cargo test -p xsh-registry --lib` — passed (8 tests).
- `cargo test --test integration runtime::modules --no-default-features` — passed (34 passed, 2 ignored).
- `cargo test --test integration runtime::coverage::xsh_native_tests --no-default-features` — positive parser tests passed; suite has 3 pre-existing unrelated failures in `core/tests/test-ifup.xsh`, `core/tests/test-ifdown.xsh`, and `tests/xsh/stdlib/fs.xsh`.
- `cargo build -p xsh -p xsht --bin xsh --bin xsht` — passed.
- `target/debug/xsht api method:Str.parse_uint_positive` — exact discoverable API entry.
- Manual script check/run — valid input prints `42`; zero input exits nonzero with empty stdout and typed runtime traceback.
- `git diff --check` — passed; worktree clean after commit.

## North-star impact

Adds a discoverable, typed `Str.parse_uint_positive()` conversion for strict `> 0` decimal contracts. Agents can reject zero and malformed or signed input through an explicit Result/error boundary instead of using a division-by-zero signal workaround, improving clarity, learnability, and reliability for widths, sizes, counts, ports, and durations while preserving existing parse behavior.

## Remaining risks

The full native corpus remains blocked by the three unrelated baseline fixture failures listed above. The new parser returns the existing `Int` representation for positive values and deliberately accepts only decimal digits without trimming or signs.
