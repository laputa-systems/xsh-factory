## XSH language proposals

- There is no generic `Error(...)` constructor, so rejecting a value that a
  typed conversion happens to accept (e.g. `"‑5".parse_int()` succeeds) forces
  an awkward workaround. To match a strict decimal-digit contract I had to
  trigger failure by parsing a derived non-digit string
  (`port.delete("0123456789").parse_int()?`) rather than expressing the
  rejection directly. A first-class `fail`/`assert`-style primitive would make
  explicit byte-exact validation much cleaner.
- The typed conversions `env.int` and `Str.parse_int` are documented as "not
  strict format validators": they accept `-5`, `+5`, etc. For a byte-exact
  decimal contract the caller must re-implement digit checking by hand, which
  is easy to get subtly wrong.
- Boolean operators are the word form `and`/`!` (`&&`/`not` are parse errors)
  and `let` bindings are immutable; both took a short discover-by-error step.

## xsht friction

- A deliberately failing `?` at top level produces a full runtime traceback on
  stderr and an exit code of 3 rather than the oracle's `exit 1`. That is fine
  for a "must exit nonzero" contract, but it means an exact exit-code
  comparison against a shell oracle would not line up.
- `let _bad = ...` triggers `lint.unused-local` while `let _ = ...` does not;
  the underscore naming is the only lint-clean way to hold a deliberately
  discarded value.
