# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

- There is no generic `Error(...)` constructor in this build, so a deliberate
  validation failure for a custom byte-exact condition cannot be constructed
  directly. `Str.parse_int`/`env.int` are not strict digit validators: they
  accept `-5`, `+5`, `1_0` (underscore separators) and `5 ` (trailing space),
  so they cannot double as the byte-exact "non-empty run of `0-9`" check the
  oracle requires. The only workaround was to force error via a conversion
  guaranteed to fail (`"".parse_int()?`), which is obscure. A first-class
  `fail`/`assert`/generic-error primitive would make validation failures
  explicit.
- Bitwise/logical `||` is rejected (`parse.unsupported-boolean-operator`) in
  favor of the word form `or`; the error message is clear, but a hard
  rejection of `||` is a small usability surprise for shell-style conditions.

## xsht friction

- `xsht lint` warns on the `Path(str)` cast for a dynamic argument and pushes
  the interpolated `fp"${...}"` form instead. The warning is a helpful nudge
  once the `fp` form is known, but `Path(argv.get(0)?)` is the only cast
  demonstrated by the handbook, so the lint guidance was initially opaque.

None.
