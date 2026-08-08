## Result

ready-for-review

## Branch

factory/task-histogram-007/1786202910274

## Commit

fdd33b69fb70b2e8ecb2038cd1ff5561f5c99cfc

## Files changed

- `src/syntax/parser/expr.rs` — constructive diagnostics and replacement hints for `//` and `div`.
- `tests/syntax.rs` — parser/check regression coverage for unsupported spellings and valid `/`.
- `docs/SPEC.md` — canonical integer-division contract.
- Run-scoped handbook candidate updated with the reusable `/` spelling lesson.

## Tests

- `cargo test --test integration syntax::parser_reports_integer_division_spellings_with_int_division_guidance` — passed.
- `cargo test --test integration syntax::` — passed (102 tests).
- `cargo test -p xsht --test integration cli::` — passed (34 tests).
- `cargo build -p xsht --bin xsht` — passed.
- `xsht check` probe for `7 // 2` and `7 div 2` — exited 2 and printed `parse.unsupported-integer-division` with guidance to `/` on Int operands.
- `git diff --check` — passed; worktree clean after commit.

## North-star impact

XSH now gives a readable, check-time diagnostic for two natural-but-unsupported integer-division spellings and points directly to the existing truncating Int `/` operation. This makes numeric glue more learnable and explicit without adding an operator or changing division semantics.

## Remaining risks

None. The diagnostic is parser-level and intentionally does not alter valid `/` behavior or runtime semantics.
