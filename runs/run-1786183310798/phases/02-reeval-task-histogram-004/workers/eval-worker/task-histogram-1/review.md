## XSH language proposals

None.

## xsht friction

- Integer division is `/` and the handbook's "// is not a comment" note is easy
  to hit literally: writing `a // b` for truncation raises a confusing
  `expected statement terminator` parse error rather than a hint pointing at
  the division operator. A clearer diagnostic would help new users.
- `fp"...${expr}"` cannot interpolate a `Result`-typed expression such as
  `argv.get(0)` (fails `display-conversion` at check time); the List index
  form `argv[0]` works but must be guarded by an explicit `len()` check first.
- `xsht lint` flags `${entry.items.len()}` inside `print` as a redundant
  command interpolation, even though the plain `$entry.items.len()` spelling
  triggers the same warning. Binding the expression to a local `let count = ...`
  and printing `$count` silences it cleanly.
