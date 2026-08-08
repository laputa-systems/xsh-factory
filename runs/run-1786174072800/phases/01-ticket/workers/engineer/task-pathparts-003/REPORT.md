## Result

ready-for-review

## Branch

factory/task-pathparts-003/1786174073904

## Commit

f697fa2453f676f686c685171f5a8a9d514f871e

## Files changed

- `src/syntax/literal.rs` — recognize `$name` and `$field.path` display-string shorthand in the shared interpolation scanner.
- `crates/xsht/tests/lint.rs` — regression test for display-string reads and genuinely unused locals.
- `tests/syntax.rs` — parser coverage for shorthand display-string interpolation.
- `docs/SPEC.md` — canonical display-string interpolation contract.

## Tests

- `cargo test --test integration syntax::parser_accepts_display_string_shorthand_interpolation -- --exact` — passed.
- `cargo test --test integration syntax::parser_accepts_raw_triple_and_nested_fmt_strings` — passed.
- `cargo test --test integration syntax::parser_accepts_nested_interpolation_boundaries_from_shared_scanner` — passed.
- `cargo test --test integration syntax::` — 101 passed.
- `cargo test -p xsht --test integration lint::` — 54 passed.
- `cargo test -p xsht --test integration` — 99 passed.
- Acceptance smoke test: `xsht check` passed; `xsht lint` passed for `print f"dir=$dir"`; runtime output was `dir=tmp`.
- `git diff --check` — passed.

## North-star impact

Display strings now use the same `$name` shorthand already accepted by XSH's documented output idiom, and lint's AST traversal sees the shorthand as an actual binding read. Agents can compose exact dynamic output without discovering a concatenation workaround, while genuinely unused locals remain diagnosed. The shared scanner also keeps expression interpolation and path-format interpolation behavior consistent.

The reusable lesson was staged in the supplied run-scoped handbook candidate: display strings support `$name`/field shorthand and both forms count as lint reads.

## Remaining risks

None known. The product worktree is clean and the committed branch is ready for CTO review.
