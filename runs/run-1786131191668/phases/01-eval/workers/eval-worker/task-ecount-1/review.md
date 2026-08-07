# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

- Effect-free function declarations use the `pure` keyword, not `fn`; writing
  `fn` parses but fails with a misleading `expected expression` at the closing
  brace. `xsht api language:core.pure-functions` is the only place this is
  documented; discovery via trial and error was confusing.
- A function body cannot end with a bare `if`/`else` expression even when both
  branches return values; the checker reports `missing-return`. The `if` must
  be bound to a `let` and that binding returned as the final expression.
- `List.get(index)` returns `Result[...]`, so chaining a method such as
  `.lower()` on it fails type-check; the fallback overload
  `List.get(index, fallback)` is required in pure functions that cannot use
  `?`.
- A parameter named `path` is rejected by lint as shadowing the standard
  `path` module; unrelated `Path` values must use another identifier.
- BusyBox `uniq -c` right-aligns the count in a width-7 field (6 spaces for a
  one-digit count), differing from the GNU width-6 convention; the width had
  to be measured from the oracle output rather than assumed.
