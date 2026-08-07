## XSH language proposals

- Inside a `fold` block, the `+` binary operator is type-checked as integer
  addition only: `fold("z") { |acc, s| s + "/" + acc }` fails with "expected
  Int, found Str", while the identical expression at top level or inside a
  plain `if` block checks cleanly. This forced string assembly with
  `List.join`/`[seg].extend(...)` rather than `+` within the fold.
- A nested stream (e.g. `parts |> take(n) |> collect()`) inside a `fold` block
  triggers `compact.indexed-build ... could not encode full_ir_function_blocker`
  at check time. Popping a list's last element therefore had to be restructured;
  the reverse-scan-with-pending-count approach avoids in-block streams entirely.
- `List` has no `pop`/`slice`/reverse methods (only contains, extend, get, join,
  len, push), so "remove last" requires a stream idiom that is unavailable
  inside a fold block.

## xsht friction

- None.
