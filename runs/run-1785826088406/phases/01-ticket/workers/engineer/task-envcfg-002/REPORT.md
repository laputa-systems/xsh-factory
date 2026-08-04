## Result

ready-for-review

## Branch

factory/task-envcfg-002/1785826089064

## Commit

2d423c166b9c06aee44b9f4e720554ebeee1216b

## Files changed

- `crates/xsh-registry/src/reference.rs`: registered and documented `language.core.fail` with signature, contract, tags, and validation semantics.
- `crates/xsht/tests/api.rs`: added exact-query and `search:fail` API coverage.

## Tests

- `cargo test -p xsh-registry --lib` — passed (8 tests).
- `cargo test -p xsht --test api api_fail_builtin` — passed (2 tests).
- `cargo test -p xsht --test api` — passed (30 tests).
- `cargo test -p xsh --lib modules::signature` — passed (1 test).
- `cargo build --bin xsh && cargo build --bin xsht` — passed.
- `target/debug/xsht api search:fail` and `target/debug/xsht api language:core.fail` — exact `language.core.fail` entry returned with purpose, contract, effects, signature, and tags.
- `git diff --check` — passed.

## North-star impact

Makes the deliberate validation-failure boundary discoverable through XSH's canonical live API, so people and agents can use structured `fail(message)?` instead of opaque sentinel host-operation workarounds. This improves learnability, explicit error boundaries, and reliable systems-glue composition without changing runtime semantics.

## Remaining risks

None.
