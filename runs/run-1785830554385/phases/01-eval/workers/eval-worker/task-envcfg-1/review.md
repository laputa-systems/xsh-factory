## XSH language proposals

- `fail(message)` is documented in `xsht api language:core.fail` with a
  signature and `validation` semantics, but `xsht check` rejects it as an
  "unresolved pure function call" in this pinned build. Either implement the
  documented constructor or mark it unavailable so validation failures do not
  have to be smuggled through a typed conversion such as `port.parse_int()?`.

## xsht friction

- `xsht fmt` rewrote a single-line display string into a triple-quoted
  multi-line literal; harmless but surprising when the composer intended
  `\n` joins. `xsht check`/`lint` accepted both forms.