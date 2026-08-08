# Controller-assigned engineer ticket

This is an immutable controller assignment for one implementation worker.
The controller, not the worker, selected the ticket, snapshot, worktree, and
branch.

## Assignment authority

- Ticket ID: `task-dupcheck-002`
- Ticket snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786201137236/phases/01-ticket/tickets/task-dupcheck-002.md`
- Ticket snapshot SHA-256: `a1053fb9ae0414ef5fcb4fa892e0baeb57f66e645f52bdd15243d437a402b60c`
- Dedicated XSH worktree: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786201137236/task-dupcheck-002`
- Branch: `factory/task-dupcheck-002/1786201139234`
- XSH base commit: `c77b01a3e2fb676cc57cdeddbb7575be7723aa32`
- engineer report: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786201137236/phases/01-ticket/workers/engineer/task-dupcheck-002/REPORT.md`
- Factory root: `/Users/josh/d/laputa-systems/xsh-factory`
- Run evidence root: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786201137236/phases/01-ticket`

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
# Ticket task-dupcheck-002

## Status

Approved.

## CTO decision — cycle-17 close

- Decision: Approved for implementation in cycle 18.
- Basis: The original `task-dupcheck` trial produced a reproducible,
  cross-probe mismatch between `xsht api` defaulted-parameter signatures and
  positional-only call syntax. The ticket has a narrow documentation/reference
  remedy, an explicit API-surface justification, and a linked acceptance
  replay. The evidence is present in the checked-in run, and the queue has no
  other fresh approved product row.
- Scope: Implement the smallest honest `xsht api` signature/contract wording
  change; do not add named-argument grammar. The linked replay must confirm
  existing positional calls and the independent histogram eval must remain
  green.
- Evidence: `runs/run-1786128115649/phases/03-eval/workers/eval-manager/task-dupcheck/REPORT.md`
  and `runs/run-1786128115649/phases/03-eval/workers/eval-worker/task-dupcheck-1/run.json`.

## CTO review

- Review cycle: run-1786128115649.
- Decision: Deferred; do not approve or dispatch.
- Basis: The named-argument/signature mismatch is reproducible and general,
  but this is one fresh eval. The manager requires replay of `task-dupcheck`
  plus a second defaulted-parameter eval before promotion of the handbook
  candidate or engineer admission. Preserve the Open observation while the
  current approved histogram implementation remains in branch review.
- Evidence: `runs/run-1786128115649/phases/03-eval/workers/eval-manager/task-dupcheck/REPORT.md`
  and `runs/run-1786128115649/phases/03-eval/workers/eval-worker/task-dupcheck-1/run.json`.

## Change target

- `product`

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-dupcheck`
- Shared handbook lineage: `runs/run-1786128115649/phases/03-eval/lineage/handbook-approved.md`
- Manager run: `runs/run-1786128115649/phases/03-eval/workers/eval-manager/task-dupcheck/`
- Executor run: `runs/run-1786128115649/phases/03-eval/workers/eval-worker/task-dupcheck-1/`
- XSH baseline commit: `1477f472d5b4d57db3584357116ef97c32358ab6`

## Observation

During a clean, all-eight-case passing `task-dupcheck` trial, the eval-worker
found that `xsht api` renders module-function signatures that invite
named-argument call syntax which the parser rejects. `xsht api api:fs.files`
prints:

```
api: module.fs.files
signature: fs.files(path: Path, gitignore: Bool = default, stat: Bool = default, exts: List[Str] = default, hidden: Bool = default)
```

The `name: Type = default` rendering strongly implies that `name = value`
named arguments are accepted. The worker tried `fs.files(root, hidden = true)?`
and `fs.files(root, hidden=true)?`, each producing the parse error
`expected ')' after call arguments`, and reproduced it standalone
(`/tmp/named.xsh`) without the postfix `?`:

```
let f = fs.files(p"/tmp/example", hidden = true)
                                       ^ expected `)` after call arguments
```

Function calls are positional-only in this build; a defaulted parameter can
only be overridden by supplying values positionally in signature order
(verified: `fs.files(root, false, false, [], true)` enables hidden traversal).
The rendered signature does not communicate that positional-only constraint,
so any agent that reads the signature and tries the natural named spelling
spends extra turns on parse errors.

## Evidence

- Session transcript `task-dupcheck-1/session.jsonl.bz2` turns 22, 24, 46: repeated
  `expected ')' after call arguments` parse errors for `hidden = true`,
  `hidden=true`, and the standalone `named.xsh` probe.
- Worker review `task-dupcheck-1/review.md` records the friction and the
  verified positional spelling `fs.files(root, false, false, [], true)`.
- Final artifact `task-dupcheck-1/dupcheck.xsh` uses the positional spelling
  and passes all eight cases against the BusyBox oracle (`run.json`
  `correctness.all_exact = true`).

## Diagnosis or hypothesis

This is a general XSH tooling/ergonomics surface problem, not task-specific
confusion. `xsht api` is the documented live reference for function contracts,
and any eval whose program calls a module function with defaulted parameters
(fs.files, fs.walk, env helpers, and others) can hit the same wall: the
rendered signature reads like labeled/named parameters, but the parser is
positional-only. The mismatch is deterministic and reproducible across two
independent probes in this session. Resolving it improves agent ergonomics
("fewer guesses, workarounds, tool errors, and repeated discoveries") for the
whole factory, not just task-dupcheck.

## North-star impact

The XSH rationale names ergonomics and honest, explicit boundaries as first
priorities. A reference surface that displays `name: Type = default` but
rejects `name = value` is a boundary that misleads the reader. Either accepting
named/optional arguments (so the displayed signature is honest) or rendering
the positional-only constraint plainly would remove a repeated-discovery class
across evals. Evidence of generalization: the same parse error stops occurring
in other evals that call defaulted-parameter module functions, confirmed by
replay of a second eval against the merged change.

## Proposed XSH change

Two candidate directions, smallest-surface first:

1. Make the rendered signature honest about positional-only calling, e.g. print
   `fs.files(path: Path, gitignore: Bool, stat: Bool, exts: List[Str], hidden: Bool)` with a note that `= default` marks an omit-able value and that calls
   are positional-only, so an agent reading the reference does not try invalid
   named syntax.
2. Alternatively, accept named/optional arguments in call position so the
   displayed signature is literally true.

## API-surface justification

Existing position-only calls already express everything this task needs, so the
capability gap is a documentation/ergonomics mismatch at the `xsht api`
surface, not a missing behavior. Option 1 adds no grammar surface and only
changes how signatures/contracts are rendered; Option 2 adds named-argument
syntax, which is a larger grammar/checker change and must be justified against
the positional-only design. Evidence from the linked `task-dupcheck` trial
supports the smaller reference-only remedy. The manager proposes Option 1 as the
minimal-surface fix and recommends it for the ticket.

## Proposed XSH change

Clarify the `xsht api` signature rendering so a defaulted parameter is not
displayed in a way that implies `name = value` named-argument support, or
otherwise state positional-only calling in the rendered contract. No language
semantics change is claimed here.

## Acceptance criteria

- `xsht api api:fs.files` (and any other signature with `= default` params)
  renders in a way that does not read as named-argument support, or documents
  positional-only calling explicitly.
- A fresh task-dupcheck trial (or a focused probe) no longer attempts named
  arguments after reading the rendered signature.
- Existing positional calls (e.g. `fs.files(root, false, false, [], true)`)
  still parse and pass the eight-case oracle.

## Scope and non-goals

- No change to the task contract, fixture cases, or evals.
- No provider/fallback change.
- If Option 2 (named arguments) is chosen, that is a separate, larger
  admission and must be justified on its own.

## Post-merge evaluation

Replay `task-dupcheck` and one other eval that calls a defaulted-parameter
module function against the merged build; the eval-manager records whether any
agent still attempts invalid `name = value` calls after reading the reference.

<!-- CONTROLLER_TICKET_SNAPSHOT_END -->

## Factory context required before coding

The factory documents below are outside the XSH worktree. Before coding, use
the `read` tool on each exact absolute path. This is required so the session
JSONL proves that the worker consumed the current factory guidance:

- North star: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786201137236/phases/01-ticket/guidance/NORTH-STAR.md`
- Approved handbook snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786201137236/phases/01-ticket/guidance/handbook.md`
- Handbook candidate: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786201137236/phases/01-ticket/lineage/handbook-candidate.md`

The approved snapshot is a run-scoped copy of the checked-in handbook. Read it
as an input and never edit it or the checked-in handbook. If this ticket
produces a reusable lesson, add it to the run-scoped candidate path above; the
candidate is shared review input and is promoted only after CTO review. If no
handbook improvement is justified, leave the candidate unchanged.

Then use the `read` tool on the product worktree's exact guidance files:

- Product agent guide: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786201137236/task-dupcheck-002/AGENTS.md`
- XSH rationale: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786201137236/task-dupcheck-002/docs/CHAPTER-01-why-xsh.md`

## Implementation contract

Work only in `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786201137236/task-dupcheck-002` on branch `factory/task-dupcheck-002/1786201139234`. Do not edit XSH main, the
factory checkout, the approved handbook snapshot, or the ticket diagnosis.
Make the smallest general XSH language, tooling, test, or
canonical-documentation change supported by the ticket. Run the narrowest
relevant checks, commit the product change on this branch, and leave the
worktree clean.

For ordinary product tickets, use `xsht lint --fix` for linting, then rerun the
relevant checks. If this ticket specifically targets lint, parsing, or
diagnostics, preserve the behavior under test and follow its explicit
acceptance procedure instead of auto-fixing away the evidence.

The controller has staged a fail-closed `not-ready` report at
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786201137236/phases/01-ticket/workers/engineer/task-dupcheck-002/REPORT.md`. Complete that file in place; do not spend turns
reconstructing its headings. Keep `## Result` as `not-ready` until the
acceptance checks, commit, and clean-worktree validation are complete.

Write `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786201137236/phases/01-ticket/workers/engineer/task-dupcheck-002/REPORT.md` with these exact headings:

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
