# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

- There is no strict, byte-exact decimal-integer validator. Both `env.int`
  and `Str.parse_int` are lenient (`+12`, `" 12"`, `0x10`, `-5` all parse), so
  matching a shell `[0-9]+` contract requires an explicit regex check plus a
  separate failure mechanism. A `parse_int`/`EnvInt` overload that rejects
  signs, whitespace, hex prefixes, and empty input would make byte-exact
  config validation first-class.
- There is no general way to construct an `Error`-family failure for
  deliberate validation rejection. `Err("...")` type-checks but produces a
  `Result[_, Str]` whose error family is incompatible with a `proc` returning
  the default `Error`, so it cannot be propagated with `?`. A
  `fail`/`Error(...)` primitive (or an `ensure(cond)` guard returning
  `Result[Unit, Error]`) would replace the awkward guaranteed-failing
  conversion (`"".parse_int()?`) used to exit nonzero on an invalid port.

## xsht friction

- `xsht fmt` rewrites a single-line display/`+` string literal into a
  multi-line `f"""..."""` form that the linter then misreports: variables
  interpolated/concatenated inside the multiline string are flagged as
  `unused-local` even though they are read. Constructing output with `+`
  concatenation avoided the false positive, but the formatter still splits
  it into a confusing structure while leaving `lint` clean.
- A deliberate validation failure surfaces as a runtime traceback on stderr
  with exit code 3 (rather than the oracle's exit 1). The task only requires
  a nonzero exit, but if an evaluator asserted an exact exit code, matching it
  would be impossible without a dedicated failure primitive.
