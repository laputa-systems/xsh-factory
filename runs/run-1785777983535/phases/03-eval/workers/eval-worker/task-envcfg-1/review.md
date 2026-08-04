## XSH language proposals

None.

## xsht friction

There is no clean, lint-clean way to make a program exit nonzero on an
invalid-input condition. The generic `Error(kind: ...)` constructor is
removed, and no constructible error variant is exposed to script code, so a
script cannot `return Err(...)` of the built-in `Error` family (returning
`Err` with a Str error type is incompatible with propagating `?` from
`fs`/`env` operations, which use the `Error` family). The only ways found to
abort were a deliberately-failing operation (e.g. `regex.compile("(")?`) —
which triggers `lint.unused-local` because its result is unused — or an
out-of-bounds list index (a runtime crash). A built-in `fail`/`assert`-style
construct or a user-constructible error value would make this far cleaner.
