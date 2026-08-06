## XSH language proposals

- There is no constructor for deliberately producing an expected failure from a
  boolean predicate (`Error(...)` is absent). Validating extra conditions
  (e.g. "width must be positive after parse_int succeeds") currently requires
  an incidental host failure such as an intentional `1 / 0` division, which is
  non-obvious and produces a different exit shape than `?`-propagation of a
  typed conversion. A small `assert(cond)` / `require(cond)` that raises an
  expected error would make explicit validation cleaner and deterministic.
- `Str.parse_int` is permissive (accepts `"+5"`, `"-3"`, `"0x1F"`, and leading
  zeros), so enforcing "non-negative decimal integer" by parsing alone is
  insufficient. A strict decimal parser / validator (or a documented
  `parse_int` strict flag) would remove the need to hand-roll digit-only checks
  with `Str.delete("0123456789")`.

## xsht friction

- Display strings only interpolate with `${expr}`; a bare `$name` inside
  `f"..."` is literal text. I initially wrote `f"${g.key} $n $new_total"` and
  the output rendered the literal `$n` / `$new_total` instead of the values.
  This is a silent (no check-time warning) gotcha for users familiar with
  other interpolation syntaxes. The handbook does document `${expr}`, but a
  `lint` warning for a bare `$name` in a display string (analogous to
  `lint.dollar-in-expression-string`) would have caught it earlier.
