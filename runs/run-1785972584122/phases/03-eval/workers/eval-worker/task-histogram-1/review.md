# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

- There is no `filter` stream stage; `xsht api language:stream.filter` reports
  `missing` and using it causes a confusing record-literal parse error. The
  working stage is `where` (found via `xsht api language:stream.where`), which
  accepts both block and implicit forms. Unclear whether the missing alias is
  a gap or intentional.
- There is no generic `Error(...)` constructor, so a deliberate validation
  rejection cannot be expressed directly. The working pattern is to force a
  typed conversion error (`"".parse_int()`) to produce the nonzero exit, which
  is non-obvious and easy to get wrong.
- `Str.parse_int` (and integer parsing generally) accepts surrounding
  whitespace, a leading `+`, and negative values, so enforcing a strict
  "non-negative decimal, no sign" contract requires an extra
  `regex.compile(r"^[0-9]+$")` whole-string check before parsing; the typed
  parse alone is not sufficient validation.
