## Result

ready-for-review

## Branch

factory/task-pathparts-001/1786138323873

## Commit

30fabd4e12181830d146615b978861bef0737f96

## Files changed

- `src/runtime/eval.rs`, `src/runtime/eval/lower.rs`, `src/runtime/eval/lowered_ops.rs`: added typed `Path.basename()`, POSIX `Path.dirname()`, and tri-state-compatible `Path.ext_or()` behavior.
- `crates/xsh-registry/src/signature/{methods,docs}.rs`: registered and documented the methods.
- `docs/SPEC.md`: documented the canonical Path surface.
- `tests/xsh/stdlib/path.xsh`: added edge-case regression coverage.

## Tests

- `cargo test --test integration runtime::coverage::xsh_native_tests --features native-tests -- --exact` — passed.
- `cargo test -p xsh-registry --lib signature:: --quiet` — 2 passed.
- `cargo test -p xsht --test api --quiet` — 29 passed.
- `target/debug/xsht check tests/xsh/stdlib/path.xsh` — passed.
- Independent BusyBox dirname/basename/extension oracle comparison across public, hidden, and special-shape cases — all match.
- `git diff --check` — passed; worktree clean after commit.

## North-star impact

Typed `Path` values now provide an explicit, composable boundary for POSIX-style directory and basename decomposition without forcing agents back to raw string parsing. `ext_or()` preserves the existing `ext()` API while distinguishing missing extensions from an empty trailing-dot extension, making path contracts clearer and learnable.

## Remaining risks

`Path.name()`, `Path.parent()`, and `Path.ext()` retain their existing native semantics for compatibility; callers targeting POSIX behavior should use the new explicit methods. The linked evaluator replay remains a controller/CTO review step.
