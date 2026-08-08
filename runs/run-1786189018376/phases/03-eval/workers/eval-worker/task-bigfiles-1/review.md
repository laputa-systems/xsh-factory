# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

- `if cond {} else {}` used as an expression (e.g. `let x = if ...`) requires each branch to be a single expression; `let`/statements inside those branches fail to parse. To run statements conditionally, use `if` as a statement and assign into a `var`. This distinction is not obvious from the error (`expected expression` pointing at the statement inside the branch).

- `Str.parse_int` accepts hex (`"0x10"` -> 16) and other radix forms, so it is not a strict decimal validator. A task demanding "decimal integer" must filter digits manually (`s.delete("0123456789")`) and reject a non-empty remainder.

## xsht friction

- `Path(str)` is accepted by `xsht check` but `xsht lint` warns to prefer the interpolated p-string form `fp"${str}"`; use the p-string form to keep lint clean.
