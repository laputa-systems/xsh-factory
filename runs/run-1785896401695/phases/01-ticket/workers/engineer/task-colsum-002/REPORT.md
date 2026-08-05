## Result

ready-for-review

## Branch

factory/task-colsum-002/1785896402449

## Commit

a1cbb632d1ab8673176f6ef9f9d9cf04a7ad5e02

## Files changed

- `src/syntax/arena.rs`
- `src/syntax/parser.rs`
- `src/syntax/parser/expr.rs`
- `tests/syntax.rs`
- `docs/SPEC.md`
- `docs/STREAMS.md`

## Tests

- `cargo test --test integration syntax::pipeline_value_calls_accept_plain_receivers_result_tails_and_named_blocks -- --exact` — passed.
- `cargo test --test integration syntax:: -- --test-threads=1` — 99 passed.
- `cargo build --bin xsht --bin xsh` — passed.
- `target/debug/xsht check /tmp/pipeline-shapes.xsh` — passed for plain receiver, block-parameter predicate, and Result-returning tail shapes.
- `target/debug/xsh /tmp/pipeline-shapes.xsh` — passed; output `2`, `b`, `a`.
- `git diff --check` — passed; worktree clean after commit.

## North-star impact

Value pipeline stages now lower to the same ordinary method or qualified-call shapes used elsewhere, including plain local receivers and trailing `?` Result propagation. Predicate blocks no longer get misclassified as proc commands when their body continues with an expression operator. This makes stream composition predictable for people and agents, reducing empirical syntax probing while preserving explicit call and Result boundaries.

## Remaining risks

The legacy mixed-pipeline fallback remains available for value stages that are not ordinary calls; those shapes retain their existing lowering path and contract. No known risk for the assigned acceptance shapes.
