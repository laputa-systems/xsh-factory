## Result

ready-for-review

## Branch

factory/task-render-001/1786159269627

## Commit

461fe36bfd0d1ca5670777e2ea1531f902e88558

## Files changed

- crates/xsh-registry/src/signature/docs.rs
- crates/xsh-registry/src/signature/mod.rs
- crates/xsht/src/api.rs
- crates/xsht/tests/api.rs

## Tests

- `cargo test -p xsht --test api` — 31 passed.
- `cargo test -p xsh-registry --lib` — 8 passed.
- `cargo test --test integration libxsh_api` — 3 passed.
- `cargo run -p xsht -- lint --fix docs/snippets/api/hello.xsh` — passed; no product files changed.
- `git diff --check` — passed.
- `target/debug/xsht api method:Map` and `target/debug/xsht api summary | grep -A20 '── Map'` — both show `map.empty()` / `module.map.empty` under Map.

## North-star impact

The API registry now associates the existing `map.empty()` factory with the `Map` type. Type-first discovery exposes the constructor reference, its signature, and the Record-vs-Map `{}` distinction without probing the module summary, improving learnability and reducing failed exploration for parsed-text aggregation and other systems-glue workflows. Runtime behavior and language semantics are unchanged.

The reusable discovery lesson was staged in the supplied run-scoped handbook candidate: `lineage/handbook-candidate.md`.

## Remaining risks

Replay evidence for `task-render` and the second map-building eval remains a controller/CTO post-merge activity; this branch provides the API and regression coverage but does not run those factory evals.
