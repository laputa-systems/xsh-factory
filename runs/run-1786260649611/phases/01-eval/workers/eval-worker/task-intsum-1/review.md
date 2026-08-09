# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

Providers expose no strict signed-decimal parser. `Str.parse_int` accepts a leading `+` (e.g. `+7` -> 7), while `Str.parse_int_decimal` rejects any sign and leading zeros. For a strict "optional `-`" input contract I had to hand-validate by stripping a leading `-` and requiring the rest to be nonempty all-digit via `delete("0123456789") == ""`. A strict signed decimal parser (like `parse_int` but rejecting `+`) would remove that hand-rolled syntax check.

## xsht friction

None.
