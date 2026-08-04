## XSH language proposals

None.

## xsht friction

- `Str` has no `len()`; the checker rejects it and points to `byte_len()`/`count_bytes()`/`count_chars()`. Using `count_chars()` on a Str while `List.len()` is the collection method works, but the parallel naming is easy to trip on.
- There is no generic `Error(...)` constructor, and the typed `env.int`/`env.bool` helpers are not strict format validators. Producing a deliberate nonzero exit for a rejected value required triggering a failing typed conversion (`"".parse_int()?`) rather than an explicit validation error, which also emits a runtime traceback on stderr.
- `Path(argv.get(0)?)` is accepted by `check` but flagged by `lint` in favor of `fp"${...}"`; the lint-preferred interpolated form is the reliable path string idiom for a runtime argument.
