# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

A deliberate validation failure has no clean construction: the build has no generic
`Error(...)` constructor and no typed conversion that expresses this task's strict
`[0-9]+` port contract (Str.parse_int accepts `+12`, `-1`, and `' 12'`). I had to
signal rejection by calling `env.get("<sentinel>")?`, which fails for an unrelated
reason. A strict byte-format predicate (e.g. an `is_decimal()` check) or an explicit
error-raising form would let a program reject malformed input through its own path.

## xsht friction

Result introspection is minimal: `is_err`/`is_ok` are undefined on `Result[T, Error]` in
the pinned image, so I could not simply branch on a result to probe behavior and had to
discover conversion semantics (which values parse_int accepts) by running throwaway
scripts. `print` also rejects expression concatenation and bare identifiers in argument
position, which made quick Result-behavior probes noisy until I routed output through
`fs.write`. These are documented but slow down exploration.
