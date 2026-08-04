## XSH language proposals

None.

## xsht friction

- No `Str.is_empty`/`isEmpty` method exists in the pinned image; emptiness is
  expressed via `byte_len() == 0` or `count_chars() == 0`.
- Boolean operators are word forms (`or`, not `||`); the `||` form is a parse
  error rather than accepted-and-normalized.
- Bare `let path = ...` shadows the standard `path` module and fails
  `xsht check`; the binding must be renamed.
