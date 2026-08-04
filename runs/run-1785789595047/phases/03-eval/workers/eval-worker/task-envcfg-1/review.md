## XSH language proposals

- Handbooks/`xsht api` do not document the boolean AND operator. `&&` (and `&`,
  `||`) are parse errors; the logical AND is spelled `and`. This is easy to
  trip on for shell/Python-style authors and is the kind of byte-level fact
  worth an index entry.
- `Str` exposes no `len()`; only `byte_len()`, `count_chars()`, and
  `count_bytes()` (List uses `len()`). The check error gives a helpful hint,
  but the asymmetry invites mistakes on mixed Str/List `len()` calls.
- `proc main` must use the spread parameter form `(...argv: List[Str])`.
  Declaring `main(argv: List[Str])` passes `xsht check` but fails at runtime
  with `runtime.compact-unsupported-main`, which is a non-obvious link
  between the entry signature and the chosen runtime.

## xsht friction

- `Str.parse_int()` is a loose parser (accepts `+5`, `-5`, leading whitespace)
  rather than a strict decimal validator. For byte-exact validation I had to
  build an explicit `delete("0123456789")` digit check and force a deliberate
  failure (`"x".parse_int()?`) to signal a nonzero exit, since there is no
  generic `Error(...)` constructor. The handbook warns that `env.int` is not a
  strict validator, but `parse_int` being equally lenient is worth calling out.
- A propagated error exits with code 3 (not 1) and prints a traceback to
  stderr. That is still "nonzero" and keeps stdout clean, but callers
  expecting an exact exit code (the oracle uses 1) must only assert nonzero.
