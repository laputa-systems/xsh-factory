# CTO briefing 01-ticket

This is the deterministic first-pass briefing for the CTO. The structured
`report.json` files and raw Pi sessions remain the source of truth.

## Result

fail

## Operating context

- Mode: `ticket-implementation`
- Request: `CYCLE-REQUEST.md`
- Structured report: `report.json`

## Phase outcomes

- `report.json`: result `pass`; report `report.json`
- `workers/director/director/report.json`: result `pass`; report `workers/director/director/report.json`
- `workers/engineer/task-ecount-002/report.json`: result `pass`; report `workers/engineer/task-ecount-002/report.json`
- `workers/engineer/task-envcfg-007/report.json`: result `pass`; report `workers/engineer/task-envcfg-007/report.json`


## Employee accounting

### Worker metrics

- `director/director` (`director`): result `pass`; report `workers/director/director/report.json`
  - Execution: `not recorded`; classification: `not recorded`
  - Turns: `12`; bucket tokens: `207781`; thinking blocks: `11`
  - Tool errors: `0`; cost: `0.007338`; budget: `0.060000`
- `engineer/task-ecount-002` (`engineer`): result `pass`; report `workers/engineer/task-ecount-002/report.json`
  - Execution: `not recorded`; classification: `not recorded`
  - Turns: `124`; bucket tokens: `8383569`; thinking blocks: `88`
  - Tool errors: `1`; cost: `0.203852`; budget: `0.250000`
- `engineer/task-envcfg-007` (`engineer`): result `pass`; report `workers/engineer/task-envcfg-007/report.json`
  - Execution: `not recorded`; classification: `not recorded`
  - Turns: `160`; bucket tokens: `11402713`; thinking blocks: `96`
  - Tool errors: `3`; cost: `0.243475`; budget: `0.250000`


### Nonzero tool results

- `engineer/task-ecount-002`, turn `116`, tool `edit`: Could not find the exact text in /Users/josh/d/laputa-systems/xsh-factory/runs/run-1785797449435/phases/01-ticket/workers/engineer/task-ecount-002/REPORT.md. The old text must match exactly including all whitespace and newlines.
  - Structured report: `workers/engineer/task-ecount-002/report.json`
- `engineer/task-envcfg-007`, turn `23`, tool `bash`: ls: src/bin/: No such file or directory


Command exited with code 1
  - Structured report: `workers/engineer/task-envcfg-007/report.json`
- `engineer/task-envcfg-007`, turn `33`, tool `bash`: (no output)

Command exited with code 1
  - Structured report: `workers/engineer/task-envcfg-007/report.json`
- `engineer/task-envcfg-007`, turn `101`, tool `edit`: Could not find edits[1] in /Users/josh/d/laputa-systems/xsh-factory/runs/run-1785797449435/phases/01-ticket/worktrees/task-envcfg-007/src/runtime/eval.rs. The oldText must match exactly including all whitespace and newlines.
  - Structured report: `workers/engineer/task-envcfg-007/report.json`


### Cycle total

- Workers: `3`
- Assistant turns: `296`
- Bucket tokens: `19994063`
- Cost (USD): `0.454665`
- Nonzero tool results: `4`
- Budget failures or unknown costs: `0`


## Employee decisions

### director/director

- Role: `director`
- Result: `pass`
- Report: `workers/director/director/REPORT.md`

#### Efficiency and evidence

Mode: `ticket-implementation`. The controller admitted two approved tickets from the shared portfolio — `task-ecount-002` (eval `task-ecount`, status `Approved.`) and `task-envcfg-007` (eval `task-envcfg`, status `Approved.`) — created one isolated worktree per ticket, and launched both engineer rows concurrently through the shared runner. `FACTORY_DIRECTOR_RECONCILE_ONLY=true`, so the controller had already dispatched the engineers; I reconciled their completed reports and recorded branches/commits without merging. XSH main commit resolved to `84fe556cb48feb747d6b575e4925dbdc5848ecdb`; both worktrees are based on it.

#### Handbook or proposal decision

not reported

#### Ticket or product decision

not reported

#### Next action

- Engineer `REPORT.md` per admitted row: present and valid for both `task-ecount-002` and `task-envcfg-007` (`## Result` = `ready-for-review`, `## North-star impact` present).
- Engineer `report.json` per row: present, `result: pass`, `required_report: present` for both.
- Worktree per ticket: present, clean (`git status --porcelain` empty), branch and commit recorded above; each commit is a child of XSH main `84fe556`.
- Controller-admitted rows reconciled: 2/2. No branches merged, no main-branch modification, no ticket-status change (left to CTO).

#### North-star impact

Both tickets strengthen the trust contract between an agent's static `xsht check`/`xsht api` surface and what the compiled program accepts at run time. `task-ecount-002` makes documented positional optional arguments (`fs.files(root, false)`) compile in the compact runtime instead of raising an opaque `full_ir_function_blocker`, generalizing the fs module to match the already-working non-fs path. `task-envcfg-007` moves the `compact.main` entry-signature rule to check time with a constructive message, eliminating a green-check-then-run-failure round trip. Together they reduce trial-and-error discovery and opaque errors for agents writing real XSH — a general ergonomics and learnability improvement rather than a task-specific trick. Uncertainty: the envcfg worker reached its 160-turn ceiling after committing, so its evidence chain is slightly thinner than ideal, and neither change has yet been replayed by a linked eval; CTO review/merge and a subsequent eval replay remain the next falsification steps.

### engineer/task-ecount-002

- Role: `engineer`
- Result: `ready-for-review`
- Report: `workers/engineer/task-ecount-002/REPORT.md`

#### Efficiency and evidence

- `cargo build --bin xsh` / `cargo build --bin xsht` — clean debug build.
- `xsht check` on `fs.files(p, false)` and `fs.walk(p, false)` — exit 0 (accepted, no `full_ir_function_blocker`).
- `xsh` runs of ticket replica `fs.files(p, false)?` and `fs.walk(p, false)?` — compile and run, matching named forms byte-for-byte (`diff` of positional `false`/`true` vs `gitignore:false`/`gitignore:true` outputs = IDENTICAL).
- Non-fs general path: `archive.compress(p, p, "gzip", 6)` positional optional args compile and produce the compressed artifact (exit 0).
- Native tests: `xsht test tests/xsh/stdlib/fs.xsh` (10 passed, incl. new regression), `path` (5), `streams` (24), `archive` (2), `methods` (1) — all pass, no regressions.
- `xsht api api:fs.files` signature matches the now-accepted positional optional-argument forms.

#### Handbook or proposal decision

not reported

#### Ticket or product decision

The fix addresses the positional-optional-argument contract in the compact runtime for the special-cased `fs.files`/`fs.walk`/`fs.mkdir`/`fs.remove` functions and the general non-fs path. It does not address a separate, pre-existing compact-runtime gap: calling `List.len()` on a List produced by an `fs.files`/`fs.walk` pipeline still fails to lower (out of this ticket's scope; e.g. `[1,2,3] |> collect()` `.len()` works, but an `fs.files(...) |> collect()` `.len()` does not). This was confirmed as a distinct defect unrelated to positional optional arguments.

#### Next action

not reported

#### North-star impact

A documented optional-argument call shape (`fs.files(root, false)`) that previously failed with an opaque `full_ir_function_blocker` compiler error now compiles and behaves identically to the named form. Agents can trust `xsht api` signatures and pass optional arguments positionally, eliminating trial-and-error discovery and the single-argument workaround the eval worker had to use. The change generalizes the fs module in the compact runtime, and the general non-fs module path (`archive.compress`) already handled positional optionals, so the whole documented contract is now honored — boundaries/contracts are explicit and reliable as the north star asks.

### engineer/task-envcfg-007

- Role: `engineer`
- Result: `ready-for-review`
- Report: `workers/engineer/task-envcfg-007/REPORT.md`

#### Efficiency and evidence

- `cargo build --bin xsh --bin xsht` — passes.
- `cargo test -p xsht --test integration` — 97 passed, 0 failed (includes the new `check_rejects_main_without_spread_parameter_but_accepts_spread` and the lint suite).
- `cargo test --test integration runtime::` — passes; only the 2 pre-existing `&&`-related failures remain (`collections::fs_walk…`, `coverage::runnable_xsh_corpus…`), both confirmed to fail on the clean base tree.
- `cargo test --test integration sema::` — 94 passed, 0 failed.
- `cargo test --test integration` (full root) — only the same 2 pre-existing `&&` failures; no new failures.
- Manual acceptance: `proc main(argv: List[Str])` → `xsht check` prints `err[compact.main-missing-spread]: proc main must use the spread form `(...argv: List[Str])`…` with rc=2; `proc main(...argv: List[Str]) [fs, env, error]` passes `xsht check` (rc=0) and runs under `xsh`. Empty `main()`, fixed scalar/defaulted params (e.g. `main(value = 7)`, `main(src: Path, dest: Path)` + `main(@args)?`), and `main(arg: Str)` all still check and/or run correctly.

#### Handbook or proposal decision

not reported

#### Ticket or product decision

The static rule is deliberately conservative to match the runtime binder:
it rejects only a fixed, non-defaulted, non-`Str`/`Path` `main` parameter, which
can never bind a CLI scalar. It does not attempt to validate the CLI-argument
*count* against a fixed scalar/defaulted signature (a `main(src: Path, dest:
Path)` run with the wrong number of arguments can still fail at run time), which
is out of scope for this ticket and left to the existing runtime/binder
behavior. The `&&`→`and` corpus failures in the runtime suite are pre-existing
on the base snapshot and unrelated to this change.

#### Next action

not reported

#### North-star impact

Closes the check-pass / run-fail split on CLI entry-point signatures: an agent's
`xsht check` result is now a trustworthy gate for the entry point `xsh` will
actually run, in every eval, instead of a green check followed by a
`compact-unsupported-main` run-time round-trip that does not explain why. This
reduces trial-and-error discovery for agents writing any `main` entry point and
moves the failure earlier with a constructive message naming the spread form,
directly serving the north-star goals of trust, learnability, and fewer repeated
discoveries without changing spread semantics or the runtime execution model.



## Eval proposal review

No CTO eval review was recorded.

## Handbook lineage

No handbook lineage snapshots were recorded for this run. Checked-in handbook: `97c5d804c42c7742c9edfea4480163828d864279391d391df77aa60ee4a40e83`.

## Historical handbook backlog

Historical candidates: 29; differing: 26; ledger-dispositioned: 26; unresolved: 0.
No unresolved candidate content is present.

## CTO action queue

Review the structured report and employee narratives before the next paid cycle.

## Evidence index

- Structured run or phase report: `report.json`
- Raw employee sessions and structured worker reports: `workers/`
- Factory improvement handoff: `CTO-IMPROVEMENT.md` status: `pending-validation`
