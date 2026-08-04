# Engineer report

## Result

ready-for-review

## Branch

factory/task-ecount-009/1785809030662

## Commit

95dd3b643588c290d035d2d99a28d0839001d731

## Files changed

- src/runtime/eval/lower.rs — type `first`/`last`/`min`/`max` stream terminals as `Result<item, Error>` in the pouch slot-based pipeline inference (`infer_checked_stream_stage_type_with_slots`), so a `?`-then-method receiver inside a stream-stage closure is checked against the unwrapped item type instead of the input list type.
- tests/xsh/stdlib/streams.xsh — native regression tests for `(s.split(".") |> last())?.lower()` in a map block and a bare trailing `?` in a stage block.
- docs/SPEC.md — note that the `?`-unwrapped value may be used inline as a receiver in a stage block expression.

## Tests

- `xsht check /tmp/ecount/t2b.xsh` (exact evidence repro, `[fs, error]`, `fs.files`) — previously `err[compact.indexed-build] ... full_ir_function_blocker` at the proc line; now returns 0, and `xsh` runs it producing the expected lowercased outputs.
- `xsht check` / `xsh` agreement on `(s.split(".") |> last())?.lower()`, `.upper()`, and a `where` block with `?.contains("t")` — both accept and run correctly.
- Error propagation: `map { |row| row.get(0)? }` over `[["a"], [], ["b"]]` — `xsht check` accepts and `xsh` propagates the index-out-of-bounds error at runtime (traceback), i.e. checker and runtime agree.
- Workarounds unchanged: `List.get(index, fallback)` and `Path.ext()` still check and run as before.
- `xsht test tests/xsh/stdlib/streams.xsh` — 26 passed, 0 failed (includes new regression tests).
- `cargo test --test integration sema::` — 96 passed, 0 failed.
- `cargo test --test integration runtime::coverage::xsh_native_tests --features native-tests -- --exact` — passed (full native corpus).
- `git diff --check` — clean.

## North-star impact

A documented, idiomatic error-propagation form (`?` inside a stream-stage
closure, used inline as a method receiver) previously crashed the compiler with
an opaque, unlocated `full_ir_function_blocker` attributed to the enclosing
`proc` line, forcing agents into a `List.get(index, fallback)` discovery loop.
It now compiles, checks, and propagates normally with `xsht check` and `xsh` in
agreement — removing the trial-and-error workaround for ecount and any future
pipeline eval that wants to propagate an expected failure inside a
map/where/each block. This is the root fix for the `?`-in-closure trigger of
the shared IR-blocker family, not a task-specific shortcut.

## Remaining risks

The fix types the four Result-returning stream terminals
(`first`/`last`/`min`/`max`) in the lightweight slot-based pipeline inference.
Other future constructs that rely on that inference knowing a stage yields a
`Result` (rather than passing through the input list type) could surface
similar mis-typing, but they would be distinct triggers, outside this ticket's
boundary; the accurate checked-type path and the runtime already agree for
these cases, and the full native corpus passes.
