# Task review

## XSH language proposals

None.

## xsht friction

- `Str.parse_int()` accepts hexadecimal (`0x10` -> 16) and signed (`+5`) input,
  so it is not a strict decimal-integer validator. A task that requires "decimal
  integer" semantics and nonzero-exit for non-decimal input has no dedicated
  strict-decimal parser; the workaround is a manual digit-only check via
  `s.delete("0123456789") == ""` before parsing, or accepting that ambiguous
  forms like `0x10`/`+5` parse. This is easy to miss and there is no generic
  `Error(...)` constructor to force a clean typed failure.
