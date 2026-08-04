# Engineer report

## Result

ready-for-review

## Branch

factory/task-envcfg-003/1785789595996

## Commit

71e7b84552a5a5614347c8c6faf064f76fd85317

## Files changed

- `src/syntax/parser/expr.rs`: in `parse_precedence_arena_only`, when the
  precedence loop would otherwise break on an unsupported token, call a new
  `report_unsupported_boolean_operator` helper; the helper emits a constructive
  diagnostic naming `||`/`&&`/`|`/`&` and the supported word forms
  `or`/`and`, plus a separate diagnostic for the `then` token.
- `src/syntax/parser.rs`: add a `peek_end(distance)` helper (mirrors
  `peek_start`) used to span the two-token `||`/`&&` forms.
- `tests/syntax.rs`: two new parser regression tests — one asserting the
  constructive diagnostic codes fire for `||`, `&&`, `|`, `&`, `then`; one
  asserting valid `or`/`and`/`and`-chains parse without diagnostics.

## Tests

- `cargo test --test integration syntax::parser_reports_unsupported_c_style_boolean_operators_constructively` — passed (1/1).
- `cargo test --test integration syntax::parser_accepts_word_form_boolean_operators` — passed (1/1).
- `cargo test --test integration syntax::` — passed (98/98, no regressions).
- Manual `xsht check` on `proc main() { if a || b { } }` now reports
  `err[parse.unsupported-boolean-operator]: unsupported operator '||': XSH
  boolean operators are the word forms 'or'` with the caret on `||`; likewise
  for `&&`, `|`, `&`, and a `then` diagnostic. `if a or b/full valid`, `if a
  and b`, pipelines (`|>`), and block params (`|x|`) still check clean.
- `git diff --check` clean; worktree clean after commit.

## North-star impact

Turns a ~10-turn operator-spelling discovery into a one-line, learnable
diagnostic. Any agent (or person) writing unsupported `||`/`&&`/`|`/`&` or a
`then` keyword is now named the offending token and the supported word-form
`or`/`and` spelling, with the caret on the operator instead of the block brace.
This is precisely the kind of precise, explicit-boundary, learnable behavior
the north star asks for — it improves any condition parse, is not an envcfg
shortcut, and preserves valid `or`/`and` semantics unchanged.

## Remaining risks

None. The change is diagnostic-only: no grammar, operator-precedence, or
valid-program parsing behavior was altered. No false positives observed on
valid pipelines, block parameters, or `or`/`and` chains; the broader
`task-envcfg` replay is handled by the linked eval-manager post-merge.
