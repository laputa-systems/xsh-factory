## Result

ready-for-review

## Branch

factory/task-safepath-003/1786163688493

## Commit

7e9814fe774ceeb9e587ae95c967944548706701

## Files changed

- `src/runtime/eval/lower.rs`: allow fold prefix statements containing lowered conditionals and reuse fold-tail lowering for nested conditional tails.
- `tests/runtime/streams.rs`: regression coverage for nested conditional statements and nested conditional branch tails in fold blocks.
- `docs/SPEC.md`, `docs/STREAMS.md`: document ordinary statements and nested conditionals in fold/reduce blocks.

## Tests

- `cargo test --test integration sema::checker_handles_fold_accumulator_plus_item_blocks` — passed.
- `cargo test --test integration runtime::streams -- --nocapture` — passed (10 tests).
- `cargo test --test integration runtime::coverage::runnable_xsh_corpus_is_formatted_and_lints_without_warnings` — pre-existing failure: `tests/xsh/stdlib/streams.xsh: needs formatting`; no corpus file was changed.
- `git diff --check` — passed.
- Worktree clean after commit.

## North-star impact

Fold now remains a composable, trustworthy stateful glue construct when an accumulator update needs ordinary statements or nested conditional control flow. Natural in-fold code no longer requires a let-hoist workaround or exposes an opaque indexed-IR blocker, and the canonical specification documents the supported form for agents and people.

## Remaining risks

The runnable XSH corpus gate remains blocked by the pre-existing formatting mismatch in `tests/xsh/stdlib/streams.xsh`; the implementation and focused stream tests pass. No handbook candidate change was justified.
