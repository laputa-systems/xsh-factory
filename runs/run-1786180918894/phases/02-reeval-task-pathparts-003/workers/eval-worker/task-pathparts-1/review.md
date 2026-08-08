# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

`xsht check` rejects a local `let path = ...` as `check.standard-module-shadow`, but several handbook examples (e.g. `let extension = path.ext()`) use `path` as an ordinary variable name. The linter's exact match on the module name `path` (case- and name-collision) is not signposted in the handbook, so the first attempt fails; a rename to `p` resolves it. Worth a one-line note in the handbook that `path` is a reserved module name.
