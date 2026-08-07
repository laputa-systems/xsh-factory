# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

There is no sanctioned way to reject a strict non-negative-decimal token when
`Str.parse_int` is lenient. `parse_int` accepts `-5`, `+5`, `0xff`, and
`1_000`, so it cannot express rejection of inputs the task defines as
invalid ("no sign", decimal only). The generic `Error(...)` constructor is
removed, and `Err("...")` produces a `Result[_, Str]` that cannot be
propagated from a procedure returning `Error` (`Result.context` adds a label
but does not change the payload type). There is no `parse_uint`/strict
decimal conversion that fails on a sign or non-decimal digit, so achieving
the required nonzero exit for such inputs required generating a failure from
an unrelated token. A strict unsigned-integer parse (`parse_uint`) or a small
sanctioned error constructor would be the clean fix.

## xsht friction

`//` is parsed as a comment marker and causes a parse error, not integer
division; integer division on two `Int` values is spelled `/` (`7 / 2 == 3`)
with `%` for remainder. This was not documented and required runtime probing
to discover. Constructing a valid `Error` value to abort a procedure was
non-obvious: `Err(Str)` is rejected as an incompatible propagated error and
would benefit from a documented, constructible variant.
