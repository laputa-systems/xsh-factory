# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

Provide a generic way to raise an error (e.g. a `fail`/`Error(...)` constructor) for domain-level validation. In `envcfg.xsh`, rejecting a non-decimal `CFG_PORT` requires a deliberate nonzero exit, but the build has no generic error constructor, so the only documented path is to force an unrelated typed conversion (`"not-a-port".parse_int()?`) to fail. A reusable validation primitive would let programs reject bad input without abusing a correlation-free parse error.

## xsht friction

Boolean/comparison operators are not discoverable through `xsht api search`: `search:equals`, `search:digit`, and `search:raise` all return no matches, and there is no `language:core.==`/`and` index entry surfaced in the summary. I had to learn the `and` word form and `!=`/`==` syntax by trial and error through `xsht check`.

## xsht friction

None.
