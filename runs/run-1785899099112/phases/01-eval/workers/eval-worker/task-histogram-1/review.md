# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

- `map` (and other stream stage) blocks require a non-`if` tail expression: a block ending in `if ... { a } else { b }` fails with `map requires a tail value`, even though `if` is a valid value expression in `let` and proc statement contexts. Workaround: bind the choice with `let probe = if cond { t } else { "x" }` and end the block with a non-`if` expression.
- `?` postfix requires a Result-returning context, so a helper `proc ... -> Int` cannot use `?` even with the `error` effect. Inline the work in `main` (which propagates) or make the helper return a Result type.
