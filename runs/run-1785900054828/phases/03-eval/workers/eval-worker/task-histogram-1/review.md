## XSH language proposals

- There is no general error/`raise`/`guard` constructor, so deliberate validation
  failures (e.g. rejecting `WIDTH=0` or a negative value) have no dedicated
  mechanism. The only sanctioned route is to route an invalid input through a
  typed parse that naturally fails (feed `""` to `parse_int`). A `guard(expr)`
  or `ensure(expr) -> Result[Int, Error]` facility would make contract
  validation much more expressive.

- A `fold` combinator's block cannot contain a side effect such as `print`; it
  fails at IR build time with `indexed IR could not encode
  full_ir_function_blocker`. There is no obvious reason a fold body should be
  restricted from emitting output (this is the natural place to emit running
  aggregates). Either allow side effects in fold bodies or document a
  first-class "cumulative fold" stage.

## xsht friction

- `//` is NOT integer division: it is a comment marker and `v // w` is reported
  as `expected statement terminator`. Took a scratch probe to discover that
  integer (truncated) division of non-negative `Int`s is plain `/` (`v / w`).
  The handbook warns about this but it is easy to hit.

- `lint.path-constructor` is an *error* (exit code 1) for `Path(file)` and
  insists on `fp"${file}"`. Fine once known, but the error exit made the lint
  pass appear to fail on something that type-checks and runs correctly.

- There is no generic error constructor in the pinned build, so rejecting a
  condition (e.g. width must be positive) requires the `""`-into-`parse_int`
  workaround described above.
