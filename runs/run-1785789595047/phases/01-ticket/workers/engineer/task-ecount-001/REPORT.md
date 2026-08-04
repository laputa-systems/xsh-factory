# Engineer report

## Result

ready-for-review

## Branch

factory/task-ecount-001/1785789595996

## Commit

c2402341d7f3cf29b504ca8c22b89be2cf7a3eba

## Files changed

- `crates/xsh-registry/src/reference.rs` — populated accurate signature/return-shape strings for every `language:stream.*` stage (including `group-by(block) -> Stream[{key, items: List[T]}]`, `fold/reduce(init, block) -> A`, `each(block) -> Unit`, `collect() -> List[T]`, etc.); corrected the stale `each` contract prose that claimed downstream stages remain available even though each is a Unit terminal.
- `crates/xsht/src/api.rs` — text formatter now renders full details (including `signature:`) for a `module:NAME.MEMBER` query that resolves to a single module-function item, giving parity with `api:NAME.MEMBER` and methods; bare `module:NAME` overviews keep concise Basic output.
- `crates/xsht/tests/api.rs` — added regression tests for stream-stage signatures (text and jsonl), `module:tui.left_pad` text/jsonl signature parity, and module-overview conciseness.

## Tests

- `cargo test -p xsht --test api` → 24 passed (5 new regression tests included).
- `cargo test -p xsh-registry` → 8 passed.
- `cargo test -p xsht` → 22 + 22 + 24 + 96 = 164 passed, 0 failed.
- Manual acceptance probes with the built `xsht`:
  - `xsht api language:stream.group-by` → `signature: group-by(block, --jobs: Int = default) -> Stream[{key, items: List[T]}]`.
  - `xsht api module:tui.left_pad` → `signature: tui.left_pad(text: Str, width: Int) -> Str`.
- Runtime probe confirmed `group-by` yields `{key, items: List}` records and `each` is a Unit terminal (matches the handbook pattern of binding its result).

## North-star impact

`xsht api` is the handbook's named source of truth. Previously every
`language:stream.*` entry had an empty signature list and the text formatter
dropped module-function signatures, so agents composing pipelines had to guess
return shapes (e.g. group-by's `key`/`items` record) by trial and error. Now
the exact core pipeline stages print their block signature and concrete return
shape, and `module:NAME.MEMBER` text output matches its jsonl payload. This
directly reduces the "repeated discoveries" the factory exists to remove: an
agent querying any stream stage sees a truthful signature instead of empty
output, improving learnability and AI efficiency for every pipeline-oriented
script in every eval. No runtime behavior changed.

## Remaining risks

- The stream-stage signature strings are curated reference prose derived from
  the type checker's per-stage return types; they are not generated from a
  single machine-readable table, so a future stage-level type change could
  drift from the reference text until the strings are updated. The registry's
  completeness tests and the new jsonl regression test catch an *empty*
  signature but not a stale one.
- None other.
