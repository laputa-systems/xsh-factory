# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

- Provide a generic `err`/`fail` constructor (or a `Result.err` helper) for
  deliberate validation failure. This build has no generic `Error(...)`
  constructor, so rejecting a *parseable* width value (`0`) required a hack:
  feeding a sentinel string to `Str.parse_int()?` solely to force an expected
  Result error. A first-class error-expression would make such validation
  direct.
- The integer division operator is `/` (`17 / 10` -> `1`), but the task and
  README idioms write `v // WIDTH`. `//` is rejected as a parse error (it is
  also not a comment in XSH). A documented operator spelling for truncated
  integer division (and its negative-value semantics) would remove the
  ambiguity.

## xsht friction

- `let path = ...` in a `[fs]` proc shadows the standard `path` module; the
  checker then reports cascading "unknown module API" and "pipeline sugar was
  not desugared" errors whose root cause is only the variable-name shadow.
  Use a different binding name (e.g. `file`).
- No clean way to reject `width <= 0` after `parse_int` succeeds; as noted
  under proposals, the absence of a generic error constructor forces the
  sentinel-string `parse_int()?` workaround. `0` would otherwise panic at
  runtime with "attempt to divide by zero".
- Lint flags `print $expr.join("...")` as "redundant command interpolation";
  the direct `print expr.join("...")` form is the accepted spelling here.
