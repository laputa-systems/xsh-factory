# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

- There is no explicit `Error(...)` constructor in this build, so deliberate
  validation rejection must be forced through a typed conversion (e.g.
  `"...".parse_int()?`). A generalized "fail with message" primitive for
  semantic validation (as opposed to host/I/O failures) would make validation
  paths clearer and less hacky.

## xsht friction

- `fold` is unusable for error propagation through control flow: putting `?`
  inside an `if`/`else` branch within a `fold` stage block fails `xsht check`
  with `indexed IR could not encode 'full_ir_function_blocker'`. The same `?`
  inside an `each` stage block (including inside `if` branches) type-checks and
  runs fine. Worked around by using `each` with a captured `var` map rather
  than a fold accumulator.
- `Str.parse_int` accepts leading `+` (and surrounding whitespace), which does
  not match this task's `-?[0-9]+` value grammar. Validation therefore required
  an explicit `regex.compile("^-?[0-9]+$")` check in addition to `parse_int`;
  the task's "deliberate failure via a typed conversion" guidance alone would
  have wrongly accepted `+3`.
