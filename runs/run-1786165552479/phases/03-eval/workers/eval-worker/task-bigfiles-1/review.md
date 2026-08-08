## XSH language proposals

None.

## xsht friction

- `List.get(i)` without a default returns `Result[Str, Error]`, which is easy to
  overlook when a script also has many `get(i, default)` calls that return a
  plain value; the resulting type-mismatch on `bytes.from_text(argv.get(0))`
  surfaced only at check time. A consistent return shape or clearer doc would
  help.
- There is no built-in digit-only predicate on `Str`; validating that `N` is a
  decimal integer required the `delete("0123456789")`-then-empty idiom plus an
  explicit empty-string guard, because `Str.parse_int()` eagerly accepts hex,
  sign, underscores, and surrounding whitespace (e.g. `0x10` -> 16). A
  `Str: is_digits()` helper (or a strict-decimal `parse_int` variant) would
  make the contract clearer.
