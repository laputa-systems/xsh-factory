# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

- `print` treats its arguments as command words, so an expression such as
  `print $r.digest + "  " + $r.path` silently emitted each operand (including
  the literal `+` tokens) as separate output fields instead of concatenating.
  It was not a parse error; the fix was to bind the concatenation to a `let`
  and print that single value. This silent misfire is easy to miss when
  composing exact-output lines.
- `hash.sha256(path)` returns `Result`, and using `?` inside a `map`/stream
  block required the enclosing `proc` to declare the `error` effect; forgetting
  it failed `xsht check` with `check.effect-violation` rather than a clearer
  "add the error effect" hint on the block itself.
