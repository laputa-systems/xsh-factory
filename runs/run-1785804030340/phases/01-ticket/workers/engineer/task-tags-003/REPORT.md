# Engineer report

## Result

ready-for-review

## Branch

factory/task-tags-003/1785804031017

## Commit

f0f0d87a1feaef07aa8ed1dce64cd9a5c70fdfb1

## Files changed

- `src/syntax/parser/literals.rs` — shift diagnostic spans from the interpolation sub-lexer/parser by the interpolation content's absolute source offset (root fix).
- `src/syntax/lexer.rs` — add a hint to the `lex.unexpected-character` error that points at a single quote, noting XSH strings use `"..."` not `'...'`.
- `tests/syntax.rs` — regression test `fmt_string_interpolation_errors_report_true_source_span`.

## Tests

- `cargo build --bin xsht --bin xsh` — build succeeds cleanly.
- `cargo test --test integration syntax::fmt_string_interpolation_errors_report_true_source_span` — ok (new regression test).
- `cargo test --test integration syntax::` — 99 passed, 0 failed (includes formatter, parser, and interpolation span tests).
- `cargo test --test integration diagnostics::` — ok (rendered-error stability).
- `cargo test -p xsh --lib syntax::lexer` — 3 passed, 0 failed.
- Manual `xsht check` reproductions:
  - `print f"tags: ${lowered.join(', ')}"` → both `lex.unexpected-character` now at true columns 3:32/3:35 with the single-quote hint (was phantom `1:14`/`1:17` at `...argv`).
  - `print f"a ${1 + } b"` → `parse.expected-expression` at true column of the stray `}` (2:19) instead of `1:5`.
  - Nested `f"a ${f"inner ${1 + } x"} b"` → correctly located at the inner stray brace.
  - Valid program with `f"..."`, `...argv` spread, `$name` command-word interpolation, and `r"..."` raw strings still passes `xsht check`/`xsht lint` and runs byte-for-byte.

## North-star impact

Fixes an opaque, trust-eroding diagnostic: a lex/parse error inside `${...}`
pointed at a valid, unchanged `proc` signature's spread parameter, which made
agents (and people) hunt a phantom `...argv` bug instead of the real typo. With
this change, f-string interpolation errors report the exact line/column and
token of the mistake, and a single-quoted literal now carries a one-line hint
that XSH strings use `"..."`. This turns a six-round debug loop into a single
read, generalizing to any script that uses `f"..."` interpolation regardless of
task. Valid interpolation semantics are unchanged (diagnostics only).

## Remaining risks

None known. The change is limited to diagnostic span attribution for errors
inside interpolation content and an added hint on the single-quote
unexpected-character error; runtime and formatting semantics are untouched.
