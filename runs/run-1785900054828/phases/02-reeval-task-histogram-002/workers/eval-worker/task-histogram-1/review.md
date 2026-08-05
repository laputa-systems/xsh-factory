# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

`//` is not usable as a division/comment token in an expression: writing
`v // width` produces a parse error (`expected statement terminator`) that is
hard to map to the actual problem, while `/` is the integer-division operator.
A documented, discoverable integer-division/floor-division operator would
remove the guesswork.

## xsht friction

- A `fold` block that calls `print` (a side effect) fails type-check with a
  cryptic `indexed IR could not encode \`full_ir_function_blocker\`` at the
  procedure's closing brace, with no hint that the fold block must be
  effect-free. The solution had to compute cumulative rows inside the fold and
  print them in a separate loop.
- `fn` is not the declaration keyword (it is `pure`); using `fn` reports a
  generic `expected expression` at the function's closing brace rather than an
  "unknown keyword" diagnostic, making the mistake hard to diagnose.
