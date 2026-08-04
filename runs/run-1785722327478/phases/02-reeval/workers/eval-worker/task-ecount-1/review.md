# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

- `fold`/`reduce` have no documented signature or example, and the single
  block parameter is ambiguously typed: with an Int initial and Int items the
  block parameter behaved like a running accumulator (`[10,20,30] |> fold(7)
  { |x| x + 1 }` -> 10), but with an Int initial and Str items it typed as the
  item (`words |> fold(0) { |p| p }` -> "expected Int, found Str"). A fold that
  cannot reliably expose both accumulator and item is hard to use; a clear
  two-argument reduce contract (e.g. `{acc, item}` tuple) would help.
- There is no direct `Str -> Path` constructor. Path literals `p"${...}"` do
  not interpolate, so one must go through `bytes.from_text(...)` +
  `Path.parse_bytes(...)`, which is awkward for taking a root path from argv.
- String padding lives in the `tui` module (`tui.left_pad`). Using a
  terminal-only module just to reproduce `uniq -c`'s `%7d` count padding
  feels wrong; a core scalar-to-fixed-width formatter would be cleaner.

## xsht friction

- `xsht api language:stream.fold` / `language:stream.reduce` return only a
  purpose/contract with no signature or example, so the exact call shape had
  to be reverse-engineered through trial and error.
- `group-by` yields per-key records whose shape is undocumented (the record
  keys are `["items"]`, the group key is not directly exposed), and
  `Record.get` only accepts one argument (returning `Result`), so using
  grouped values is non-obvious.
- `print` command arguments cannot contain call expressions (e.g.
  `print $k (g.get(k)).len()` is rejected), requiring every computed value to
  be bound to a `let` first; this parse-only restriction is not mentioned in
  the `language:core.print` contract.
- `let mut` is not valid syntax (immutable `let` emits `assign-let`); a
  mutable binding requires `var`, which is undocumented in the bindings
  reference.
