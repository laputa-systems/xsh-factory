# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

Naming a local binding after a standard module (e.g. `let path = ...`) is
reported through three separate `unknown module API` diagnostics pointing at
the method calls (`path.dirname()` etc.) rather than a clear "name shadows
module `path`" error, which makes the actual cause hard to spot. A distinct
shadowing diagnostic would help.
