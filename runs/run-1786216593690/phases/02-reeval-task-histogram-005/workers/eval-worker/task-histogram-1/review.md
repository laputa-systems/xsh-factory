# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

Naming a local binding `path` shadowed the standard module `path` and made `xsht check` fail with `err[check.standard-module-shadow]`. Renaming the variable (e.g. `file_path`) resolved it; worth remembering that common names colliding with standard modules are hard check errors.
