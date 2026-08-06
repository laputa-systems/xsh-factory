# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

- A `map` (and similar stage) block whose sole statement is an `if/else`
  expression is rejected with `map requires a tail value`; the block must bind
  the result (`let r = if ... { } else { }`) and then end with a bare tail
  expression. This is surprising since an `if/else` is otherwise a value.
- Integer division uses `/` (truncating), not `//`; `v // width` is a parse
  error under `group-by`. The `//` binary operator is not documented as an
  operator in the language.
- Boolean operators are the word forms `and`/`or`; `&&` is a parse error.
- List concatenation is `.extend(other)`, not `+`.
- There is no generic `Error(...)` constructor, so validation failure must be
  forced through a typed conversion. Using `"invalid".parse_int()?` to reject
  bad input (e.g. `-3`, `+5`, `0x10`) prints a runtime traceback to stderr
  rather than failing cleanly and silently.
