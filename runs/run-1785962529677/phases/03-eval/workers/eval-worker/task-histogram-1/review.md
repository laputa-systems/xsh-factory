# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

There is no way to raise a deliberate validation error. `parse_int` accepts
signs and hex (`-5`, `+5`, `0x10`) and length-1 values are fine, but the task
required rejecting non-negative/no-sign violations (a negative file line, a
non-positive width), which `parse_int()?` cannot express. With no `assert`,
`fail`, or `Error(...)` constructor available, the only deterministic abort
was a contrived `("x" + bad).parse_int()?` to force a failing result. A
primitive like `assert(cond, msg)` or a `fail(msg)` that returns a failing
Result would let validations abort cleanly instead of abusing a parse error.

## xsht friction

- Integer division in the task text is written `//`, but in XSH `//` is a
  parse error (`expected statement terminator`); the actual operator for Int
  is `/` (truncating division). This mismatch is easy to hit and hard to
  discover from the handbook, which only says `//` is not a comment.
- `xsht api method:Str.matches` leads nowhere: `matches` lives on the `Regex`
  receiver (`Regex.matches(text)`), not on Str, and the summary's grep hints
  are too sparse to find it. Also `Str.parse_int` is very lenient (accepts
  `+5`, `-5`, `0x10`, `1_000`, `007`, surrounding whitespace), so a strict
  "no sign, optional whitespace" contract requires extra regex validation
  that the parse API does not advertise.
