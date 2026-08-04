# Engineer report

## Result

ready-for-review

## Branch

factory/task-ecount-007/1785805967997

## Commit

26c9922

## Files changed

- `src/sema/check/stream.rs` — fold/reduce blocks bind the accumulator (typed by the initial value) before the stream item and accept up to two parameters; three-parameter blocks get a fold-specific diagnostic; non-fold stages still accept at most one parameter.
- `src/runtime/eval/lower.rs` — `lower_pipeline_stage_fold` lowers the block tail via `lower_tail_stmt_as_expr`, so a bare accumulator tail no longer trips the compact indexed-IR builder (`full_ir_function_blocker`).
- `crates/xsh-registry/src/reference.rs` — `fold`/`reduce` API contract now states block parameter count and meaning, argument order, and result shape.
- `crates/xsh-registry/src/examples.rs` + `docs/snippets/api/stream-fold.xsh`, `stream-reduce.xsh` — working `xsht api language:stream.fold`/`reduce` examples.
- `docs/SPEC.md`, `docs/STREAMS.md` — document the two-parameter accumulator-plus-item fold block.
- `tests/xsh/stdlib/streams.xsh`, `tests/sema.rs` — regression tests.

## Tests

- `cargo build --bin xsh --bin xsht` — OK.
- Native stream tests: `xsht test streams` — 26 passed, 0 failed (includes new two-param fold, reduce, bare-tail, and Map-counting cases).
- Full native suite: `xsht test` — 326 passed, 0 failed, 6 skipped.
- `cargo test --test integration sema::` — 95 passed, 0 failed (includes new `checker_handles_fold_accumulator_plus_item_blocks`).
- `cargo test --test integration runtime::streams` — 7 passed, 0 failed.
- `cargo test -p xsh-registry --lib` — 8 passed; `cargo test -p xsh --lib modules::signature` — 1 passed; `cargo test -p xsht --test api` — 27 passed.
- `cargo test -p xsh --lib runtime::eval` — 26 passed, 2 ignored.
- Verified `[1,2,3] |> fold(0) { |acc, it| acc + it }` → 6, `reduce(10) {...}` → 16, bare `fold(0) { |x| x }` → 0 (no IR crash), and Map-accumulator counting via fold (a=2,b=1,c=1) which previously required the `group-by` workaround.
- `xsht check` and `xsh` agree on every form (accepted forms run; three-parameter form rejected by both with `check.stream-block-params`, no `compact.indexed-build`, no parse cascade).

## North-star impact

`fold`/`reduce` was advertised as a first-class stream stage but every
accumulator form failed (a check-time arity rejection, a parse cascade, or an
internal `full_ir_function_blocker` crash with no source mapping). This change
makes the documented accumulator-plus-item form compile, check, and run with a
precise signature, and makes unsupported forms fail with a clear, stage-naming
diagnostic — eliminating the IR crash and parse cascade. Agents can now
accumulate directly (`fold(init) { |acc, item| ... }`) including counting with
a Map accumulator, instead of reassembling it from undocumented `group-by`
records. `xsht api language:stream.fold` now states the block signature,
argument order, and result shape with a working example, removing the
trial-and-error loop the handbook told agents to enter.

## Remaining risks

The full-repo XSH corpus gate (`runnable_xsh_corpus_is_formatted_and_lints_without_warnings`)
and `cargo fmt --check` already fail on the base commit for pre-existing
unrelated reasons (e.g. `docs/snippets/api/stream-par-map.xsh` references
illustrative undefined names; broad rustfmt drift), so they are not reliable
gates here. My changed XSH/Rust files do not add new failures beyond that
pre-existing state.
