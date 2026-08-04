# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

- Stream stage blocks accept at most one parameter, and `fold`/`reduce`'s
  accumulator-plus-item binding is undocumented and effectively unusable here:
  `fold(init) { |acc, it| ... }` fails with `check.stream-block-params` (at most
  one parameter), `fold { |a, b| ... }` fails with `check.arity` (expects an
  initial value), and a close variant crashed the compiler with
  `compact.indexed-build`/`full_ir_function_blocker` (an internal IR error
  with no source mapping). A documented example and a first-class
  accumulator+item block (or a `group-by`/`count-by` that returns a Map) would
  remove the need to assemble counting from `group-by` records.

## xsht friction

- `xsht api` for the stream stages used here (`group-by`, `count`, `sort`,
  `sort-by`, `fold`) returns only a summary/contract and, except `where`,
  carries `"example": null` and no signature, so block arity, argument order,
  and result shape had to be discovered by trial. `group-by`'s result is a
  record with `items`/`key` fields that is not documented anywhere in the API.
- Method naming is inconsistent: `List.len()` and `Map.len()` exist, but
  `Str.len()` is rejected as an unknown method (only `byte_len()`/`count_chars()`
  work). Likewise `List.get(i)` returns a `Result` (needs unwrap and fails
  inside `map`), while subscript `list[i]` returns the value directly; this
  difference is undocumented and cost several failed probes.
- Introspection friction: a `Record`/`List` value cannot be printed directly
  (`cannot display Record`/`cannot display List`); one must call `Record.keys()`
  and format each field, which is how `group-by`'s `items`/`key` shape was found.
