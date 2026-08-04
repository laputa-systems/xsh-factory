# Engineer report

## Result

ready-for-review

## Branch

factory/task-envcfg-007/1785797450137

## Commit

b9251bc79ae42b6321e31d3c568d40a03afa9186

## Files changed

- `src/runtime/eval.rs` — add `compact.main-missing-spread` check-time diagnostic and helper in the compact lowerability path.
- `crates/xsht/tests/cli.rs` — CLI regression test for the spread requirement.
- `docs/SPEC.md` — document the entry `main` spread requirement and check-time diagnostic.

## Tests

- `cargo build --bin xsh --bin xsht` — passes.
- `cargo test -p xsht --test integration` — 97 passed, 0 failed (includes the new `check_rejects_main_without_spread_parameter_but_accepts_spread` and the lint suite).
- `cargo test --test integration runtime::` — passes; only the 2 pre-existing `&&`-related failures remain (`collections::fs_walk…`, `coverage::runnable_xsh_corpus…`), both confirmed to fail on the clean base tree.
- `cargo test --test integration sema::` — 94 passed, 0 failed.
- `cargo test --test integration` (full root) — only the same 2 pre-existing `&&` failures; no new failures.
- Manual acceptance: `proc main(argv: List[Str])` → `xsht check` prints `err[compact.main-missing-spread]: proc main must use the spread form `(...argv: List[Str])`…` with rc=2; `proc main(...argv: List[Str]) [fs, env, error]` passes `xsht check` (rc=0) and runs under `xsh`. Empty `main()`, fixed scalar/defaulted params (e.g. `main(value = 7)`, `main(src: Path, dest: Path)` + `main(@args)?`), and `main(arg: Str)` all still check and/or run correctly.

## North-star impact

Closes the check-pass / run-fail split on CLI entry-point signatures: an agent's
`xsht check` result is now a trustworthy gate for the entry point `xsh` will
actually run, in every eval, instead of a green check followed by a
`compact-unsupported-main` run-time round-trip that does not explain why. This
reduces trial-and-error discovery for agents writing any `main` entry point and
moves the failure earlier with a constructive message naming the spread form,
directly serving the north-star goals of trust, learnability, and fewer repeated
discoveries without changing spread semantics or the runtime execution model.

## Remaining risks

The static rule is deliberately conservative to match the runtime binder:
it rejects only a fixed, non-defaulted, non-`Str`/`Path` `main` parameter, which
can never bind a CLI scalar. It does not attempt to validate the CLI-argument
*count* against a fixed scalar/defaulted signature (a `main(src: Path, dest:
Path)` run with the wrong number of arguments can still fail at run time), which
is out of scope for this ticket and left to the existing runtime/binder
behavior. The `&&`→`and` corpus failures in the runtime suite are pre-existing
on the base snapshot and unrelated to this change.
