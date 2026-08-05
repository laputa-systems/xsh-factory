# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

There is no generic way to fail deliberately on a validation condition that a
typed conversion cannot express (e.g. a width that parses as an integer but is
not positive). `?` propagation is only wired to `Result`-returning
conversions, and there is no `Error(...)` constructor or assertion primitive.
I worked around it by calling `"".parse_int()?` in the failing branch, which
is an unrelated host failure and not an expression of the actual rejection. A
first-class `require(cond, msg)` / custom-error constructor would let programs
reject invalid-but-double-checked inputs cleanly.

## xsht friction

`?` propagation is context-sensitive in a surprising way: it works inline in a
Unit-returning `main` (`let x = f()?`) and inside stream map blocks, but a
standalone helper declared `-> Int` that does `return "".parse_int()?` is
rejected with `check.try-context: ? requires a Result-returning context`. The
two spots behave differently despite the same declared `[error]` effect.
Also, list concatenation is `.push`/`.extend`, not `+`; the checker's note was
helpful but this differs from common expectation.
