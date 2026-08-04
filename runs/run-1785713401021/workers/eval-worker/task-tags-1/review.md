# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

- In `print`, arguments are parsed as command words: `print "tags:" + line`
  is not string concatenation and emits a literal `+` with extra spaces.
  Compute the combined string in a `let` with `+` (which does concatenate in
  expression position) and then pass it via `$var` interpolation.
- Expression string literals do not interpolate (`let s2 = "tags:${j}"` is a
  parse error); interpolation is only valid in command (print) words.
