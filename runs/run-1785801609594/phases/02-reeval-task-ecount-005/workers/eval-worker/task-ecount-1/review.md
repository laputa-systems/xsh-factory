## XSH language proposals

None.

## xsht friction

- `tui.left_pad(text, width)` (padding a string with spaces to a target display
  width) is the only convenient way to reproduce `uniq -c`'s `%7d` right-aligned
  count padding without manual string-building; it is grouped under the TUI
  terminal-control module even though it returns plain text with `effects:
  none`, so it is easy to overlook when scanning for formatting helpers.
- There is no direct Int->decimal-Str conversion method on `Int` (the type only
  exposes `float`); converting a count to text requires a display string
  `f"${count}"`. A dedicated `Str(Int)`/`to_str` that matched `parse_int`'s
  reverse direction would remove the surprise.
