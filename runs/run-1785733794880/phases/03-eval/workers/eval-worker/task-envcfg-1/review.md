# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

There is no explicit, user-facing way to raise a native failure from a
condition. `Err("...")` produces a `Result[<unknown>, Str]` whose error type
is `Str`, and propagating it through the `[error]` effect is rejected with
"cannot propagate Str from function returning Error" (the proc's error family
is the native `Error` type). Searches for `fail`, `assert`, `raise`, `panic`,
and `abort` in `xsht api` return no constructors. The only route to a native
`Error` is through a host/native API that returns one, which forced a
workaround (e.g. compiling an intentionally invalid regex,
`regex.compile("(")?`) to make an invalid `CFG_PORT` fail with a nonzero exit
and no file. A dedicated `fail`/`assert` primitive that produces a native
`Error` would make such validation idiomatic.

## xsht friction

`xsht api` accepts only exact `KIND:NAME.MEMBER` lookups (e.g.
`method:Str.lower`); there is no way to list every method of a receiver
(`method:Str.` and `method:Str` are both rejected). Browsing a type's full
surface required dumping `xsht api summary` and grepping the text output,
which is slow and easy to miss details on. An index query per type (e.g.
`method:Str`) would be easier than the whole `summary`.
