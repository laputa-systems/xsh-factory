# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

The `abort` builtin is a parenthesized call (`abort(2)`). Writing it with the
command-word spelling `abort 2` (natural when many stream stages take blocks as
command words) fails `xsht check` with a misleading `unresolved proc command`
diagnostic instead of pointing at the call syntax. Useful to know before
reaching for a process-exit validation.
