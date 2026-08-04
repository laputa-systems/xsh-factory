# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

- `fs.files(path)?` immediately followed only by `|> collect()` fails
  compilation with an internal error `compact.indexed-build: indexed IR
  could not encode 'full_ir_function_blocker'`. Adding any transformation
  stage (`where`/`map`) before `collect()` makes it compile. A misleading
  internal IR error instead of a useful message.
- `fold`/`reduce` are documented as "explicit accumulator block" reductions,
  but the parser rejects two-parameter blocks (`{ |acc, x| ... }`) with
  "stream stage blocks accept at most one parameter", and no valid
  accumulator form is documented. Counting/folding therefore requires
  workarounds (here `group-by`).
- `Str` has no `.len()` receiver; the length methods are `byte_len()`,
  `count_bytes()`, `count_chars()`. `xsht api`'s get-started summary lists
  `List.len()` but a Str-length query is easy to guess wrongly.
- Empty collection literals are unsupported: `{:}` is parsed as a record and
  rejected; an empty map must be created via `map.empty()`.
