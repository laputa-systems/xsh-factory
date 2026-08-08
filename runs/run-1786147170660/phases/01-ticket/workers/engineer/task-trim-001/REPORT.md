## Result

ready-for-review

## Branch

factory/task-trim-001/1786147173597

## Commit

2e244e4ac8c724c2e4720e8840405f8faaee1fb1

## Files changed

- `src/sema/check.rs`: actionable unrestricted-proc effect diagnostic recommending `[]` for side-effect-free helpers.
- `tests/sema.rs`: regression coverage for the diagnostic and valid `[]` helper call.
- `docs/SPEC.md`: documents the diagnostic guidance.

## Tests

- `cargo test --test integration sema::checker_suggests_empty_effect_list_for_unrestricted_callee` — passed.
- `cargo test --test integration sema::` — passed (99 tests).
- `git diff --check` — passed.
- Worktree clean after commit.

## North-star impact

Side-effect-free helpers called from effect-declaring procedures now receive a direct, reusable explanation of the existing `[]` effect-list spelling. This reduces agent guessing while preserving explicit effect boundaries and unchanged checker semantics.

## Remaining risks

None.
