# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

There is no unsigned/non-negative integer parser (`parse_uint` is absent even
though the search hints at it). Validating "digits only, no sign" for file
values and "positive" for a width meant hand-rolling `delete("0123456789")`
checks and falling back to `abort(1)`, since `Str.parse_int` silently accepts
surrounding whitespace and `+`/`-` signs. A `Str.parse_uint() -> Result[Int,
Error]` (rejecting signs, whitespace, and non-digits) would cover the common
"non-negative decimal integer" contract directly.

## xsht friction

Integer division accepts only `/` on Int operands and truncates; `//` is a
parse error with a helpful hint (`unsupported-integer-division`). Fine once
known, but the task spec literally said `v // WIDTH`.

There is no generic `Error(...)` constructor, so validation failures that a
typed conversion cannot express (negative width, signed value lines) relied on
`abort(1)`. The handbook's "propagate an expected failure from a typed
conversion" guidance only covers inputs that parse/reject; the rest needs the
language-level `abort`, which produces no diagnostic on stderr by design.

List concatenation is `.extend(other)`, not `+` (check error: "list
concatenation does not use `+`"), and `Str` has no `trim_end`/`trim_start` —
only `trim()`. Building per-line output via a fold accumulator required
`.extend` on a growing list and each-`print` to avoid a trailing blank line.