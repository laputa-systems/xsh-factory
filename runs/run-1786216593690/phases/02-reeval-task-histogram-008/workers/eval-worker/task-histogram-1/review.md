# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

- The stream predicate stage is spelled `where`, and the handbook's
  fs.files example (`|> where .kind == "file"`) is the only correct spelling.
  The near-synonym `filter` (widely used in other languages) parses as an
  unknown ordinary call, and the diagnostic surface is misleading: errors name
  the block parameter bars as an "unsupported operator '|'" instead of saying
  "unknown stream stage `filter`". A proposal: give the filter/predicate stage
  `filter` as an accepted alias of `where`, or make unknown-stage errors point
  at the stage name.

## xsht friction

- `fold`/`reduce` blocks must be pure; `print` inside the accumulator block is
  a hard check error telling you to emit in a separate `each` stage. This is
  reasonable but undocumented in the handbook, so the natural approach of
  printing cumulative totals inside a fold fails check. It took an extra pass
  (fold to build lines, then `each { |line| print $line }`) to satisfy it. A
  handbook/tool note calling out "fold blocks are pure — emit with each" would
  save a cycle.
- The task dev loop references `xsht api search:parse_uint`, but that term is
  not present in this pinned image (`parse_uint` is missing). The only strict
  decimal parser is `parse_int_decimal`, which additionally rejects leading
  zeros. This makes leading-zero decimal inputs ("007") an error even though
  the task only rules out signs; a documented strict-decimal parse that accepts
  leading zeros (while still rejecting signs) would match the "non-negative
  decimal integer, no sign" wording more directly.
