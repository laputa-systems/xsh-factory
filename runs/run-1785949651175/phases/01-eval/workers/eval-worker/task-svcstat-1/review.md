# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

Boolean operators are inconsistent with common notation: conjunction must be
`and` (`&&` is a parse error) while negation uses C-style `!` (`not` is a
parse error). Having `!` for negation but word-form `and` for conjunction is
easy to trip on. Also, there is no generic `Error(...)` constructor; forcing a
validation failure requires abusing a typed conversion such as
`"".parse_int()?`, and `Err("msg")` yields `Result[T, Str]`, which `?` cannot
propagate from a function returning the Error family. A first-class "expected
failure" constructor would make deliberate input validation expressible.

## xsht friction

`xsht api summary` nests methods under parentheses-qualified headings (e.g.
`Str (28 items)`), so enumerating a type's methods requires sed-range slicing
rather than a flat listing; a `method:Str` query is explicitly rejected. Minor:
`Path(...)` on a dynamic arg triggers a lint warning suggesting `fp"..."`
interpolation, which was easy to resolve but not immediately obvious from the
handbook.
