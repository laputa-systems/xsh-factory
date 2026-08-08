## Result

ready-for-review

## Branch

factory/task-bigfiles-002/1786185106648

## Commit

c77b01a3e2fb676cc57cdeddbb7575be7723aa32

## Files changed

- `crates/xsh-registry/src/reference.rs`: documents command-word `sort-by` block spelling.
- `crates/xsh-registry/src/examples.rs`: attaches the sort-by API example.
- `docs/snippets/api/stream-sort-by.xsh`: adds the accepted `--desc` plus block example.
- `crates/xsht/tests/api.rs`: asserts the example is rendered and the misleading parenthesized spelling is absent.

## Tests

- `cargo build -p xsh -p xshi -p xsht --bin xsh --bin xshi --bin xsht` — passed.
- `cargo metadata --no-deps --format-version 1` — passed.
- `cargo test -p xsh-registry --lib` — 8 passed.
- `cargo test -p xsh --lib modules::signature` — passed.
- `cargo test -p xsht --test api api_stream_sort_by_shows_options_before_block` — passed.
- `cargo test -p xsht --test api api_inventory_is_standalone_and_documented` — passed.
- `cargo test -p xsht --test api api_stream_stages_carry_a_signature_in_jsonl` — passed.
- `cargo test --test integration libxsh_api` — 3 passed.
- `target/debug/xsht check docs/snippets/api/stream-sort-by.xsh` — passed.
- `target/debug/xsht lint --fix docs/snippets/api/stream-sort-by.xsh` — passed with no changes.
- `git diff --check` — passed.

## North-star impact

The `xsht api language:stream.sort-by` reference now explicitly teaches the composable command-word form for a named flag and block, while preserving the existing signature and parser behavior. Agents and people can reach `|> sort-by --desc { |e| e.size }` without trying rejected parenthesized call forms.

## Remaining risks

The required post-merge `task-bigfiles` replay remains for controller/CTO validation of first- or second-attempt adoption and byte-for-byte evaluator output; no parser grammar was changed.
