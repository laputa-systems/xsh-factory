# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

- There is no `filter` stream stage; the checked/run error `unknown stream
  stage 'filter'; use 'where' for filtering` directs to `where` instead.
- Integer division is spelled `/` (not `//`); `Int / Int` yields the truncated
  quotient (e.g. `5 / 10 == 0`), while `//` is not a valid operator and only
  causes a parse error. Documenting the binary arithmetic operators would
  save discovery time.
- `List.len()` is the length method; there is no `length()`/`size()`/`count()`.

## xsht friction

None.
