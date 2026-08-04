# Engineer report

## Result

ready-for-review

## Branch

factory/task-ecount-008/1785809030662

## Commit

dcb2ad23636d5b3eceed23e72ac53ba65fd694b8

## Files changed

- crates/xsh-registry/src/reference.rs — `language:core.bindings` reference now states the `var` token, that `let` bindings are immutable, and that `let mut` is not valid syntax.
- src/sema/check/stmt.rs, src/sema/check/compact.rs — `check.assign-let` diagnostic now names `var` ("declare with `var` to allow reassignment").
- crates/xsht/tests/api.rs — regression test asserting `xsht api language:core.bindings` names `var`, `let` immutability, and invalid `let mut`.
- tests/runtime/coverage.rs — extended `reassigning_let_is_check_error` to assert the diagnostic names `var`.

## Tests

- `cargo test -p xsht --test api api_core_bindings_names_var_and_let_immutability` — passed.
- `cargo test -p xsht --test api` — 28 passed.
- `cargo test -p xsh-registry --lib` — 8 passed.
- `cargo test --test integration sema::` — 96 passed (assign-let checker paths unchanged).
- `cargo test --test integration runtime::coverage::reassigning_let_is_check_error` — passed.
- Manual: `xsht api language:core.bindings` prints "Bindings are immutable with `let`; declare a reassignable binding with `var` (`var x = 0; x = x + 1`). `let mut` is not valid syntax."
- Manual: `var total = 0; total = total + 1; print $total` `xsht check` exit 0 and `xsh` prints `1`.
- Manual: `let x = 1; x = 2` still errors `err[check.assign-let]` with message naming `var`.
- `git diff --check` — clean.

## North-star impact

Makes the mutable-binding keyword discoverable from the documented source of
truth (`xsht api language:core.bindings`) and from the point of failure
(`check.assign-let`). A first-time agent that needs a mutable counter or
accumulator can reach `var` directly instead of burning discovery turns
guessing `let mut` / `mut` / `let var`. This directly serves the north-star
goals of learnability ("clear enough for people to learn") and AI efficiency
("less unnecessary exploration, turns, and thinking"), and generalizes to any
eval or user script that needs mutable state. No binding or runtime semantics
changed.

## Remaining risks

None. The generic parse-time "expected `=` in binding" message for `let mut x
= 0` was left unchanged because it is shared across many non-mut binding parse
contexts, where a `var` hint would be misleading; the authoritative reference
and the assignment diagnostic now carry the guidance, and the handbook already
taught `var`.
