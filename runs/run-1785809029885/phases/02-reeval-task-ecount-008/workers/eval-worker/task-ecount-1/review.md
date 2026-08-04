# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

- `if`/`else` acts as a statement, not an expression: inside a
  `reduce(map.empty()) { |acc, e| ... }` block, `if cond { acc.set(...) } else { acc }`
  type-checked as producing `Unit` for the block, so conditional map
  accumulation was impossible inline. I worked around it with a `where`
  extension filter plus `group-by`. Treating `if`/`else` as an expression
  (each branch producing the block's value) would allow conditional fold
  accumulation directly.
- There is no printf-style fixed-width formatter exposed for scalars. To
  reproduce `uniq -c`'s right-aligned `%7d` count field I had to hand-pad by
  slicing a literal 7-space string with `byte_slice`. A `format`/pad primitive
  (or `%Nd` support) would make byte-exact column output less error-prone.

## xsht friction

None.
