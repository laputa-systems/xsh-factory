## Result

ready-for-review

## Branch

factory/task-envcfg-001/1785876950208

## Commit

754fcba8d1d15fb3d8c0a03f11fbf2708b463a03

## Files changed

- `src/sema/check/call.rs` — type-check `fail(message)` as `Result[Unit, Error]`.
- `src/runtime/eval.rs`, `src/runtime/eval/indexed/full.rs`, `src/runtime/eval/lower.rs`, `src/runtime/eval/lowered_run/indexed_run.rs` — lower, encode, and evaluate deliberate validation failures.
- `docs/SPEC.md` — canonical `fail` and `?` contract.
- `tests/xsh/run.xsh` — native regression for nonzero propagation and no output.

## Tests

- `cargo test --test integration runtime::coverage::xsh_native_tests -- --exact` — passed.
- `cargo test --test integration runtime::run::process_failures_report_distinct_error_kinds -- --exact` — passed.
- `cargo test --test integration sema::` — 96 passed.
- `cargo test -p xsh-registry --lib` — 8 passed.
- `cargo test -p xsht --test api` — 30 passed, including `fail` discovery.
- `cargo test --test integration runtime::` — 230 passed, 6 unrelated baseline failures, 26 ignored; failures are existing boolean-operator/fixture issues and did not involve `fail`.
- Manual acceptance: `xsht check` and `xsht lint` accepted a script using `fail("invalid port")?`; `xsh` exited 3 with `validation: invalid port`, emitted no stdout, and created no output file.
- `git diff --check` — passed; final worktree clean.

## North-star impact

Provides a first-class, explicit validation error instead of requiring an unrelated sentinel conversion. `fail(message)?` makes expected rejection visible, preserves structured Result propagation, and lets systems-glue programs stop before side effects such as writing an output file.

## Remaining risks

None for the assigned behavior. The broader runtime gate still exposes pre-existing unrelated failures in repository fixtures and boolean-operator compatibility tests.
