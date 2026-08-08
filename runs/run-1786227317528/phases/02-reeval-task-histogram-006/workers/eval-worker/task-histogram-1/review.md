# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

The task prompt (and common notation) uses `v // WIDTH` for integer division,
but `//` is not a valid lexeme in XSH: it produces `lex.unexpected-character`
/ `expected statement terminator`. Integer division on `Int` is performed by
the plain `/` operator (verified: `7 / 2 == 3`). Consider documenting `/` as
integer division, or adding a distinct `//` division operator/comment-visible
lexeme so prompts and code can share one spelling.

## xsht friction

- `argv.get(i)` returns `Result[Str, Error]`, so calling `.parse_int()` on it
  fails with `unknown method `parse_int` on Result[Str, Error]`; you must use
  the fallback overload `argv.get(i, default)` to obtain a bare `Str` before
  chaining typed parsers. The need for the fallback overload is not surfaced
  by the error message.
- `fp"${expr}"` interpolation rejects a `Result`-typed variable with the
  misleading message `value cannot be displayed in fmt string`; interpolating
  the unwrapped `Str` (e.g. via the fallback overload) works with no hint that
  the receiver type is the actual cause.

