# Engineer report

## Result

ready-for-review

## Branch

factory/task-envcfg-004/1785801610686

## Commit

6ad50260d97184a66f514929fa6e8e2a45cd9989

## Files changed

- `crates/xsht/src/api.rs` — accept a bare `method:NAME` selector as a receiver-scoped index query that lists every method on that receiver by purpose; `method:NAME.MEMBER` still resolves one exact item. Documented the query in the `xsht api` onboarding text and JSONL guide.
- `crates/xsht/tests/api.rs` — added three integration tests: receiver listing, exact-member lookup preserved, and the shared Path receiver.
- `docs/XSHT.md` — documented `method:NAME` as the receiver overview query.

## Tests

- `cargo build --bin xsht` — ok.
- `cargo test -p xsht --test api` — 27 passed, 0 failed (covers the new receiver-listing tests plus the `search:`/`summary`/exact regressions).
- `cargo test -p xsht` — 97 passed, 0 failed.
- Manual: `xsht api method:Str`, `method:Path`, `method:Regex` list their members with `status: matches`; `method:Str.lower`, `search:parse_bytes`, and `summary` still resolve (the latter with `--format jsonl`).

## North-star impact

This removes the rejected-query discovery loop the task-envcfg worker hit. `xsht api` can now answer "what methods does a type have?" with one query (`method:Str`) instead of dumping the whole index and grepping it. The change matches an agent's natural spelling ("list Str methods"), applies to every receiver type (Str, Path, Regex, Result, …), and keeps exact lookups byte-for-byte intact, so future eval replays can resolve a type's member list in one index query.

## Remaining risks

None for the product change. The shared factory handbook (outside this worktree, manager-owned lineage) still says a bare receiver query such as `method:Str` is rejected; that sentence should be reconciled when the linked eval-manager promotes the handbook after replaying the merged commit.
