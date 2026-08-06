# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

There is no general `Error(...)` constructor, so rejecting a semantic condition
(such as a non-positive WIDTH, or a value with an explicit sign that a regex
already confirmed is invalid) had no direct expression. I had to synthesize a
failure by calling `"...".parse_int()?` on a deliberately malformed string so
the postfix `?` would exit nonzero. A typed primitive for "fail with expected
error" (or a Result-returning guard) would make validation contracts much more
readable and less hacky.

## xsht friction

`?` inside a stream `map` block is rejected when the block's tail is a
conditional: an `if ... { -1 } else { ...parse_int()? }` map body reported
"map requires a tail value", and a `where` stage after such a map then produced
a confusing type mismatch. The working shape required filtering blanks in a
separate `where` stage and keeping the `?...` expression as the single map
tail. The diagnostic did not point at the real cause (`?` occupying a
Result-context in a branching tail).

The task text used `v // WIDTH` for integer division, but `//` is a parse error
in XSH ("expected statement terminator"); integer division for Int operands is
`/`. This is documented in the handbook, but an `xsht api` search for the
division operator returned nothing, so the operator had to be discovered by
trial and error.
