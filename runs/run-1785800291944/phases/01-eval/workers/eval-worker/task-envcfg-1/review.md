# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

There is no generic way to raise a deliberate nonzero exit for a validation
failure; the only supported idiom is to propagate a typed conversion error
(handbook confirms there is no `Error(...)` constructor). For a strict
"decimal digits only, non-empty" port check, the standard `parse_int`/`env.int`
helpers are not strict validators (they accept `+5`, `-1`, ` 5`, `0x10`), so
the script must do an explicit `delete("0123456789")` check and then trigger a
contrived failure via a hard-coded bad literal like `"abcdef".parse_int()?`.
A language-level "fail"/validation-error primitive would make this clearer.
