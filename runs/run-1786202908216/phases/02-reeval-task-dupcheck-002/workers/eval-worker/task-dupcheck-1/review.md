# Task review

## XSH language proposals

- Print arguments are command-word tokens, so expression concatenation with
  `+` written inside a `print` call emits the operator as a separate literal
  token. A line must be built in an expression position (`let line = ...`)
  and then printed as a single value. This surprised me mid-task and the
  handbook already documents it; it is worth reinforcing because the failure
  mode is silent textual garbage rather than a parse error inside `print`.

## xsht friction

- `print $it.digest + "  " + $it.path` produced `digest +    + path` output
  instead of a parse/type error, which was easy to miss during inspection.
  There is no static signal that a `+` inside a `print` argument list is not
  string concatenation.
