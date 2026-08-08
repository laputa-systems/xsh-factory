# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

- An `if` used as an expression (`let n = if ... { let s = ...; ... } else { ... }`) rejected a statement block in a branch with repeated `expected expression` parse errors. I had to restructure to a `var n = 5` plus a statement-style `if` that assigns inside the branches. Worth documenting that `if`-expressions only accept single-expression branches (no local `let` bindings or multi-statement blocks).
