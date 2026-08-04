# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

Provide a first-class deliberate-failure primitive (e.g. `fail(msg)` or
`assert(cond, msg)`) that yields a nonzero exit. Today there is no generic
`Error(Str)` constructor: `Err("...")` requires an `Error` value, not a `Str`,
so a validation failure must be manufactured by parsing a hard-coded probe
string (`"x".parse_int()?`). A real `fail`/`expect` would make validation
failures direct and self-documenting.

## xsht friction

`env.int()` and `Str.parse_int()` are lenient parsers: they accept leading or
trailing whitespace, a sign (`-5`, `+5`), and hex (`0x10`), so a byte-exact
"run of decimal digits" contract (like the CFG_PORT oracle) cannot be checked
with the typed conversions alone. I had to hand-validate with
`Str.delete("0123456789")` plus the fabricated `"x".parse_int()` probe to get
a nonzero exit. A documented strict unsigned-decimal validator would remove
the hack. Also, boolean combinators are inconsistent: `or` and `and` work but
`||`, `&&`, and `not` are parse errors.
