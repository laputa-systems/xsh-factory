# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

- Add an Int->Str conversion (or reuse display-string interpolation as a named
  method) and a Str pad/repeat method. There is no `Int.to_string` (Int only
  exposes `float`) and no string-repetition/padding primitive, so producing the
  oracle's width-7 left-padded counts required `f"${count}"` plus
  `byte_slice` of a hard-coded 7-space literal.
- Allow an `if/else` to serve as a stage block's tail expression. Both `map`
  and `flat-map` rejected a block whose final statement was an `if/else`
  returning a list ("map requires a tail value", "flat-map blocks must produce
  List or Stream"); the workaround was binding the result to a `let out` and
  returning `out`.

## xsht friction

- `where { |e| e.kind == "file" }` (block form with a field access) is
  rejected with `check.unresolved-proc-command`, while the shorthand form
  `where .kind == "file"` type-checks and runs. The failure message does not
  point at the cause and makes the valid block/parameter form appear
  broken.
- `Str.split` on a trailing separator does keep the empty trailing field
  (matching awk), but this is undocumented in the checked signature and was
  discovered only by an explicit fixture; a one-line contract note would save
  re-verification.
