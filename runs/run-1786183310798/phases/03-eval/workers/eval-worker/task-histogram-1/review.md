# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

Postfix `?` is rejected inside a user procedure that declares a concrete return type such as `-> Int`, even when that procedure declares the `error` effect (`err[check.try-context]`). The same `?` is accepted in a `Unit`-returning `main`, in `Result`-returning procedures, and inside stream block expressions. This forced restructuring helpers into inline `map` blocks (or `Result` returns) rather than reusable `-> Int` helpers, and is not called out in the handbook. A clearer rule (or an explicit message naming the required `Result` context) would have saved a round trip.
