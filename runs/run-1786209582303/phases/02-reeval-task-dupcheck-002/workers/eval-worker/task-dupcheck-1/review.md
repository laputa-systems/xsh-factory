# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

Using `group` as a loop variable (e.g. `for group in groups`) fails
`xsht check` with `name shadows the standard module 'group'`. It is a natural
identifier when iterating `group-by` results, so the shadowing rule is easy to
trip; the diagnostic is clear, but a broader set of reserved/std names (or a
lint suggestion) would help.
