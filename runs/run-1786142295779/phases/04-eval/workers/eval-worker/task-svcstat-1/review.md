## XSH language proposals

- There is no generic `Error(...)` constructor and no obvious way to build a
  deliberate `Err` value for validation failure. The only sanctioned route is
  to drive a typed conversion such as `parse_int` into failure and propagate it
  with postfix `?`. A generic validation-error constructor would make manual
  field validation (service token charset, digit-run check) cleaner than
  forcing an artificial `parse_int` failure.

## xsht friction

- Postfix `?` for validation propagation only works inside a procedure that
  itself returns `Result` ("`?` requires a Result-returning context"). The
  initial parse helper returned a plain record type (`-> Entry`), and the
  compiler rejected every `let _ = "...".parse_int()?` inside it; changing the
  signature to `-> Result[Entry, Error]` resolved it. This is worth a clearer
  note: a bare `?` cannot be used to abandon a non-Result procedure.
