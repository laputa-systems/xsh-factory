## XSH language proposals

`Str.parse_int` is not a strict decimal validator: it accepts a leading sign (`CFG_PORT=+5` parses successfully and exits 0), whereas a digit-only port contract must reject it. Byte-exact decimal input therefore has to be validated explicitly (e.g. via `Str.delete`) before, or independently of, a parse-based failure path.

## xsht friction

None.
