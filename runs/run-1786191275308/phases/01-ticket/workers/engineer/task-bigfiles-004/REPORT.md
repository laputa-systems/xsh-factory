## Result

ready-for-review

## Branch

factory/task-bigfiles-004/1786191276307

## Commit

608ab11bcf25cb0f69df4cb352fa40b27c1be2b3

## Files changed

- `crates/xsh-registry/src/signature/docs.rs`: document `hidden: false` and dot-entry omission for `fs.files` and `fs.walk`.
- `crates/xsht/tests/api.rs`: add API-reference regression coverage for both contracts.

## Tests

- `cargo build -p xsh -p xshi -p xsht --bin xsh --bin xshi --bin xsht` — passed.
- `cargo metadata --no-deps --format-version 1` — passed.
- `cargo test --test integration libxsh_api` — 3 passed.
- `cargo test -p xsh --lib modules::signature` — 1 passed.
- `cargo test -p xsht --test api` — 32 passed.
- `cargo test -p xsh-registry --lib` — 8 passed.
- `git diff --check` — passed.
- Worktree clean after commit.

## North-star impact

The `xsht api` contract now makes recursive filesystem discovery trustworthy and learnable: agents can see that `hidden: false` omits dot-prefixed files and directories and can explicitly choose `hidden: true`, without relying on fixture experiments. Runtime behavior remains unchanged.

## Remaining risks

None.
