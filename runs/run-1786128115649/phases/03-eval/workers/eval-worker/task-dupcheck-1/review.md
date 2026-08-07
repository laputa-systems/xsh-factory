# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

Module signatures display optional/default parameters (e.g. `fs.files(path, hidden: Bool = default)`) which strongly implies named-argument calls, but `name = value` in a call position fails to parse (`expected ')' after call arguments`), even on its own without a postfix `?`. Real calls must pass all optional parameters positionally (verified: `fs.files(root, false, false, [], true)` works). Either document positional-only calling or accept named args so the displayed signature is honest.
