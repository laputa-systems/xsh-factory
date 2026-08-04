# Ticket task-envcfg-002

## Status

Closed.

## CTO review

- Review cycle: `runs/run-1785821597944`.
- Decision: Approved for the next organization cycle.
- Supersession note: This ticket is now Closed. The registered `fail` API was
  reverted with XSH commits `38adfb0` and `a67599b` after CTO review found no
  semantic justification for the underlying new primitive. See
  `runs/run-1785876949561/` and `tickets/task-envcfg-001.md`.
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

- Worker session: `runs/run-1785821597944/phases/02-reeval-task-envcfg-001/workers/eval-worker/task-envcfg-1/session.jsonl` (turns 53-81; especially turn 54 `search:fail` and turns 62/64 `summary` grep; final artifact uses the sentinel `parse_int` idiom).
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
