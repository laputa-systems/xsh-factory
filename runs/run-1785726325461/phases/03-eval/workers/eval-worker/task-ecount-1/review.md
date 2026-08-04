# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

- `sort-by` accepts only scalar keys (Int, Str, Bool, Path) and rejects a
  composite/tuple projection (`expected Int, found Str`; `sort-by keys must be
  Int, Str, Bool, or Path`). Sorting by two keys (numeric count then lexical
  extension, as `sort -n` tie behavior requires) forces a hand-built padded
  string sort key. A native multi-key sort (e.g. sort-by accepting a list or
  a comparator) would make this class of task direct.
- `stream.group-by` returns a `List[Record{key, items}]`, not a Map, and the
  API item has empty `signatures` and no example, so real users must infer the
  `{key, items}` shape by trial. Documenting the group record shape would
  remove guesswork.
- There is no documented direct Str -> Path conversion; runtime construction
  requires `bytes.from_text(...)` plus `Path.parse_bytes(...)`. A `Path` from
  `Str` value (e.g. a `to_path()` method) would be more discoverable.

## xsht friction

- `xsht api` is inconsistent when searching the Path constructor: `api:Path.parse_bytes`
  and `method:Path_constructor.parse_bytes` are "missing" while only
  `method:Path.parse_bytes` resolves, and there is no glob for the constructor
  bucket (summary names it "Path constructor"). Building a Path from a runtime
  string was non-obvious.
- `stream.max()` returns a `Result` that `print` cannot display and needs `?`
  (declaring the `error` effect); small scalar-returning terminals such as
  `max`/`min`/`first` being `Result` adds friction for simple programs.
- `Str` has no `len()`; only `byte_len()`/`count_chars()`. The handbook's
  "list length is `List.len()`" note does not extend to Str, and the compiler
  rejects `Str.len()` with a suggestion.
- Counting via `Map` + `fold` is awkward because `map.empty()` is `Map[Any]`
  and `Map.get(key, 0)` returns `Any`, so `acc.get(e, 0) + 1` fails type
  checking; I worked around it with `group-by` + `items.len()`.
