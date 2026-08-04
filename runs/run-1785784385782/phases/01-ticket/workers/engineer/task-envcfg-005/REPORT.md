# Engineer report

## Result

ready-for-review

## Branch

factory/task-envcfg-005/1785784386279

## Commit

746a851a7b3ac51e84be8f6d0af34dcaa612687d

## Files changed

- `src/runtime/eval.rs` — add `WhereBlock`/`AnyBlock`/`AllBlock` variants to `LoweredPipelineStage`.
- `src/runtime/eval/lower.rs` — lower multi-statement predicate blocks for `where`/`any`/`all` via the existing block-stage path (single-expression form still preferred).
- `src/runtime/eval/indexed/full.rs` — add the three stage tags and their codec (encode/decode/verify) entries.
- `src/runtime/eval/lowered_run/indexed_run.rs` — evaluate the new block stage tags in the compact runtime; extend stage names.
- `crates/xsh-registry/src/reference.rs` — document that where/map/any/all predicate/transform blocks may contain multiple statements including local `let` bindings.
- `tests/xsh/stdlib/streams.xsh` — native regression test comparing multi-statement block predicates with the single-expression form.

## Tests

- `target/debug/xsht check /tmp/final_let.xsh` (closure-with-`let`): accepted, no `full_ir_function_blocker`, exit 0.
- `target/debug/xsh /tmp/final_let.xsh` and single-expression form: both print `true` (identical results), exit 0.
- `target/debug/xsht test "stdlib/streams.xsh::test_predicate_stage_blocks_bind_local_lets"`: ok.
- `target/debug/xsht test "stdlib/streams.xsh"`: 24 passed.
- `cargo test -p xsh --lib runtime::eval::indexed::full::tests`: 17 passed.
- `cargo test -p xsh --test integration runtime::coverage::xsh_native_tests --features native-tests`: ok.
- `cargo test -p xsh-registry --lib`: 8 passed.
- `cargo test -p xsht --test api`: 19 passed.
- `cargo test -p xsht --test integration cli::`: 33 passed.
- `xsht fmt --check` / `xsht lint` on `tests/xsh/stdlib/streams.xsh`: clean.

Note: the runnable-corpus gate (`runtime::coverage::runnable_xsh_corpus_is_formatted_and_lints_without_warnings`) fails on the clean baseline before this change due to pre-existing `docs/snippets/api/*.xsh` formatting and lint issues; none of the failing files are touched by this change.

## North-star impact

Makes a core stream-composition idiom — a predicate/transform block that binds a
local with `let` — compile in the compact runtime instead of surfacing the
opaque `err[compact.indexed-build]`: indexed IR could not encode
`full_ir_function_blocker`. Agents can now write digit/range validation with a
local binding and trust that the compact runtime matches the handbook, removing
the single-expression workaround that re-evaluates method calls and the repeated
failed probes previously needed to discover the restriction. The fix generalizes
across `where`/`any`/`all` (and is consistent with the already-supported
multi-statement `map`/`each` blocks), and the `xsht api language:stream` text now
documents the accepted block form, making the boundary learnable.

## Remaining risks

The block support was added for `where`, `any`, and `all` (the minimum required
by the ticket, plus the already-supported map-family and fold/reduce block
forms). Other projection-key stages that still lower through the single-expression
path (`sort-by`, `unique-by`, `group-by`, `count-by`) were left unchanged; a
multi-statement key block in one of those still falls back to the existing
blocker. Extending them would follow the same pattern if a future ticket needs it.
