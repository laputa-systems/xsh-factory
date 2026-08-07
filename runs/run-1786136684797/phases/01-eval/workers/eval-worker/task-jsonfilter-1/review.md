# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

A record cast in expression position (`return {name: n}: Item`) is invalid — `xsht check` reports "expected statement terminator". The type annotation only works on a binding (`let item: Item = {...}`). This is easy to trip on when building a typed record as a final expression, and it conflicts with `lint.redundant-tail-return-binding`, which then asks you to eliminate exactly that binding. Worked around by annotating each JSON field (e.g. `let name: Str = json.get(...)?`) and returning a plain structural record.
