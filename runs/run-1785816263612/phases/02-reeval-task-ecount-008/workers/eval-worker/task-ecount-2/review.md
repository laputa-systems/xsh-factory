# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

- A string repeat / width-padding facility (or printf-style width in `f"..."`
  interpolation) would avoid the ad hoc `[0..6] |> map |> collect |> join`
  dance needed to right-align `uniq -c`-style counts to a fixed width.
- An `if` expression should be usable directly as a function/stream block tail
  (see friction below).

## xsht friction

- An `if ... else ...` expression cannot be the tail of a `map` block directly;
  `xsht check` reports `map requires a tail value`. The workaround is to bind
  the `if` result to a `let` and tail with that variable.
- `join` is not a stream stage: `stream |> join(sep)` fails with
  `pipeline sugar was not desugared`. You must pipe through `|> collect()` and
  then call `.join(sep)` on the resulting List.
- `List.get(index)` (single-argument) returns `Result[T, Error]`, so calling a
  method on the result (e.g. `.lower()`) is rejected as unknown. Use the
  two-argument `List.get(index, fallback)` overload to obtain a plain value.
