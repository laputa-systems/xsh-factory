# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

- XSH has no `//` integer-division operator; integer division is the single
  `/` on Int operands. The task prompt's `v // WIDTH` had to be written as
  `v / width` (valid for the non-negative values this task allows).
- Boolean operators are word forms only: `||`/`&&` are parse errors, so I had
  to write `or` instead of `||`.
- A Str method cannot be used as a bare pipeline stage name: `|> Str.lines()`
  is an unresolved name; the receiver must be called explicitly
  (`text.lines()`).
- Validating a positive/decimal contract has no direct predicate or
  constructor; I detected invalid input and forced a nonzero exit by
  propagating `".".parse_int()?`, relying on runtime error propagation.
