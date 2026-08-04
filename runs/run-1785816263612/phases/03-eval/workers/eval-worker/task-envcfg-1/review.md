# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

The handbook repeatedly recommends using a typed conversion (`env.int` /
`parse_int`) to express a rejected input and let `?` produce a nonzero exit,
on the assumption that these are strict. They are not: `env.int` and
`parse_int` both accept `+5`, `-5`, ` 5`, and `0x10`, only rejecting empty and
non-numeric runs like `abc`. A byte-exact decimal contract therefore cannot be
expressed by any typed conversion in this build. A small proposal would be a
first-class boolean guard / `fail`/`require_true` primitive (or a generic
`Error`/`Err` that propagates through `?` with the standard error family) so
deliberate validation failures do not have to be routed through a sentinel
`parse_int` call. Today `Err("...")` yields `Result[_, Str]` and cannot
propagate through `?` into a function returning the standard `Error` family.

## xsht friction

There is no documented way to deliberately abort with a nonzero exit for an
arbitrary boolean condition without an unrelated host failure. The only
practicable route was `let _ = "sentinel".parse_int()?` inside an `if`, which
is opaque and depends on an unrelated value. Additionally, boolean operators
are word forms only: `||` is a parse error and must be written `or` (the
friendly error message explains this, which is good). `Str.len()` does not
exist (`len` is a List method); Str comparison against `""` was used instead.
