# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

A `parse_uint`/unsigned integer parser would remove a real gap: `Str.parse_int` accepts an optional sign ("-5", "+3" both parse), so rejecting signed input for a strict non-negative contract requires an extra regex check. There is also no generic `Error(...)` constructor, so a deliberate validation failure has to be expressed by parsing an empty string (`"".parse_int()?`), which is opaque and easy to misread. A built-in way to construct or force a typed error would clarify the intended-rejection path.

## xsht friction

`?` postfix is rejected inside a user procedure whose declared return type is not `Result[...]`, even when that procedure declares the `error` effect (`err[check.try-context]: ... requires a Result-returning context`). A small helper that returns `Int` and wants to propagate a parse failure must instead be rewritten to return `Result[Int]` (returning the `Result` without `?`) and have the caller apply `?`. This is surprising relative to `main`, where `?` works without an explicit `Result` return type.

