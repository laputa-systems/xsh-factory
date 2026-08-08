## Result

ready-for-review

## Branch

factory/task-safepath-004/1786165555987

## Commit

9bbc473af32e20e7bb3fa9b967a51acd89eb5200

## Files changed

- `src/runtime/eval/lower.rs` — select specialized integer lowering only when the checked expression is Int, allowing Str expressions to use general lowering.
- `tests/runtime/coverage.rs` — regression coverage for a mutable Str accumulator using `+` in a loop.
- `docs/SPEC.md` — document that `+` operates on Int and Str.

## Tests

- `cargo test --test integration runtime::coverage::mutable_string_accumulator_uses_string_addition_in_loop -- --exact` — passed.
- `cargo test --test integration runtime::coverage::reassigning_let_is_check_error -- --exact` — passed.
- `cargo test --test integration runtime::coverage:: -- --test-threads=1` — 47 passed, 1 unrelated existing corpus-format failure (`tests/xsh/stdlib/streams.xsh: needs formatting`).
- `target/debug/xsht check /tmp/safepath-004.xsh` — passed.
- `target/debug/xsht fmt /tmp/safepath-004.xsh` — passed.
- `target/debug/xsht lint /tmp/safepath-004.xsh` — passed.
- `git diff --check` — passed.
- Worktree clean after commit.

## North-star impact

Mutable Str accumulators now compose through ordinary `+` expressions in loop assignments, matching the existing expression behavior and removing the opaque runtime Int-lowering failure from a common systems-glue pattern. The regression test and canonical specification make the behavior durable and learnable for both people and agents.

## Remaining risks

The broader coverage gate has one unrelated pre-existing formatting failure in `tests/xsh/stdlib/streams.xsh`; no product failure was observed in the focused acceptance checks. No handbook candidate update was needed because the corrected canonical specification is the reusable guidance for this operator behavior.
