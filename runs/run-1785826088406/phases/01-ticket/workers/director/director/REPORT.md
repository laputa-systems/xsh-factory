# Director report

## Result

pass

## Cycle

Mode: `ticket-implementation`. The controller admitted one approved ticket,
`task-envcfg-002` (eval `task-envcfg`), created its isolated worktree on branch
`factory/task-envcfg-002/1785826089064`, and launched the single assigned
engineer row concurrently through the shared runner. This director session
reconciled the completed worker report only; no engineers or eval roles were
launched here. XSH main commit resolved and preserved for this cycle:
`97edb51c621260d61a00034ea7ed0742adacbb80`.

The ticket scoped one change: register the `fail(message)` deliberate
validation-failure primitive in the canonical `xsht api` registry (the
`CORE_LANGUAGE_ITEMS`/`core_doc` in `crates/xsh-registry/src/reference.rs`)
plus focused registry/API coverage, without altering `fail` semantics.

## Children

- `task-envcfg-002` (engineer, worker_id `task-envcfg-002`): **pass** —
  worker `report.json` result `pass`; narrative `REPORT.md` `ready-for-review`.
  Evidence: `runs/run-1785826088406/phases/01-ticket/workers/engineer/task-envcfg-002/`.

## Required-output status

Controller-required output (director reconciliation report) versus the fail-closed
skeleton: the pre-staged `## Result` was `not-ready` until the single dispatched
row was reconciled; now completed as `pass`.

Engineer deliverable on the admitted ticket:
- Branch `factory/task-envcfg-002/1785826089064`, commit `6def20b9b0f0a2acdcb3373ddafb243ab9d824b1` ("Register fail primitive in API reference"), worktree working tree clean. Verified present and on-branch.
- Diff touches `crates/xsh-registry/src/reference.rs` (+10) and `crates/xsht/tests/api.rs` (+38), matching the ticket scope. No runtime/sema/validator changes.

Ticket acceptance criteria (verified from the committed worktree build):
- `xsht api search:fail` now returns an exact `language.core.fail` entry (not merely `fallback`/`results` word matches). **Present.**
- Exact `xsht api language:core.fail` resolves with purpose, contract, effects, signature, tags describing `fail(message)` → `Result[Unit, Error]`, propagated by `?`, exiting nonzero at top level. **Valid.**
- The existing native test `test_fail_constructor_propagates_validation_error` and the `task-envcfg` failure controls remain covered (engineer reports `cargo test -p xsh --lib modules::signature`, `-p xsht --test api`, and `-p xsh-registry --lib` all pass; no validator-strictness or operator changes). **Valid.**

Cost/effort: 28 assistant turns, 2 tool errors (both non-fatal, resolved: one `bash` non-zero-exit probe at turn 16, one non-unique `edit` anchor at turn 20), session span ~230s, cost ~$0.031. No budget breach, session limit watcher pass, agent process pass.

## North-star impact

This cycle turns a previously reproduced discoverability defect into durable,
merged-ready product evidence rather than a task workaround. The parent replay
(`run-1785821597944`) showed that a newly shipped `fail` primitive was
mechanically correct yet invisible to `xsht api`, so an agent burned many turns
and fell back to the sentinel `parse_int` hack the ticket was created to remove.
Registering `language.core.fail` in the canonical registry restores the
language's central promise — "expected failures visible" and discoverable —
so both people and agents can use structured `fail(message)?` instead of opaque
host-operation workarounds. This is a general ergonomics/learnability
improvement, not a task-specific fix: it establishes that any keyword/constructor
added to the runtime must be registered in the same reference surface or it is
indistinguishable from "not implemented."

Uncertainty: the change is verified at the reference/build level and against the
native registry/API tests, but it is not yet confirmed end-to-end that an eval
agent will now choose `fail(...)?` over the sentinel. That is the claim the
linked manager replay after CTO merge must test (per the ticket's post-merge
evaluation: replay `task-envcfg` and confirm adoption of `fail` with all 10
cases and both failure controls). The implementation branch remains pending CTO
review; merge was not performed in this cycle.
