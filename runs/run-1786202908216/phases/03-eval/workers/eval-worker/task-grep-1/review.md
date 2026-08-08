# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

Naming a local binding `path` shadows the standard `path` module and makes the `check` stage report a confusing `unknown-module-api` on `path.read_text()` (only a secondary `standard-module-shadow` warning hints at the real cause). Renaming the binding to `file` resolved it. A pointer in that error message would save debugging time.
