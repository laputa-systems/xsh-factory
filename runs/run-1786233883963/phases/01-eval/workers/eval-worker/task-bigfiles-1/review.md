## XSH language proposals

None.

## xsht friction

The `xsht api` documentation was sufficient to discover `fs.files`, stream
stages (`sort-by --desc`, `take`), and `Str.parse_int_decimal` for strict
decimal validation. The `error` effect is required when using postfix `?` on
`fs.files(...)` and on `parse_int_decimal()`, which the docs made clear after
an initial violation. `fp"${...}"` is the lint-preferred dynamic path
constructor over `Path(...)`.
