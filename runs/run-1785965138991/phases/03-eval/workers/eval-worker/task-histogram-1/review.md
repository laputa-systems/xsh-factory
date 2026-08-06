## XSH language proposals

- Postfix `?` error propagation is rejected inside a helper procedure that
  returns a non-Result type (it reports `check.try-context: ? requires a
  Result-returning context`), even when the proc declares the `[error]`
  effect. The same `?` works inside `main` (returning Unit) and inside stream
  blocks nested in `main`. This asymmetry forces either inlining all fallible
  work into `main` or making helpers return `Result`. Proposal: allow `?` in
  any proc that declares the `error` effect, not just Result-returning or
  top-level contexts, so small validation helpers can propagate naturally.

- There is no general assertion / error constructor for deliberate validation
  failures, so rejecting an input that a permissive conversion accepts (e.g.
  a sign, hex, or underscore in what must be a plain decimal integer) has no
  clean typed expression. Proposal: expose a first-class `Error(...)`/assert
  primitive that participates in the `error` effect, instead of routing such
  rejections through an artificial failing `parse_int()`.

## xsht friction

- `Str.parse_int()` is far more permissive than a "decimal integer"
  contract: it accepts `+5`, `-5`, hex `0x10` (as 16), digit separators
  `1_0` (as 10), and leading zeros. Enforcing the task's "non-negative
  decimal integer, no sign" rule therefore required a separate
  digit-only sanity check (`s.delete("0123456789") != ""`); worth documented
  in the method contract.

- Integer division uses `/` (and remainder `%`); the handbook's task brief
  wrote it as `//`, which is not valid XSH. A terse arithmetic-operator
  reference would remove guesswork.

- `let path = ...` shadows the standard `path` module (check error
  `standard-module-shadow`), and `xsht lint` prefers `fp"..."` interpolation
  over `Path(...)`. Neither is fatal, but both surfaced as early stumbling
  blocks on an otherwise-straightforward pipeline.
