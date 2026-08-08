## Result

ready-for-review

## Branch

factory/task-histogram-008/1786216602930

## Commit

df60bdbf1a722daca096175c9473a79f99f78999

## Files changed

- `src/syntax/parser/expr.rs`: name reserved record-field words in diagnostics.
- `src/syntax/parser/stmt.rs`: name reserved schema-field words in diagnostics.
- `tests/syntax.rs`: parser regression coverage and quoted-key acceptance.
- `crates/xsht/tests/lint.rs`: typed record annotation usage coverage.
- `docs/SPEC.md`: canonical record-field diagnostic and quoting contract.
- Handbook candidate updated at the supplied run-scoped candidate path with the reusable reserved-field lesson.

## Tests

- `cargo test --test integration syntax::parser_ -- --test-threads=1` — 58 passed.
- `cargo test -p xsht --test integration lint:: -- --test-threads=1` — 55 passed.
- `cargo test --test integration sema:: -- --test-threads=1` — 101 passed.
- `cargo build -p xsht --bin xsht` — passed.
- `./target/debug/xsht check /tmp/record-clean.xsh` and `./target/debug/xsht lint /tmp/record-clean.xsh` — passed with no diagnostics.
- Reserved-field probe reports `parse.reserved-schema-field` / `parse.reserved-record-field` and names ``run``; quoted reserved keys parse successfully.
- `git diff --check` — passed; final worktree clean.

## North-star impact

Record construction now gives an actionable diagnostic naming the reserved word instead of a generic parser cascade, while typed record annotations are covered as legitimate type uses by lint. This reduces agent discovery turns and makes the explicit record-field boundary learnable without changing record value semantics.

## Remaining risks

The implementation diagnoses reserved keywords and requires non-reserved identifiers in typed schemas; quoted string keys remain supported for untyped literals. The linked task-histogram and post-merge eval replays remain controller/CTO validation work.
