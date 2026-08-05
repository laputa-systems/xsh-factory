# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

- There is no general, idiomatic way to raise a deliberate validation error
  with a message. To exit nonzero on a "header not found" condition I had to
  abuse a typed conversion (`"__missing_header__".parse_int()?`), since no
  generic `Error(...)` constructor exists. A dedicated fail/error-raise form
  would make such control flow explicit.

## xsht friction

- Drilling into `argv`/`List` needs `?`: `argv.get(0)` and `ls.get(0)` return
  `Result[Str, Error]`, so they must be unwrapped; the error surfaces as a
  type mismatch otherwise.
- `print` treats arguments as command words, not expressions: `print "a=" $n`
  inserts a separating space, and `$n` is rejected inside an expression
  context. Exact output requires building text with a display string
  (`f"n=${n}"`) or `+` concatenation first. `Int` exposes no `to_string`
  method, so `+` with an Int needs an f-string.
- Converting a runtime `Str` to `Path` requires the documented
  `Path.parse_bytes(bytes.from_text(s))?`; a bare `Path(str)` cast is not a
  usable constructor for this.
