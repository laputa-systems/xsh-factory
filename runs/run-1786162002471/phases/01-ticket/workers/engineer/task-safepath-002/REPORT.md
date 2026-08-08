## Result

ready-for-review

## Branch

factory/task-safepath-002/1786162005661

## Commit

95878384b9d6bb66f5631d630dca4d306f95a3a0

## Files changed

- `src/runtime/eval/lower.rs`: preserve fold accumulator types and lower value-producing conditional fold arms.
- `src/runtime/eval/indexed/full.rs`: retain lowerer blocker locations when reporting indexed build failures.
- `tests/runtime/streams.rs`: regression coverage for an in-fold `take`/`collect` pipeline over an accumulator field.

## Tests

- `cargo check -p xsh` — passed.
- `cargo test --test integration runtime::streams::fold_block_can_compose_pipeline_over_accumulator_field -- --exact` — passed.
- `git diff --check` — passed.
- Worktree clean after commit.

## North-star impact

Fold accumulators can now express the existing stream composition needed for list pop-last logic without a task-specific workaround. The lowerer carries checked accumulator record types into the fold scope and preserves the source location of lowerability failures, improving composability and making future diagnostics more actionable for people and agents.

## Remaining risks

The focused regression passes. Broader stream coverage was not run in this session; the implementation is limited to compact lowering paths exercised by the regression.
