## XSH language proposals

- `xsht api language:core.fail` documents a `fail(message) -> Result[Unit, Error]` "deliberate validation failure" constructor, but the installed parser rejects `fail("...")?` with `check.unresolved-call: unresolved pure function call`. The handbook's guidance that the build has no usable error constructor is correct; deliberate rejection must be produced by a typed conversion (here `Str.parse_int()?` on the non-digit residue), which the checker accepts.
- `env.int`/`Str.parse_int` are convenience readers, not byte-exact validators: `env.int("CFG_PORT")` accepts `-5` and `+5` and normalizes `007` to `7`, so a byte-exact decimal/boolean contract (reject any non-digit, preserve original bytes like `007`) must inspect the raw string (via `Str.delete("0123456789")`) rather than rely on the typed readers. `env.get_or` does provide the required absent-vs-empty distinction (`fallback` only on absence), and `env.list()` records (`{name,value}`) give a sentinel-free presence check.

## xsht friction

- `xsht lint` emits `warn[lint.prefer-in]` for `List.contains(...)`, directing use of `in` membership syntax (`"CFG_PORT" in names`); `.contains(...)` passes `xsht check` but fails `xsht lint`.
- XSH boolean operators are the word forms `or`/`and`, not `||`/`&&`; `||` is a parse error (`parse.unsupported-boolean-operator`) in `xsht check`.
