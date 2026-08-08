## Result

ready-for-review

## Branch

factory/task-grep-001/1786206303274

## Commit

26d59eb844b670365931d91ffb15ae8c109bae12

## Files changed

- `src/sema/check/call.rs`: resolve locally bound names before treating qualified calls as standard-module calls.
- `tests/sema.rs`: regression test for a shadowed `path` binding and valid `Path.read_text()` method.

## Tests

- `cargo test --test integration sema::checker_reports_shadowing_as_the_cause_of_module_like_method_calls` — passed.
- `cargo test --test integration sema::` — passed (101 tests).
- `git diff --check` — passed.
- Worktree clean after commit.

## North-star impact

A local binding now takes precedence over a same-named standard module during qualified-call checking. Agents receive the actionable `check.standard-module-shadow` diagnostic without a misleading `check.unknown-module-api` diagnostic when using a natural path variable name, reducing debugging guesses while preserving valid standard-module calls.

## Remaining risks

None.
