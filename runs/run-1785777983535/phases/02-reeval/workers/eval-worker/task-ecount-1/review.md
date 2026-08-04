# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

- A lambda block passed as a trailing positional argument (e.g.
  `list.fold(initial, { |acc, e| ... })` and `list.each { |line| ... }`) is
  parsed as a record literal or rejected as a command argument, so compute
  helpers (folding into a Map, side-effecting iteration) cannot be expressed
  with the ordinary block syntax. This forces re-deriving the same logic via
  stream stages (group-by, join) instead.
- There is no ergonomic empty-map literal: `{}` denotes a record, and the
  only constructor is `map.empty()`. Likewise there is no runtime Path
  constructor from Str; one must round-trip through
  `Path.parse_bytes(bytes.from_text(...))`. A dedicated Str/Path constructor
  would simplify arg-driven programs.
- `print` of a `group-by` record fails with "cannot display Record" and gives
  no field preview; a display form for structured records would aid
  development.

## xsht friction

- `exts.fold(map.empty(), { |acc, e| ... })` fails to parse (`expected record
  field`); worked around with `group-by { |e| e }` + `.items.len()`.
- `list.each { |l| print $l }` runs and prints every line correctly, then
  aborts with `runtime.error: lowered return type mismatch`; worked around by
  joining lines and printing once. The `each` block's expected return shape
  is undocumented and surprising.
- `group-by` groups are opaque records; discovering their shape required
  probing `g.keys()` → `items,key` and `g.items.len()`, since the contract
  does not state the group record's fields.
- Declaring a pure helper as `proc f(...) -> T` with no effect block makes it
  "unrestricted" and uncallable from an effect-declared proc, and `[none]` is
  not a valid effect; the fix is the undocumented-in-handbook `pure` keyword
  (`language.core.pure-functions`).
