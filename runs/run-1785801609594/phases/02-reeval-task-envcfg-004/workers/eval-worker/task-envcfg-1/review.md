# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

- Boolean operators are word forms (`or`/`and`), not `||`/`&&`; using `||`
  yields `parse.unsupported-boolean-operator`. Easy to trip over when porting
  familiar syntax; xsht's error message does point at the correct word form.
- `env.int` (and `Str.parse_int`) are not strict decimal validators: they
  accept `+5`, `-5`, and surrounding whitespace, while a task's oracle may
  require a bare run of digits. I had to replicate the check with
  `port.delete("0123456789")` plus an emptiness test and trigger the nonzero
  exit via a forced `parse_int()?`. Worth documenting that the convenience
  readers liberalize sign/space inputs.
- There is no generic error/`exit`/`panic` constructor; deliberately failing
  relies on `?` propagating a typed-conversion error, which exits with code 3
  (not a controllable code) and prints a traceback to stderr. The task only
  required a nonzero exit and no file creation, so this is consistent, but the
  exact exit code is not controllable.
