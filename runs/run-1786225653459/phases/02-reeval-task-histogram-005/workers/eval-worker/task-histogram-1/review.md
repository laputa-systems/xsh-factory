# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

- Binding names collide with builtins/reserved words in ways that only surface
  at parse/check time and are easy to trip over: `let stream = ...` fails with
  `expected binding name` (stream is reserved), and `let path = ...` is
  rejected as shadowing the standard `path` module. No lint hint suggests an
  alternative name.
- Dividing with `//` (the task's own phrasing) parses as a line comment and
  emits `expected statement terminator`; integer division is `/`. The handbook
  warns about this, but it is easy to misread the confusing diagnostic.
- The `text.lines(text)` stream adapter rejected a single argument as
  "incorrect standard API arity" even though its signature declares
  `text.lines(text: Str)`; the reliable path was the `Path.lines()` method,
  whose signature is clearer.
