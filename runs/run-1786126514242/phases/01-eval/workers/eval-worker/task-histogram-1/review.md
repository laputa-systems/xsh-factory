## XSH language proposals

The rolling handbook should document a few behaviors that cost trial-and-error
discovery:

- `//` is not integer division; it is a parse error (and not a comment either,
  despite the task prose describing `v // WIDTH`). In this image `/` performs
  integer division on Int operands (`17 / 5 == 3`) and `%` is modulo. The
  handbook only mentions `#` comments and never states the integer-division
  operator.
- Record literals (`{name: "demo", enabled: true}`) only parse when the record
  type is declared (a bare `let rec = {run: 0, ...}` fails to parse), and some
  field names are reserved keywords: `run` and `lines` fail with "expected
  record field" while `total`/`out`/`k`/`n` work. This ambiguity also means a
  fold/accumulator must be built through a declared `type` whose name is then
  referenced (e.g. by annotating an `init0` binding) to satisfy `xsht lint`
  `unused-type`.
- Display-string interpolation is `${expr}`, not `{expr}`. Writing
  `f"{item.k} {t}"` printed the brace text literally; `f"${item.k} ..."`
  interpolates expressions as well as identifiers.
- `Str.parse_int()` trims surrounding whitespace and accepts an optional sign
  (`"+10"`, `"-5"`, `" 5"`), so strict digit-only validation of values and the
  width must be done separately (via a `^[0-9]+$` `Regex` check) rather than
  relying on `parse_int` alone.

## xsht friction

- `xsht lint` rejects a record type declared solely so that a record literal
  can parse, reporting `unused-type` until the type name is explicitly
  referenced. There is no way to annotate the literal inline at a call site
  (`fold(({...}: Acc))` fails to parse), so a helper binding annotated with the
  type is needed; this is non-obvious.
- There is no `unwrap_or` / is-ok-style helper on `Result` in this image
  (only `Result.context`), and the handbook's match syntax example did not
  parse in this build; recovering from `Result` values had to be done by
  re-invoking the parse and propagating `?` in both branches.
