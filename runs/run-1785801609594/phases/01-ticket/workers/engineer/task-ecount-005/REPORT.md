## Result

ready-for-review

## Branch

factory/task-ecount-005/1785801610686

## Commit

acd2d5dc1a3b7d33c09441c99af484bb1504d8f7

## Files changed

- `src/runtime/eval/lowered_run/indexed_run.rs` — lower the terminal `each` stage to `LoweredValue::Unit` (tee remains a pass-through List stage), so a proc ending in `each` exits 0 with full output instead of `lowered return type mismatch`.
- `tests/runtime/streams.rs` — regression test `terminal_each_as_final_proc_statement_exits_clean` asserting `xsht check` and `xsh` agree.
- `docs/SPEC.md` — classify `each` as a Unit-valued terminal stage and note that a pipeline ending in a Unit terminal may be a proc's final statement.

## Tests

- `cargo test --test integration runtime::streams::` → 7 passed (includes new regression test).
- `cargo test --test integration sema::checker_accepts_pipeline_collect_terminal` → passed (checker still accepts a terminal stage).
- Manual probes: `xsht check` + `xsh` on a proc ending in `each` both succeed (exit 0, full output); `tee |> each` still passes items through (exit 0); a non-final terminal followed by a stage still fails at check time with `check.stream-terminal-stage`; a Unit-valued final statement behaves as before.
- `cargo test --test integration runtime::` → 232 passed; 3 failures confirmed pre-existing/environmental (verified by re-running them with this change stashed): `collections::fs_walk...` and `coverage::runnable_xsh_corpus...` fail on the base tree too (macOS tmp-path / snippet lint); `modules::net_module_download_many...` is a network flake that passes when run alone.
- `git diff --check` clean; worktree clean after commit.

## North-star impact

The north star asks for explicit boundaries, clear errors, and removing
"repeated discoveries." A program that printed correct output and then exited 3
with an internal `lowered return type mismatch` because an undocumented
trailing-statement convention forced every agent to rediscover it by trial and
error is exactly the learning-loop the factory exists to remove, and it
undermined trust in `xsht check`. This fix makes the runtime lower a terminal
`each` final expression to `Unit`, matching what the checker already accepts, so
an agent can end a pipeline naturally with a terminal stage and exit 0 with full
output. The checker/runtime contract generalizes to any stream-ending proc (each
can only be a final stage, since the checker rejects any stage that follows a
Unit terminal), and non-final terminal-stage behavior is unchanged. A regression
test and a canonical SPEC clarification make the agreement durable and
learnable.

## Remaining risks

- Only `each` (and `table.print`, already Unit) are Unit-valued terminal stages;
  terminal stages that yield a scalar/list type (`count`, `collect`, `sum`,
  `first`, etc.) cannot end a Unit-returning proc and are rejected at check time
  with a return-type diagnostic, which satisfies the acceptance contract.
- The three unrelated runtime-suite failures noted in Tests are pre-existing and
  environmental (macOS tmp-path / network flake), not caused by this change.
