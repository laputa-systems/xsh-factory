# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

The lack of a generic error constructor makes deliberate validation failure
awkward when the host value is a raw string. To reject a malformed `CFG_PORT`
I had to keep the raw string for output (to preserve leading zeros like
`08080`, matching the oracle) yet still produce a nonzero exit, which was only
possible by invoking `env.int(...)?` as a hidden failure trigger. A first-class
`Error(msg)`/`fail` primitive, or a way for `?` to accept a rejected value
without a typed conversion, would let validation and output use the same value.

## xsht friction

- `xsht api` could not address the `Path` constructor by any selector I tried
  (`api:path`, `constructor:Path`, `Path constructor`); I had to verify `Path(str)`
  and `fp"..."` by trial and error.
- `xsht fmt` silently rewrote a plain `+` string concatenation into a
  triple-quoted multiline literal; semantically identical but non-obvious, and
  it made the intended output harder to read in the source.
