## XSH language proposals

- There is no printf/format primitive for right-aligned numeric fields.
  Reproducing the oracle's `uniq -c` output (a 7-character right-aligned count
  followed by one space) required manual padding: building a run of spaces and
  taking a `byte_slice` of `7 - len(decimal)`. A `%7d`-style format helper or a
  string repetition operator would make such exact-width output idiomatic.
- `fs.files(root)?.collect()` raised a runtime "lowered `?` expected Result"
  type error, while binding the stream to a local first
  (`let s = fs.files(root)?; let l = s.collect()`) worked. The postfix `?`
  combined with a trailing method call on the same expression is confusing and
  produced a non-obvious failure mode.
- `argv.get(i)` and `List.get(i)` both return `Result`, so indexing requires an
  explicit `?` even though the handbook presents them as straightforward
  getters/fallbacks. This trips first-time code.

## xsht friction

None.
