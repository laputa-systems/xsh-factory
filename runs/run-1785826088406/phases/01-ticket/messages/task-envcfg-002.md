# Controller-assigned engineer ticket

This is an immutable controller assignment for one implementation worker.
The controller, not the worker, selected the ticket, snapshot, worktree, and
branch.

## Assignment authority

- Ticket ID: `task-envcfg-002`
- Ticket snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785826088406/phases/01-ticket/tickets/task-envcfg-002.md`
- Ticket snapshot SHA-256: `90657f911deb6a976cead541a5762f07772c5a6cec682fc1ed3f91b799936e2a`
- Dedicated XSH worktree: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785826088406/phases/01-ticket/worktrees/task-envcfg-002`
- Branch: `factory/task-envcfg-002/1785826089064`
- XSH base commit: `97edb51c621260d61a00034ea7ed0742adacbb80`
- engineer report: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785826088406/phases/01-ticket/workers/engineer/task-envcfg-002/REPORT.md`
- Factory root: `/Users/josh/d/laputa-systems/xsh-factory`
- Run evidence root: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785826088406/phases/01-ticket`

You are an implementation worker, not a ticket selector. Implement only the
ticket identified above and inlined below. Do not search for open tickets,
choose another ticket, or broaden this assignment. Do not create or modify a
ticket assignment. If the ticket ID, worktree, branch, or snapshot is missing
or conflicts with the runner's `FACTORY_TICKET_ID` or `FACTORY_WORKDIR`, stop
and report the assignment problem; do not guess.

The snapshot path is retained for provenance. The inlined snapshot below is
the controller's authoritative task input, so no ticket-discovery read is
required. Relative links in that snapshot resolve from the factory root above,
not from the XSH product worktree; use exact paths under that root if linked
evidence needs to be consulted.

## Ticket snapshot

<!-- CONTROLLER_TICKET_SNAPSHOT_BEGIN -->
# Ticket task-envcfg-002

## Status

Approved.

## CTO review

- Review cycle: `runs/run-1785821597944`.
- Decision: Approved for the next organization cycle.
- Basis: The linked replay reproduced a general discoverability defect: the
  newly implemented `fail(message)` primitive is absent from the authoritative
  `xsht api` registry, causing an eval agent to fall back to the sentinel
  conversion the parent ticket was meant to remove.
- Assignment boundary: Register `fail(message)` in the canonical API reference
  and add focused registry/API coverage. Do not change fail semantics,
  validator strictness, or unrelated handbook/operator guidance.

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-envcfg`
- Shared handbook lineage: `runs/run-1785821597944/phases/02-reeval-task-envcfg-001/lineage/handbook-approved.md` (snapshot `97c5d804c42c7742c9edfea4480163828d864279391d391df77aa60ee4a40e83`); candidate `handbook-candidate.md`
- Manager run: `runs/run-1785821597944/phases/02-reeval-task-envcfg-001/workers/eval-manager/task-envcfg/REPORT.md`
- Executor run: `runs/run-1785821597944/phases/02-reeval-task-envcfg-001/workers/eval-worker/task-envcfg-1/`
- XSH baseline (candidate under test) commit: `91e0eaa46014ea1dba60a5faebdead98db38cc9f`

## Observation

Candidate commit `91e0eaa` ("Add deliberate validation failure primitive")
implements a `fail(message)` keyword that constructs an `Err(Error)` validation
failure propagated by postfix `?` and exiting nonzero. In a live `task-envcfg`
eval run against that exact candidate build, the worker searched
`assert`/`expect`/`ensure`/`require`/`panic`/`invalidate`/`fail`/`Error`/`Err`/
`module:result` across turns 53-81 and could not discover any deliberate-error
primitive, then reverted to the sentinel workaround ticket `task-envcfg-001` was
created to remove:

```
if ! valid {
  let _ = "".parse_int()?
}
```

Concretely, `xsht api search:fail` (turn 54) returned only
`language.core.fallback`/`core.results`/`core.streams` (textual "fail/failure"
word matches), and `xsht api summary | grep -iE "Error|Fail|Invalid"` (turns 62,
64) surfaced no `fail` entry. The new primitive is mechanically correct but
invisible to the canonical discovery surface the handbook directs agents to use.

## Evidence

- Worker session: `runs/run-1785821597944/phases/02-reeval-task-envcfg-001/workers/eval-worker/task-envcfg-1/session.jsonl.bz2` (turns 53-81; especially turn 54 `search:fail` and turns 62/64 `summary` grep; final artifact uses the sentinel `parse_int` idiom).
- Artifact: `task-envcfg-1/envcfg.xsh` (line 7 `let _ = "".parse_int()?`).
- Evaluator: `task-envcfg-1/run.json` — `xsh_commit: 91e0eaa...`, all 10 cases pass.
- Source-level: candidate diff touches `src/runtime/eval{,/indexed/full,lower,lowered_run/indexed_run}.rs`, `src/sema/check/call.rs`, `docs/SPEC.md`, `tests/xsh/run.xsh`; it does NOT touch `crates/xsh-registry/src/reference.rs` (`CORE_LANGUAGE_ITEMS` / `core_doc`) or `XSHT-API.md`. So `fail` has no API-reference entry.

## Diagnosis or hypothesis

`xsht api` is advertised in the handbook and the `xsht api` onboarding as the
live reference for discovering exact functions, methods, and language rules. A
new runtime/sema primitive that is not registered in that reference is
indistinguishable from "not implemented" from an agent's perspective. This is a
general ergonomics defect, not a task-specific miss: any keyword/constructor
added to the language must be discoverable through the same reference or agents
will continue to route around it with opaque workarounds. It generalizes beyond
`task-envcfg` to any eval that needs a deliberate error boundary (repeat of the
original two-worker finding, which is why the primitive was created in the first
place).

## North-star impact

XSH's north star calls for structured errors and "expected failures visible."
A deliberate-failure primitive is genuinely useful, but a language feature
agents cannot discover is not learnable or ergonomic; it simply adds another
silent treadmill of turns (this run: a large fraction of a 51-turn budget) that
ends at the same hack. Registering the primitive in the API reference makes the
feature actually usable and would let an eval agent adopt `fail("...")?` directly,
which is the acceptance behavior ticket `task-envcfg-001` asked for. Evidence it
generalized: `xsht api search:fail` and `summary` then resolve, and a replay of
`task-envcfg` (plus `task-ecount`/`task-tags` style loud-exit boundaries) shows the
agent choosing `fail` over the sentinel.

## Proposed XSH change

Register the `fail` deliberate-validation primitive in the `xsht api` reference so
`xsht api search:fail` and an exact query (e.g. `api:fail` / a `core.fail`
language rule) resolve with purpose/contract/signature ("constructs a validation
`Err(Error)` propagated by `?`; exits nonzero at top level"). This is the smallest
change: one add to `crates/xsh-registry/src/reference.rs` (a `CORE_LANGUAGE_ITEMS`
entry plus `core_doc` text, mirroring `Ok`/`Err`/`results`/`postfix-question`), and
optionally a matching line in `XSHT-API.md`. Do not change the runtime or the
semantics of `fail`.

## Acceptance criteria

- `xsht api search:fail` returns an exact entry describing the `fail(message)`
  deliberate-validation primitive (not merely "fallback"/"results" word matches).
- An agent can discover `fail` from the reference alone and write
  `fail("message")?` in an `if`/guard that passes `xsht check`/`lint` and exits
  nonzero with no output file.
- The `task-envcfg` malformed and empty-port failure controls still pass.
- The existing native test `test_fail_constructor_propagates_validation_error`
  still passes.

## Scope and non-goals

- Out of scope: changing `fail` semantics, the `env.int`/`parse_int` validator
  strictness, or boolean/`&&`/`||` operator friction (separate handbook/override
  concerns).
- Out of scope: retrofitting every existing keyword into the reference in this
  ticket; the fix is scoped to making newly shipped primitives discoverable,
  demonstrated by `fail`.

## Post-merge evaluation

Replay `task-envcfg` against the merged commit and verify the eval agent adopts
`fail(...)?` (no sentinel `parse_int`) with all 10 cases and both failure
controls passing. Optionally replay `task-ecount`/`task-tags` loud-exit cases to
confirm the discoverable primitive generalizes.

<!-- CONTROLLER_TICKET_SNAPSHOT_END -->

## Factory context required before coding

The factory documents below are outside the XSH worktree. Before coding, use
the `read` tool on each exact absolute path. This is required so the session
JSONL proves that the worker consumed the current factory guidance:

- North star: `/Users/josh/d/laputa-systems/xsh-factory/NORTH-STAR.md`
- Shared handbook: `/Users/josh/d/laputa-systems/xsh-factory/runtime/handbook.md`

Then use the `read` tool on the product worktree's exact guidance files:

- Product agent guide: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785826088406/phases/01-ticket/worktrees/task-envcfg-002/AGENTS.md`
- XSH rationale: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785826088406/phases/01-ticket/worktrees/task-envcfg-002/docs/CHAPTER-01-why-xsh.md`

## Implementation contract

Work only in `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785826088406/phases/01-ticket/worktrees/task-envcfg-002` on branch `factory/task-envcfg-002/1785826089064`. Do not edit XSH main, the
factory main tree, or the ticket diagnosis. Make the smallest general XSH
language, tooling, test, or canonical-documentation change supported by the
ticket. Run the narrowest relevant checks, commit the product change on this
branch, and leave the worktree clean.

The controller has staged a fail-closed `not-ready` report at
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785826088406/phases/01-ticket/workers/engineer/task-envcfg-002/REPORT.md`. Complete that file in place; do not spend turns
reconstructing its headings. Keep `## Result` as `not-ready` until the
acceptance checks, commit, and clean-worktree validation are complete.

Write `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785826088406/phases/01-ticket/workers/engineer/task-envcfg-002/REPORT.md` with these exact headings:

```markdown
## Result

ready-for-review

## Branch

<branch name>

## Commit

<commit hash>

## Files changed

<short list>

## Tests

<commands and results>

## North-star impact

<how this improves XSH or agent use>

## Remaining risks

<known limitations, or None.>
```

Change `## Result` to `ready-for-review` only when the branch is committed, the worktree is
clean, and the relevant checks passed. Do not merge the branch or update the
ticket status; the deterministic controller records it for CTO review.
