# Engineer report

## Result

ready-for-review

## Branch

factory/task-ecount-006/1785804031017

## Commit

eead8f790a5a501bc971614625cec8897c55f279

## Files changed

- src/runtime/eval/lower.rs (Type the `Collect` stream terminal as producing a `List`, so a module stream piped straight into `collect()` is not mis-typed as a stream)
- tests/xsh/stdlib/streams.xsh (native regression test: direct `fs.files(root) |> collect()` then `len()`)

## Tests

- `cargo build --bin xsh --bin xsht` — ok
- `xsht check` and `xsh` on the ticket's probe1 (`fs.files(p"/usr/share")? |> collect(); print $all.len()`): before the fix `err[compact.indexed-build] ... full_ir_function_blocker`; after the fix `check` exit 0 and `xsh` prints the entry count (`15730`), with `?`/`[fs,error]` and without `?`/`[fs]` variants both passing. The transform-stage probe2 continues to run.
- `cargo test -p xsh --test integration runtime::streams --features native-tests` — 7 passed
- `cargo test -p xsh --test integration runtime::coverage::xsh_native_tests --features native-tests -- --exact` — ok (includes the new native regression test)
- `cargo test -p xsh --test integration -- sema::` — 94 passed
- `cargo test -p xsh --test integration -- runtime::collections runtime::modules runtime::streams` — 41 passed; the single failure (`fs_walk_streams_lazily_and_short_circuits_take_first_any_and_break`) is a pre-existing parser/`&&` failure that also fails on the clean base commit (verified via `git stash`).
- `cargo test -p xsht --test integration -- cli::check_reports_compact_lowerability_by_default cli::check_compact_lowerability_reports_dependency_blocker cli::check_top_level_lowerability_reports_first_nested_call_blocker` — 3 passed (these cover unrelated blockers and remain intact)
- `git diff --check` — ok

## North-star impact

The handbook documents `fs.files(...) |> collect()` as the standard minimal terminal for a lazy module stream, but the compact body type inference mis-typed the direct (no-transform-stage) `collect()` result as a `Stream`. That made the documented first stream program fail with an opaque internal `full_ir_function_blocker` (and, when printed directly, a misleading "value cannot be displayed" stream error), costing agents discovery turns bisecting stage order. Typing the `Collect` terminal as materializing a `List` makes the documented pattern compile and run, so the checker and runtime agree and the misleading internal diagnostic no longer leaks for this case. This is a general ergonomics/learnability fix for any XSH program that consumes a module stream, not a task-specific workaround.

## Remaining risks

The fix targets the shared `Collect` terminal typing and removes the `full_ir_function_blocker` for this documented trigger. Other distinct compact-lowering blockers (e.g. `with` blocks in fallible procs, unsupported param defaults, positional optional args on `fs.files`/`fs.walk`) are separate root causes and are intentionally left untouched, per the ticket scope. The pre-existing `fs_walk_streams_lazily_and_short_circuits_take_first_any_and_break` `&&` parse failure is unrelated to this change and present on the base commit.
