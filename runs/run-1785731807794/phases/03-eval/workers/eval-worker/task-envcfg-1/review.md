# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

Constructing a deliberate failure is awkward: `Error(...)` was removed at
type-check time (the error suggests constructing declared variants such as
`FsError.NotFound`), and there is no dedicated `fail`/`abort` primitive that
returns a `Result[_, Error]`. To make the program exit nonzero on an invalid
`CFG_PORT` without a domain-specific variant, I had to signal the error via `?`
on a deliberately failing `"".parse_int()?`. A library-side `fail(msg)`/
`abort(msg)` returning an `Err` would make validation branches more
intentional.

## xsht friction

Boolean operators are the word forms `or`/`and`, not the C-style `||`/`&&`.
Writing `if a == "" || b != ""` failed at parse time with a misleading
`expected '{' to start block`, which pointed at the `{` rather than the
operator; the correct spelling was only found by probing alternatives. `if`
also takes `COND { ... }` with no `then`. The parse diagnostics could
reference the unsupported operator directly.
