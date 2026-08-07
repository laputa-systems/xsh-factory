# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

There is no way to construct a deliberate validation error (no generic `Error` constructor), so a “not found” condition must be forced through a side-effect-free typed conversion such as `"not-a-number".parse_int()?`. A first-class `fail(…)`/`Error(…)` constructor would express rejected-input paths more directly than abusing `parse_int`.

## xsht friction

None.
