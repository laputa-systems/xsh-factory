## XSH language proposals

There is no generic `Error(...)` constructor in this build, and the `fail(...)`
language rule surfaced by `xsht api language:core.fail` is not actually callable
(`xsht check` reports `unresolved pure function call`). For a deliberate
validation failure (reject a non-decimal `CFG_PORT`), the only deterministic
route is to force a typed-conversion error, e.g. calling `parse_int` on a
literal invalid string guarded by the regex check. A first-class, callable
`fail`/validation error constructor would make this pattern clearer and avoid
the parse-a-sentinel trick.

## xsht friction

`env.int`/`env.bool` are documented as non-strict convenience readers, so a
byte-exact decimal-integer contract (rejecting `-5`, `+5`, and whitespace the
way `case *[!0-9]*` does) cannot rely on them; an explicit `^[0-9]+$` regex
check is required while still outputting the raw string to preserve values like
`007`.
