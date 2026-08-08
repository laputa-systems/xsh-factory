## Result

ready-for-review

## Branch

factory/task-dupcheck-002/1786201139234

## Commit

b9cc3ffc6425b365a172c5a897ed9684db235487

## Files changed

- `crates/xsht/src/api.rs`: append an explicit positional-only calling convention note to contracts whose signatures contain defaulted parameters.
- `crates/xsht/tests/api.rs`: regression coverage for `xsht api api:fs.files`.
- Run-scoped handbook candidate updated with the reusable positional-only/default parameter lesson.

## Tests

- `cargo test -p xsht --test api --no-fail-fast` — 32 passed.
- `cargo test -p xsh-registry --lib` — 8 passed.
- `cargo test -p xsh --lib modules::signature` — 1 passed.
- `cargo test --test integration libxsh_api` — 3 passed.
- `cargo metadata --no-deps --format-version 1` — passed.
- `bash scripts/check-libxsh-imports.sh` — passed.
- `target/debug/xsht api api:fs.files` — rendered the positional-only note and defaulted signature.
- `target/debug/xsht api summary --format jsonl` — passed.
- `xsht lint --fix` smoke check — passed on a temporary XSH script; no product files changed.
- `git diff --check` — passed.
- Final worktree clean after commit.

## North-star impact

`xsht api` now makes the positional-only boundary explicit wherever a displayed callable signature contains `= default`, preventing readers from inferring unsupported `name = value` syntax while preserving existing positional calls and language semantics. This reduces avoidable parse-error turns for agents doing systems-glue work.

## Remaining risks

None.
