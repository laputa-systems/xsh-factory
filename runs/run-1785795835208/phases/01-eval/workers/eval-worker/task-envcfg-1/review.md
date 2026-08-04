# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

There is no strict, byte-exact decimal-validator in the pinned image.
`Str.parse_int()` and `env.int()` are both lenient: they accept signs
(`-5`, `+5`), surrounding whitespace (` 5`, `5 `, `\t5`), and leading zeros,
while `env.int()` rejects out-of-range all-digit strings. None of these match
the task oracle's `[0-9]+` contract, so the port had to be validated with an
explicit `regex.compile("^[0-9]+$")` instead of a typed conversion. The image
also has no generic `Error(...)` constructor and no `require`/`assert` guard,
so a deliberate validation failure can only be forced by propagating an
unrelated typed-conversion error (`"".parse_int()?`). A strict unsigned
decimal parser, or a `require(cond, msg)` guard that yields an `Error`, would
make this kind of exact contract expressible without a side-trip through a
sentinel parse.

## xsht friction

`not` is not a boolean-negation keyword; negation must be written `== false`.
`match` arms take parenthesized patterns (`Ok(val) => ..., Err(msg) => ...`),
not brace patterns, and the bound `Error` value cannot be surfaced inside an
`f"..."` display string (display-conversion error), so debugging a match arm
requires returning a static sentinel. These match/negation details are not
called out in the handbook and were only pinned down by trial and error.
