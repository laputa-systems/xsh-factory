## Result

ready-for-review

## Branch

factory/task-histogram-003/1786128117659

## Commit

857154dfe505f0d01053c1b5311f44422070eb34

## Files changed

- `src/sema/check.rs`
- `src/sema/check/command.rs`
- `src/sema/check/stream.rs`
- `tests/sema.rs`
- `docs/SPEC.md`
- `docs/STREAMS.md`

## Tests

- `cargo test --test integration sema::checker_rejects_fold_output_with_actionable_diagnostic` — passed.
- `cargo test --test integration sema::checker_handles_fold_accumulator_plus_item_blocks` — passed.
- `cargo test --test integration runtime::streams` — 7 passed.
- `cargo test --test integration runtime::coverage::runnable_xsh_corpus_is_formatted_and_lints_without_warnings` — passed.
- `git diff HEAD --check` — passed; worktree clean.

## North-star impact

Fold/reduce output now fails during checking with `check.fold-effect` and explains the pure-reduction boundary while pointing agents to a composable `each` output stage, replacing the opaque indexed-IR blocker. Canonical stream specification and documentation now teach the reusable constraint and idiom.

## Remaining risks

The change diagnoses direct `print`/`eprint` commands in fold/reduce blocks; other unsupported effects may still surface through separate checker or lowerability diagnostics. No runtime semantics were changed.
