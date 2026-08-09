# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

- `Str.parse_int_decimal` rejects negative integers and leading zeros (its contract admits only nonempty digits and `0`), which is easy to misread for a general decimal parser. A task requiring signed decimal values needs `Str.parse_int`, which accepts `-5`, `+3`, and `007`. Worth surfacing in the API contract/docs given how similar the two names are.

## xsht friction

None.
