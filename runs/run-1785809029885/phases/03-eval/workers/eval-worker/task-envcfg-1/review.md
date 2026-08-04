# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

- There is no clean, first-class way to emit a deliberate validation failure
  after an explicit byte-level check. The endorsed mechanism (propagate a
  typed-conversion error with `?`) is indirect: to exit nonzero on a bad
  `CFG_PORT` I had to parse a string that is *guaranteed* to fail
  (`nondigits.parse_int()?` for the non-digit residue, and `"".parse_int()?`
  for the empty case). This is fragile because `Str.parse_int` trims
  whitespace and accepts signs (`-5`, `+5`, ` 12`, `12 `, `00` all parse
  fine), so it cannot be fed the raw value to reject those. A small
  `assert(cond, msg)` / explicit `raise`/`fail` primitive that produces a
  clean nonzero exit (and no file side effect) without a runtime traceback
  would make strict validation simpler and less surprising.
- `Err("msg")` exists but yields `Result[_, Str]`, which cannot be propagated
  from `proc main() [error]` (its error family is `Error`): the checker emits
  `incompatible propagated error ... cannot propagate Str from function
  returning Error`. Combined with the handbook's "no generic Error(...)
  constructor" guidance, this leaves no ergonomic path to a semantic
  validation error versus an unrelated host/traceback failure.
