# Controller-assigned engineer ticket

This is an immutable controller assignment for one implementation worker.
The controller, not the worker, selected the ticket, snapshot, worktree, and
branch.

## Assignment authority

- Ticket ID: `task-envcfg-009`
- Ticket snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786257836059/phases/01-ticket/tickets/task-envcfg-009.md`
- Ticket snapshot SHA-256: `e76f9f62970b8188a33376daad06759a2a409e9675a5da0821a45d384985d51e`
- Dedicated XSH worktree: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786257836059/task-envcfg-009`
- Branch: `factory/task-envcfg-009/1786257843378`
- XSH base commit: `7b4bee1a1cef74fed832331cd6cc5bb6e324c4ee`
- engineer report: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786257836059/phases/01-ticket/workers/engineer/task-envcfg-009/REPORT.md`
- Factory root: `/Users/josh/d/laputa-systems/xsh-factory`
- Run evidence root: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786257836059/phases/01-ticket`

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
# Ticket task-envcfg-009

## Status

Approved.

## Change target

- `product`

## CTO review

- Review cycle: `runs/run-1786255756177` closeout (2026-08-08).
- Decision: Approved as the scoped successor to closed `task-envcfg-008`.
- Basis: `error.fail(message)` is specified, lowered, and natively tested, but
  canonical API registration makes `error` a standard-module name. The product
  contains 609 established local bindings named `error`; rejecting each would
  be a broad, unrelated source migration. The recorded candidate proved the
  registry and linked replay behavior, but its silent checker exception was
  outside the prior ticket's reference-only contract. This ticket makes the
  compatibility rule, specification, and regression coverage explicit.
- Duplicate review: this supersedes only the closed reference-only
  `task-envcfg-008`; it is not a second spelling, new error mechanism, or
  replacement for the existing `args` exception.
- Assignment boundary: expose only the existing `error.fail` operation and
  define `error` as a documented local-binding compatibility exception. Keep
  all runtime, lowering, Result, error-kind, and syntax behavior unchanged.

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `7b4bee1a1cef74fed832331cd6cc5bb6e324c4ee`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-envcfg` (`evals/task-envcfg/EVAL.md`)
- Shared handbook lineage:
  `runs/run-1786255756177/phases/02-reeval-task-envcfg-008/lineage/handbook-approved.md`
  (`c1295e0ad1caaf0387c18293b8be7c79ebf567afd45154d4850912f686783618`)
- Manager run:
  `runs/run-1786255756177/phases/02-reeval-task-envcfg-008/workers/eval-manager/task-envcfg/REPORT.attempt-1.md`
- Executor run:
  `runs/run-1786255756177/phases/02-reeval-task-envcfg-008/workers/eval-worker/task-envcfg-1/run.json`
- XSH baseline commit: `7b4bee1a1cef74fed832331cd6cc5bb6e324c4ee`

## Observation

The candidate build recorded an exact `xsht api api:error.fail` result and a
passing package-owned replay gate, but registering that existing runtime module
caused the standard-module-shadow checker to reject the product's widespread
local `error` result bindings. The candidate preserved those bindings by adding
an undocumented exception; the specification currently documents only `args`.

## Evidence

- `runs/run-1786255756177/phases/01-ticket/workers/engineer/task-envcfg-008/REPORT.md`
  and provenance event `75-ticket-task-envcfg-008-provenance` record the
  candidate and its focused checks.
- `runs/run-1786255756177/phases/02-reeval-task-envcfg-008/workers/eval-worker/task-envcfg-1/run.json`
  records all ten task cases and the `error_fail_reference_required/passed`
  gate as `true`.
- Candidate commit `b9ddeadc3dcc6e51ecd3d1d81aa8675066d2c7a3` adds `error` to
  the registry and shows the two necessary checker sites. `rg` over product
  source found 609 existing local `error` bindings.
- `docs/SPEC.md` lines 295–304 define registry module names as reserved and
  document the sole `args` exception.

## Diagnosis or hypothesis

The API registry is the authoritative discoverability and standard-module
contract. Adding an existing runtime module to it must either reserve a name
or explicitly preserve compatible local bindings. `error` is the conventional
payload name for `Err(error)` matches, so a silent exception would make the
language contract misleading while a wholesale rename is disproportionate.
A documented, regression-tested exception is the smallest durable policy.

## North-star impact

Agents can discover and use the existing deliberate-validation operation with
an exact API query, while existing programs retain their ordinary error-result
bindings. Making the tradeoff explicit prevents a reference improvement from
quietly changing language validity and gives future standard-module additions
a clear compatibility precedent.

## API-surface justification

No builtin, keyword, constructor, type, method, or syntax form is added.
`error.fail(message)` already exists with its current Result and error-effect
contract. The only language-policy change is whether the already conventional
identifier `error` may remain a local binding after the existing module becomes
registry-visible. Existing `Err(error)` patterns are not a competing API or
desugaring; preserving them is a compatibility rule, not a new spelling.

## Proposed XSH change

Register the existing `error.fail(message)` module function in the canonical
API registry and documentation. Make `error`, like the already documented
`args` exception, legal in ordinary local binding positions; update
`docs/SPEC.md` to name its distinct rationale. Add focused API and checker
regressions that prove both the exact reference and local-binding behavior.

## Acceptance criteria

- `xsht api api:error.fail` returns an exact entry with the existing validation
  Result and error-effect contract; `xsht api search:fail` includes it.
- `docs/SPEC.md` documents why local `error` bindings remain legal while other
  registry module names stay reserved.
- Focused product tests prove an ordinary local `error` binding remains valid
  and an unshadowed `error.fail(...)` call keeps its existing effect contract.
- No runtime, lowering, error-kind, Result, parser, or syntax behavior changes.
- The package-owned `task-envcfg-009` replay gate passes all ten config cases
  and records the exact `error.fail` API reference as passed.
- `cargo build -p xsht --bin xsht` and `target/debug/xsht lint --fix` leave the
  candidate worktree clean.

## Scope and non-goals

- No bare `Error(...)`, `fail(...)`, or second deliberate-failure spelling.
- No general relaxation for other standard-module names.
- No broad source rename of current local `error` bindings.
- No task-envcfg behavior change beyond the package-owned reference gate.

## Post-merge evaluation

Run the controller-owned linked `task-envcfg` replay for `task-envcfg-009`.
The evaluator must resolve the exact API reference and preserve all ten config
cases; the eval-manager must record `Candidate acceptance: pass.` before the
organization controller may merge the provenance commit.

<!-- CONTROLLER_TICKET_SNAPSHOT_END -->

## Factory context required before coding

The factory documents below are outside the XSH worktree. Before coding, use
the `read` tool on each exact absolute path. This is required so the session
JSONL proves that the worker consumed the current factory guidance:

- North star: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786257836059/phases/01-ticket/guidance/NORTH-STAR.md`
- Approved handbook snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786257836059/phases/01-ticket/guidance/handbook.md`
- Handbook candidate: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786257836059/phases/01-ticket/lineage/handbook-candidate.md`

The approved snapshot is a run-scoped copy of the checked-in handbook. Read it
as an input and never edit it or the checked-in handbook. If this ticket
produces a reusable lesson, add it to the run-scoped candidate path above; the
candidate is shared review input and is promoted only after CTO review. If no
handbook improvement is justified, leave the candidate unchanged.

Then use the `read` tool on the product worktree's exact guidance files:

- Product agent guide: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786257836059/task-envcfg-009/AGENTS.md`
- XSH rationale: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786257836059/task-envcfg-009/docs/CHAPTER-01-why-xsh.md`

## Implementation contract

Work only in `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786257836059/task-envcfg-009` on branch `factory/task-envcfg-009/1786257843378`. Do not edit XSH main, the
factory checkout, the approved handbook snapshot, or the ticket diagnosis.
Make the smallest general XSH language, tooling, test, or
canonical-documentation change supported by the ticket. Run the narrowest
relevant checks, commit the product change on this branch, and leave the
worktree clean.

The CTO, through the ticket controller, owns the required candidate-hygiene
sequence. After you commit and leave this worktree clean, the controller runs:

```sh
cargo build -p xsht --bin xsht
target/debug/xsht lint --fix
```

Do not run a broad autofixer yourself. The controller records both command
streams before provenance and accepts the candidate only when the second
command leaves the worktree clean. If it changes tracked source, the
controller captures a portable hygiene patch and fails the candidate rather
than changing XSH `HEAD` after linked replay.

The controller has staged a fail-closed `not-ready` report at
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786257836059/phases/01-ticket/workers/engineer/task-envcfg-009/REPORT.md`. Complete that file in place; do not spend turns
reconstructing its headings. Keep `## Result` as `not-ready` until the
acceptance checks, commit, and clean-worktree validation are complete.

Write `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786257836059/phases/01-ticket/workers/engineer/task-envcfg-009/REPORT.md` with these exact headings:

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
