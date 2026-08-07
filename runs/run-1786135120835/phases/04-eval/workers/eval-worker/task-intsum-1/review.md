# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

There is no generic `Error(...)` constructor or dedicated validation/fail
primitive, so a deliberate validation failure has no direct expression. To
reject an argument whose format was already disproved by a regex match, the
solution had to force a guaranteed failure through a bogus literal
(`"bad-value".parse_int()?`). A first-class fail/assert that produces an
expected Result error would make such validation both clearer and less
contingent on parse behavior.

## xsht friction

`xsht api summary | grep Str` is not a usable method enumeration: the summary
emits an indented tree with counts, not flat `method.Str.*` ids, so grepping
for Str methods returned nothing. Discovering the Str surface required exact
`method:Str.parse_int` queries. The handbook's `not`-based examples do not
hold in this build; boolean negation is spelled `!` and `not` is a parse
error (`err[parse.expected-expression]`).
