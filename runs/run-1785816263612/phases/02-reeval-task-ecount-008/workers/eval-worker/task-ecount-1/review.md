# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

Str has no padded/right-aligned numeric formatting or repeat/pad helpers needed
to reproduce `uniq -c`'s fixed-width count field (e.g. `printf("%7d %s")`).
There is no `Str.repeat`, `Str.pad_left`, or `Int.format`; the only width pad is
`tui.left_pad`/`right_pad`, which is terminal-width based and unsuitable for
byte-exact output. The workaround (interpolate with `f"${count}"`, then slice a
constant run of spaces via `byte_slice`) is opaque. A language-level
`Int.format(width)` or `Str.pad_left(len, char)` would make fixed-width numeric
output direct.

## xsht friction

A stream transform block whose final statement is an `if/else` does not count as
the block's tail value, so `map` reported "map requires a tail value" even when
the `if/else` clearly produces a value; the block only type-checked after
binding the result to a `let` and ending with a bare expression. This is
documented nowhere in the handbook's multi-statement block examples.

A named record literal uses `:` (not `=`, as the handbook's field-access
examples might suggest) and, when nested directly inside a `map { |x| ... }`
block, is only parsed reliably when wrapped in parentheses (`({ext: ..., ...})`);
an unwrapped `{ext: ...}` was mis-parsed as a nested block and produced confusing
`expected }` errors.
