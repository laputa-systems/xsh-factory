# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

- There is no generic `Error(...)` constructor and `Err("msg")` yields `Result[<unknown>, Str]` (type mismatch against `Result[Int, Error]`). Deliberate validation failure in a rules-based checker had to be forced through an unrelated typed conversion (e.g. `"x".parse_int()?`), which is indirect and gives a misleading runtime message. A first-class construct for asserting/raising would be cleaner.
- Maps need a `map.empty()` module helper; there is no Map literal, and `{"a": 1}` parses as a Record (no `set`).
- No `for` loop exists; iteration over collections must go through stream stages (`each`) that reassign an outer `var`, which works but is verbose.

## xsht friction

- The API query form is `method:Path.display`; `api:method:Path.display` is rejected as invalid, which is easy to miss when the getting-started text says `api:api:fs.read_text` uses the `api:` prefix but methods do not.
- A block-lambda literal assigned via `let f = { |s| ... }` parses as a record and fails; reusable logic must be hoisted into `pure`/`proc` functions, discovered only by trial and error.
- Boolean operators must be the word forms `and`/`or`; `&&`/`||` produce a parse error, but the message mentions `|` ambiguity before `||`, so the real fix ("use 'or'") is not obvious from the first lines of output.
