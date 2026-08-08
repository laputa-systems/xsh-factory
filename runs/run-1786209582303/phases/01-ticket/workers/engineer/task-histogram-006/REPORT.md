## Result

ready-for-review

## Branch

factory/task-histogram-006/1786209590202

## Commit

fc432eadf48fdbf607c52fe487770d630dad5838

## Files changed

- `src/syntax/parser/expr.rs`: recognize block-bearing unknown pipeline stages and emit a stage-level diagnostic naming the stage and recommending `where`.
- `tests/syntax.rs`: regression coverage for the `filter` diagnostic and absence of the misleading parse cascade.
- `docs/SPEC.md`: documents that `where` is the filtering stage and `filter` is not an alias.

## Tests

- `cargo test --test integration syntax::parser_reports_unknown_block_stream_stage_with_filtering_guidance`: passed.
- `cargo test --test integration syntax:: -- --test-threads=1`: passed (102 tests).
- `cargo test --test integration sema:: -- --test-threads=1`: passed (101 tests).
- `cargo build -p xsht --bin xsht`: passed.
- `target/debug/xsht check /tmp/task-histogram-006-filter.xsh`: failed as intended with `parse.unknown-stream-stage: unknown stream stage \`filter\`; use \`where\` for filtering`.
- `target/debug/xsht check /tmp/task-histogram-006-where.xsh` and `target/debug/xsht lint /tmp/task-histogram-006-where.xsh`: passed with no output.
- `git diff --check`: passed.
- Worktree clean after commit.

## North-star impact

Agents now get a direct, source-spanned explanation when a guessed block-bearing stream stage such as `filter` is used, including the working `where` spelling, rather than falling through to record-literal parsing and a misleading error cascade. The parser retains ordinary value-pipeline calls and does not add an alias or change stream runtime semantics.

The run-scoped handbook candidate was updated with the reusable `where`/no-`filter` alias lesson.

## Remaining risks

None known. The diagnostic recommendation is intentionally specific to filtering; other unknown stages receive the same stage-level error with that recommendation, which may be less relevant for non-filter guesses.
