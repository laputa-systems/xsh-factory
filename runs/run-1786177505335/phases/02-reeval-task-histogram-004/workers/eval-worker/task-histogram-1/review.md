# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

The task's own example (`v // WIDTH`) is not valid XSH: `//` is rejected at parse time ("expected statement terminator") and list/record comments use `#`, not `//`. Integer division is spelled `/` on Int (17 / 5 == 3), which the task description's hint obscures.

List concatenation uses `.extend(other)`, not `+`; the `+` operator applies only to numbers and strings, and `xsht check` reports this with a `note` pointing to `.extend`.
