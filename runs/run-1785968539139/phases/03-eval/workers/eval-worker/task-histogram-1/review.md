# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

There is no clean way to deliberately raise a typed error for input validation. A proc `[error]` can propagate an expected failure only by triggering a real host conversion such as `parse_int` on a deliberately malformed literal (e.g. `"".parse_int()?` inside a conditional arm). A first-class `fail`/`panic`, or a validated unsigned/decimal `parse_uint`, would express rejected input (negative/oversized values, sign-bearing decimal) without fabricating a failing conversion.

## xsht friction

`//` is rejected as a parse error (it is not integer division nor a comment marker; only `#` comments), and `/` on two Int values silently performs truncated integer division. I confirmed `7 / 2 == 3` only by running it; there is no documented integer-division operator. Also, `Ok(())` is invalid because `()` is not an expression, and constructing `Err("msg")` yields a Str-typed error that is incompatible with the `error` effect's opaque `Error`, so no unit result/`Err` can be produced for validation helpers.
