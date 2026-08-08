# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

The List type exposes only contains/extend/get/join/len/push, with no pop,
drop, slice, or tail operation. A stack-shaped algorithm (e.g. the `..` path
normalizer here) therefore cannot remove an element from a List; the workaround
was to model the stack as a Str and pop via `reverse()` + `find("/")` +
`byte_slice`. A `List.pop`/`List.slice` method (or drop-last) would make such
accumulators far more natural.

## xsht friction

Str concatenation via `+` fails inside a `var` reassignment in a `for` loop
with the opaque runtime error `lowered expression expected Int`, even though
the same `+` expression is accepted in a `let` initializer. Reassigning with a
display string (`stack = f"${stack}${seg}"`) works, so the `+` path is an
inconsistent limitation rather than a missing feature. The compiler gives no
hint that the problem is the `+` on Str in this position.
