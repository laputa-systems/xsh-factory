# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

Binding a value with the name `path` (common for a path variable) shadows the standard `path` module; `xsht check` then reports misleading `unknown module API` errors at every use of the variable. Renaming the binding (e.g. `target`) resolves it, but the module-shadow diagnostic on a local `let` is easy to mistake for a bad method call.
