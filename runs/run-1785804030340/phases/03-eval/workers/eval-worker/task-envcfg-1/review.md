# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

There is no generic error/raise constructor in this build, so a deliberate
input-validation failure must be expressed by forcing a typed conversion to
fail. For CFG_PORT, which must be rejected for inputs the parser otherwise
accepts (`-5`, `+5`, ` 5`), I had to call `("x" + port).parse_int()?` purely
to drive a nonzero exit while keeping the exact source string for output. An
ergonomic way to signal an expected validation error (a `Result`-returning
validator or an explicit raise) would make such rejection intent clearer than
coercing a spurious parse failure.

## xsht friction

Binding a variable named `path` is rejected by `xsht check`/`lint` because it
shadows the standard `path` module (`name `path` shadows the standard module
`path``). The failure is actionable but easy to hit when writing filesystem
code, and the workaround (renaming to `out_path`) is only discoverable from
the error text.
