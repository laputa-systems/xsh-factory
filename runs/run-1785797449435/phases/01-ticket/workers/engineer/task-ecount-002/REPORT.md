# Engineer report

## Result

ready-for-review

## Branch

factory/task-ecount-002/1785797450137

## Commit

d9264c10f282ac310d50628046a226e8109bb211

## Files changed

- `src/runtime/eval/lower.rs`: made the compact-runtime special-cased argument lowering for `fs.files`/`fs.walk` (`lower_fs_files_args`) and `fs.mkdir`/`fs.remove` accept optional arguments positionally, matching `lower_fs_list_args` and the general `compact_module_bindings` mechanism.
- `tests/xsh/stdlib/fs.xsh`: added `test_fs_optional_arguments_accept_positional_forms` regression covering `fs.files`/`fs.walk` positional-vs-named equivalence.

## Tests

- `cargo build --bin xsh` / `cargo build --bin xsht` — clean debug build.
- `xsht check` on `fs.files(p, false)` and `fs.walk(p, false)` — exit 0 (accepted, no `full_ir_function_blocker`).
- `xsh` runs of ticket replica `fs.files(p, false)?` and `fs.walk(p, false)?` — compile and run, matching named forms byte-for-byte (`diff` of positional `false`/`true` vs `gitignore:false`/`gitignore:true` outputs = IDENTICAL).
- Non-fs general path: `archive.compress(p, p, "gzip", 6)` positional optional args compile and produce the compressed artifact (exit 0).
- Native tests: `xsht test tests/xsh/stdlib/fs.xsh` (10 passed, incl. new regression), `path` (5), `streams` (24), `archive` (2), `methods` (1) — all pass, no regressions.
- `xsht api api:fs.files` signature matches the now-accepted positional optional-argument forms.

## North-star impact

A documented optional-argument call shape (`fs.files(root, false)`) that previously failed with an opaque `full_ir_function_blocker` compiler error now compiles and behaves identically to the named form. Agents can trust `xsht api` signatures and pass optional arguments positionally, eliminating trial-and-error discovery and the single-argument workaround the eval worker had to use. The change generalizes the fs module in the compact runtime, and the general non-fs module path (`archive.compress`) already handled positional optionals, so the whole documented contract is now honored — boundaries/contracts are explicit and reliable as the north star asks.

## Remaining risks

The fix addresses the positional-optional-argument contract in the compact runtime for the special-cased `fs.files`/`fs.walk`/`fs.mkdir`/`fs.remove` functions and the general non-fs path. It does not address a separate, pre-existing compact-runtime gap: calling `List.len()` on a List produced by an `fs.files`/`fs.walk` pipeline still fails to lower (out of this ticket's scope; e.g. `[1,2,3] |> collect()` `.len()` works, but an `fs.files(...) |> collect()` `.len()` does not). This was confirmed as a distinct defect unrelated to positional optional arguments.
