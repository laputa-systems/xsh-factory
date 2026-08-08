## Result

ready-for-review

## Branch

factory/task-trim-002/1786155405105

## Commit

d917d6d84f7c8360d122b0c571d386a4db902211

## Files changed

- `docs/SPEC.md` — documented terminal-newline behavior for `Str.lines()` and `Bytes.lines()`, including the newline-preserving reassembly idiom.
- `tests/xsh/stdlib/streams.xsh` — added a regression test proving terminal-newline line collection and round-trip reassembly.

## Tests

- `cargo test --test integration runtime::coverage::xsh_native_tests --features native-tests -- --exact` — passed (309 native tests; 6 skipped).
- `cargo run -p xsht --bin xsht -- lint --fix tests/xsh/stdlib/streams.xsh` — passed.
- `git diff --check` — passed.

## North-star impact

Makes line-oriented file transformations clearer and safer for people and agents: the canonical contract now states that terminal newlines do not create an empty final element and shows how to preserve one newline per input line during reassembly, avoiding a silent byte-loss trap.

## Remaining risks

The runtime behavior is unchanged; callers that need to preserve a terminal newline must apply the documented final append. A second file-rewriting eval replay remains a post-merge acceptance task.
