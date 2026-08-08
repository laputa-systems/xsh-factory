## XSH language proposals

- `Str.parse_int()` is too permissive for a "decimal integer" contract: it
  accepts `0x10` (hex, =16), `+3`, `-3`, and surrounding whitespace. A task
  that requires a strict decimal run of digits had to validate the string
  separately before parsing. A dedicated `parse_decimal()` or a strict-parse
  flag on `parse_int` would remove the need to hand-roll digit validation.

## xsht friction

- Lint flags `$e.path.display()` as redundant and points to `$e.path`; the
  handbook's `print` guidance (dereference with `$var`) does not mention that
  `Path` values display automatically in command arguments, so the fix was
  driven by lint rather than by the handbook.
