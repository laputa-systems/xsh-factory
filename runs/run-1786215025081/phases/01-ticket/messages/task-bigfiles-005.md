# Controller-assigned engineer ticket

This is an immutable controller assignment for one implementation worker.
The controller, not the worker, selected the ticket, snapshot, worktree, and
branch.

## Assignment authority

- Ticket ID: `task-bigfiles-005`
- Ticket snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786215025081/phases/01-ticket/tickets/task-bigfiles-005.md`
- Ticket snapshot SHA-256: `e53240c4a830c4441a0c90ffc1ef83b141d1c56bd2fc9956d7c0d02068de1784`
- Dedicated XSH worktree: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786215025081/task-bigfiles-005`
- Branch: `factory/task-bigfiles-005/1786215040119`
- XSH base commit: `26d59eb844b670365931d91ffb15ae8c109bae12`
- engineer report: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786215025081/phases/01-ticket/workers/engineer/task-bigfiles-005/REPORT.md`
- Factory root: `/Users/josh/d/laputa-systems/xsh-factory`
- Run evidence root: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786215025081/phases/01-ticket`

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
# Ticket task-bigfiles-005

## Status

Approved.

## CTO review — cycle 26 close

- Decision: Approved for controlled implementation in the next organization
  cycle.
- Basis: The independent `task-bigfiles` eval passed all nine cases with zero
  tool errors, and its manager recorded a reproducible strict-decimal parsing
  gap that generalizes to counts, sizes, and ports. The next engineer must
  implement only the smallest strict-decimal surface and retain the linked
  replay as a hard gate.
- Scope guard: do not change the default lenient `parse_int`, eval oracle, or
  evaluator restrictions; preserve the existing `Result`/`?` failure path.

## Change target

- `product`

Factory changes are CTO-owned. Do not create a factory-target ticket for
engineer dispatch; report the infrastructure change to the CTO instead.

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-bigfiles`
- Shared handbook lineage: `runs/run-1786212430316/phases/03-eval/lineage/handbook-approved.md`
- Manager run: `runs/run-1786212430316/phases/03-eval/workers/eval-manager/task-bigfiles/REPORT.md`
- Executor run: `runs/run-1786212430316/phases/03-eval/workers/eval-worker/task-bigfiles-1/`
- XSH baseline commit: `26d59eb844b670365931d91ffb15ae8c109bae12`

## Observation

`task-bigfiles` requires `N` to be a strict decimal integer and the program
to exit nonzero (printing nothing) when it is not. The eval-worker found that
`Str.parse_int()` is not a strict decimal parser: it also accepts hex
(`0x10`), a leading `+`/`-`, surrounding whitespace, and leading zeros. The
build has no generic `Error(...)` constructor. To satisfy the byte-exact
decimal `N` gate, the worker had to (a) run a separate digit-only check
(`raw.delete("0123456789") == "" and raw != ""`) and (b) force a failure by
feeding a provably invalid literal to `parse_int("invalid")?`. The final
artifact `bigfiles.xsh` relies on this two-step force-invalid-string
workaround.

## Evidence

- Executor run manifest `runs/run-1786212430316/phases/03-eval/workers/eval-worker/task-bigfiles-1/run.json`:
  all nine cases byte-exact; `hidden_bad_n` (N=`abc`) exits nonzero (3) and
  prints nothing, matching the failure gate.
- Final artifact `/work/bigfiles.xsh` shows the digit-only check paired with
  `parse_int()` on a sentinel invalid string.
- Worker `review.md` `## XSH language proposals` documents: "`Str.parse_int()`
  is not a purely decimal parser: it also accepts hex..., a leading `+`/`-`,
  surrounding whitespace, and leading zeros. For a contract that requires
  strict decimal-digit input, there is no decimal-only parse primitive and no
  generic `Error(...)` constructor, so the program must separately run a
  digit-only check ... and force a failure by feeding a provably-invalid
  string to `parse_int()?`."
- Worker `report.json`: 31 turns, 0 tool errors, 20 thinking blocks.

## Diagnosis or hypothesis

This is a general XSH ergonomics/correctness problem, not task-specific
confusion. Byte-exact decimal contracts (counts, port numbers, byte sizes,
indices) recur across evals and real systems-glue programs, and a lenient
`parse_int` that silently accepts hex/sign/whitespace/leading-zeros gives a
plausible-but-wrong value whenever a caller wanted strict decimal validation.
Because there is no decimal-only Result-returning primitive and no generic
error constructor, the only way to both validate and fail loudly is an opaque
force-invalid-string hack. That hack couples a validation check to an
intentionally-invalid literal, which is exactly the kind of incantation the
north-star rejects. The capability — "parse this string as a strict decimal
integer, returning a Result that `?` can propagate" — currently cannot be
expressed in one typed call.

## North-star impact

A strict decimal parse (a Result-returning `parse_int_decimal()` or an
explicit `radix:` parameter that rejects hex/sign/whitespace/leading-zeros)
lets byte-exact numeric contracts be validated and fail loudly in a single
typed call, removing the force-invalid-string workaround. This advances
explicit, trustworthy, ergonomic boundaries. Evidence it generalized: any later
eval or user program that must reject a non-decimal count/port/size reaches the
strict validation without hand-rolling a digit check plus a sentinel-invalid
string, and the failure still exits nonzero and prints nothing.

## Proposed XSH change
## API-surface justification

- Semantic capability gap: there is no way to parse a `Str` as a strict
  decimal integer and receive a `Result` that rejects hex, sign, whitespace,
  and leading zeros — the common byte-exact numeric contract.
- Closest existing spelling and why insufficient: `Str.parse_int()` exists but
  is lenient (hex/sign/whitespace/leading-zeros), so it cannot express a
  strict-decimal contract by itself.
- Smaller-surface alternatives: a `radix:` parameter on the existing parse is
  the smallest surface (no new builtin keyword or type); a separate
  `parse_int_decimal()` method is the next-smallest. Both keep the Result/`?`
  failure idiom already in the handbook. A desugaring or type rule would not
  help because the gap is runtime parsing strictness, not syntax.
- Implementation and maintenance cost: a `radix` parameter (or a decimal-only
  method) in the Str parse registry, the runtime parser, the `xsht api`
  registry entry, documentation, and focused native tests for hex/sign/
  whitespace/leading-zero rejection — all bounded to the existing parse path.
- Evidence and falsification replay: the linked `task-bigfiles` failure control
  (`hidden_bad_n` nonzero) plus a strict-decimal parse test asserting `0x10`,
  `+5`, ` 5 `, and `05` are rejected.

An ergonomic shortcut that merely gives a second spelling to an existing
operation is not sufficient justification for product admission.

## Proposed XSH change

Add a strict-decimal parse to `Str` (smallest surface first: a `radix:`
parameter defaulting to the current behavior, or a dedicated
`parse_int_decimal()` that rejects hex, `+`/`-`, whitespace, and leading
zeros) that returns a `Result` so postfix `?` propagates a nonzero exit for
non-decimal input. Do not claim the change is implemented.

## Acceptance criteria

- `parse_int("0x10")`, `parse_int("+5")`, `parse_int(" 5 ")`, and
  `parse_int("05")` are rejected by the strict decimal surface (or an
  explicit `radix:` is required for non-decimal), while `parse_int("5")`
  succeeds.
- The failure path returns a `Result` so `?` produces a nonzero exit and no
  stdout, matching `task-bigfiles hidden_bad_n`.
- A replay of `task-bigfiles` expresses the `N` validation with a single typed
  strict-decimal call (no separate digit-check plus force-invalid-string) and
  all nine cases remain byte-exact.

## Scope and non-goals

Out of scope: changing the eval, evaluator, or harness; recommending provider
changes; altering the default behavior of the existing lenient `parse_int`
when no explicit strict/radix form is requested.

## Post-merge evaluation

A `task-bigfiles` replay at the merged XSH commit that checks the worker
selects the strict-decimal surface from the API reference, removes the
force-invalid-string hack, and keeps `hidden_bad_n` exit-nonzero/print-nothing
while all nine cases stay byte-exact.

<!-- CONTROLLER_TICKET_SNAPSHOT_END -->

## Factory context required before coding

The factory documents below are outside the XSH worktree. Before coding, use
the `read` tool on each exact absolute path. This is required so the session
JSONL proves that the worker consumed the current factory guidance:

- North star: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786215025081/phases/01-ticket/guidance/NORTH-STAR.md`
- Approved handbook snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786215025081/phases/01-ticket/guidance/handbook.md`
- Handbook candidate: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786215025081/phases/01-ticket/lineage/handbook-candidate.md`

The approved snapshot is a run-scoped copy of the checked-in handbook. Read it
as an input and never edit it or the checked-in handbook. If this ticket
produces a reusable lesson, add it to the run-scoped candidate path above; the
candidate is shared review input and is promoted only after CTO review. If no
handbook improvement is justified, leave the candidate unchanged.

Then use the `read` tool on the product worktree's exact guidance files:

- Product agent guide: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786215025081/task-bigfiles-005/AGENTS.md`
- XSH rationale: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786215025081/task-bigfiles-005/docs/CHAPTER-01-why-xsh.md`

## Implementation contract

Work only in `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786215025081/task-bigfiles-005` on branch `factory/task-bigfiles-005/1786215040119`. Do not edit XSH main, the
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
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786215025081/phases/01-ticket/workers/engineer/task-bigfiles-005/REPORT.md`. Complete that file in place; do not spend turns
reconstructing its headings. Keep `## Result` as `not-ready` until the
acceptance checks, commit, and clean-worktree validation are complete.

Write `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786215025081/phases/01-ticket/workers/engineer/task-bigfiles-005/REPORT.md` with these exact headings:

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
