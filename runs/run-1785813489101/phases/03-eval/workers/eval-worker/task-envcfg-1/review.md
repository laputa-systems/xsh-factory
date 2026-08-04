## XSH language proposals

None.

## xsht friction

- The standard `path` module name shadows ordinary identifiers: naming a
  local binding `path` failed `xsht check` with `check.standard-module-shadow`.
  Renaming the binding to `out` resolved it. A clearer error/avoidance hint
  would reduce iteration time.
- Deliberate validation failure has no generic `Error(...)` constructor and
  there is no Result success/`is_ok` introspection in the pinned API
  (only `Result.context`). Forcing a nonzero exit required triggering a
  guaranteed-failing typed conversion (e.g. a literal `"invalid".parse_int()?`)
  inside the invalid branch. A more direct way to raise an expected error
  would be simpler.
- `Str.parse_int()` is not a strict decimal validator: it accepts `-5`, `+3`,
  and leading zeros (`08`), and normalizes `08` to `8`. It therefore cannot be
  used both to validate the byte-exact port string and to preserve its raw
  form; validation had to be done with `count_chars`/`delete` and the raw
  string output separately.
