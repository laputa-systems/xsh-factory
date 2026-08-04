## XSH language proposals

Using postfix `?` (error propagation) inside a stream-stage closure (e.g. a
`map { |s| (s.split(".") |> last())? }` block) is rejected not with a clear
diagnostic but with an internal compiler error: `indexed IR could not encode
`full_ir_function_blocker``, reported at the enclosing `proc` declaration.
This makes `?` unusable inside pipeline-stage blocks. A real fix would either
support `?` in those closures or emit a normal type/check error instead of an
internal IR failure. The workaround (read the element via `List.get(index,
fallback)` without `?`) compiled cleanly.

## xsht friction

No other blockers; `check`, `fmt`, and `lint` all passed cleanly once the
code avoided `?` inside closures. Minor: matching `uniq -c` byte-for-byte
requires knowing its fixed count-field width of 7 (right-aligned, single space
then item), which is not documented in the language reference and had to be
derived by experiment.
