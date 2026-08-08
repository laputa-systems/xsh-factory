## Result

ready-for-review

## Branch

factory/task-pathparts-002/1786167297024

## Commit

a652116f9cb91eb4a6d432731c9902c34007b172

## Files changed

- `crates/xsht/src/cli/lint.rs`: make the documented `lint.path-constructor` recommendation non-fatal.
- `docs/SPEC.md`: document the direct typed-`Path` cast as an advisory-lint boundary.
- `docs/XSHT.md`: document non-fatal quality guidance.
- `tests/runtime/coverage.rs`: regression test for clean exit with the Path constructor advisory.

## Tests

- `cargo test -p xsht --test integration lint:: --no-fail-fast` — passed (53 tests).
- `cargo test --test integration runtime::coverage::xsht_lint_accepts_documented_path_constructor_warning --no-fail-fast` — passed.
- `cargo test --test integration runtime::coverage::xsht_lint_reports_warnings_with_spans --no-fail-fast` — passed.
- `cargo test --test integration runtime::coverage:: --no-fail-fast` — 48 passed; the existing corpus test failed because `tests/xsh/stdlib/streams.xsh` needs formatting, unrelated to this change.
- `git diff --check` — passed.
- Worktree clean after commit.

## North-star impact

XSH now preserves the explicit typed-`Path` boundary named by a task without forcing agents to choose between a documented construction and a hard lint failure. The lint remains visible guidance, but only actual lint errors or other warnings fail the command. The run-scoped handbook candidate was updated with this reusable guidance lesson.

## Remaining risks

The broader corpus gate remains blocked by the pre-existing formatting failure in `tests/xsh/stdlib/streams.xsh`; no product file was changed to paper over it. The implementation treats only the specific `lint.path-constructor` advisory as non-fatal; all other lint diagnostics retain their existing status behavior.
