# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

The documented `fail` validation primitive (`language:core.fail`) is advertised in the API but is not wired up as a callable in this build: `fail("...")` reports `unresolved pure function call` and `fail "..."` reports `unresolved proc command` across every signature I tried. Because there is no usable generic `Error(...)` either, a deliberate validation failure had to be induced indirectly through a typed conversion. A first-class, actually-callable validation-failure construct would be the reusable fix for rejecting a specific bad value.

## xsht friction

`language.core.fail` is documented with a signature and contract but cannot be invoked (both the call and command forms are unresolved during `check`), and the handbook states no generic `Error` constructor exists, so converting a deliberately-invalid value into a nonzero exit is not directly expressible. I worked around it by validating via `Str.delete("0123456789")` (the non-digit residue is never a valid integer, so `residue.parse_int()?` always fails) — functional but non-obvious. Minor: the boolean operator `||` is a parse error in favor of the word form `or`.
