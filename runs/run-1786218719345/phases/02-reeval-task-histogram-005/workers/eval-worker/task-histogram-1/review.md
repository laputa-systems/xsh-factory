# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

- Integer division is written `/` (with `/` doing truncating division and `%`
  as modulo), not `//`. The handbook only documents that `//` is not a comment
  and causes a parse error, and the task spec itself wrote `v // WIDTH`, so
  the first attempt with `//` failed with `parse.expected-terminator`. The
  handbook does not state the actual division operator, which cost discovery
  time.
- There is no generic `Error(...)` constructor, so a syntactically valid but
  non-positive width (e.g. `0`, which `parse_uint` accepts) cannot be rejected
  via typed-conversion failure; it required the `abort(1)` language builtin
  instead.
