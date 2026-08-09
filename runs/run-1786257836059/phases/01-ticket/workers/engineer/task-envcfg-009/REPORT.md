## Result

ready-for-review

## Branch

factory/task-envcfg-009/1786257843378

## Commit

04fb98f8c63b63cccffce7ef2c3cabde81bb05ba

## Files changed

- `crates/xsh-registry/src/signature/{modules,docs}.rs`: register and document `error.fail`.
- `crates/xsht/tests/api.rs`: exact API and search regressions.
- `src/sema/check.rs`, `src/sema/check/compact.rs`: preserve local `error` bindings.
- `src/syntax/node.rs`: assign the existing error effect to the module call.
- `tests/sema.rs`: checker compatibility and effect regressions.
- `docs/SPEC.md`: document the `error` compatibility exception.

## Tests

- `cargo test --test integration sema::checker_accepts_error_bindings_and_preserves_error_fail_effect` — passed.
- `cargo test -p xsht --test api api_error_fail_is_exactly_registered_and_searchable` — passed.
- `cargo test --test integration sema::` — 102 passed.
- `cargo test -p xsh-registry --lib` — 8 passed.
- `cargo test -p xsht --test api` — 34 passed.
- `cargo test --test integration libxsh_api` — 3 passed.
- `cargo test -p xsh --lib modules::signature` — passed.
- `cargo build -p xsht --bin xsht` — passed.
- `target/debug/xsht api api:error.fail` — exact entry returned with `Result[Unit, Error]` and `error` effect.
- `target/debug/xsht api search:fail` — includes `api: module.error.fail`.
- `git diff --check` — passed; committed worktree is clean.

## North-star impact

Agents can discover the existing deliberate-validation operation through the canonical API registry without breaking conventional local `error` payload bindings. The explicit specification and focused regressions make Result/error-effect boundaries learnable and preserve composability for existing systems glue.

## Remaining risks

Controller-owned `target/debug/xsht lint --fix` and the linked ten-case `task-envcfg-009` replay remain to be run by the controller.
