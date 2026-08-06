## XSH language proposals

- `//` is not an integer-division operator; the handbook examples and the
  task prompt use `v // WIDTH`, but XSH rejects `//` and `div`. Integer `/`
  on Int values silently performs integer division (truncated for
  non-negative operands). Consider supporting `//` as an explicit integer
  division operator (or documenting that `/` truncates for Int) so the
  intended math is explicit and not inferred from the operand type.
- `&&`/`||` are rejected as unsupported boolean operators; XSH requires the
  word forms `and`/`or`. This diverges from common XSH-style syntax examples
  and the check error could point to the accepted word form (it does). No
  change strictly required, but a `&&` alias would reduce friction.
- A proc with no effects clause is diagnosed as "unrestricted" and cannot be
  called from an effect-constrained proc. An empty `[]` effects clause solves
  it, but a pure helper that only does string math and returns a Result still
  needs an explicit `[]` clause. Consider inferring pure procs automatically.

## xsht friction

- The "unrestricted" diagnostic for a proc missing an effects clause is
  cryptic: `proc X is unrestricted — cannot call from a proc with declared
  effects`. It does not say to add `[]`, which is the actual fix for a pure
  helper. Suggest mentioning "add an effects clause (e.g. `[]`)".
- Binding a variable named `path` is rejected (`shadows the standard module
  `path``) but the message does not suggest a rename. Minor, but helpful to
  surface a concrete alternative like `file`/`src`.
