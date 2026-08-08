# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

- `fs.files`/`fs.walk` accept positional args only (named args unsupported), and `stat` defaults to true while `hidden` defaults to false. To enable hidden files you must pass all preceding positional values; passing `stat=false` silently yields all-zero sizes with no diagnostic, which is easy to trip.
- Boolean operators are only the word form (`or`), not `||`; the parser reports a generic `expected-token` cascade rather than clearly pointing at the operator.
- Int has no `.str()` conversion; presenting an Int requires a display string (`f"${v}"`), which is discoverable but not obvious.
- Match arm patterns require parenthesized `Ok(v)` / `Err(_)`; bare `Ok v` is a parse error.

## xsht friction

- `xsht api` contracts are terse (`accepted radix and syntax are explicit`) and don't state that `Str.parse_int` also accepts `+5`, surrounding whitespace, and `-3`, forcing manual digit-only validation for a "decimal integer" contract. The `delete("0123456789")` idiom works but is undocumented as a validation trick.
- `print` rejects bare field access (`e.name`) and requires `$e.name`, and interpolation of an array index (`$a[0]`) is rejected as "cannot convert to one command word" — both surfaced only via check errors.
- Sizes are only populated when `stat` is true (which is the default), but a stray explicit `stat=false` produces all-zero sizes silently; no check catches this.
