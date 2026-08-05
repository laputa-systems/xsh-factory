# Controller-assigned engineer ticket

This is an immutable controller assignment for one implementation worker.
The controller, not the worker, selected the ticket, snapshot, worktree, and
branch.

## Assignment authority

- Ticket ID: `task-colsum-001`
- Ticket snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785894766939/phases/01-ticket/tickets/task-colsum-001.md`
- Ticket snapshot SHA-256: `842852e90f92f3a17d5f3fcc64bcce2575eb5528e06a6edeaece614c1be9a380`
- Dedicated XSH worktree: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785894766939/phases/01-ticket/worktrees/task-colsum-001`
- Branch: `factory/task-colsum-001/1785894767724`
- XSH base commit: `e5d29c7ec8b4411dc749fd3e44bf472d641ad9f4`
- engineer report: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785894766939/phases/01-ticket/workers/engineer/task-colsum-001/REPORT.md`
- Factory root: `/Users/josh/d/laputa-systems/xsh-factory`
- Run evidence root: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785894766939/phases/01-ticket`

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
# Ticket task-colsum-001

## Status

Approved.

## CTO decision — next organization cycle

- Review cycle: next organization cycle.
- Decision: Approved for one bounded engineer assignment.
- Basis: The current XSH `HEAD` is `e5d29c7`, where the prior `Error(kind: ...)` constructor is removed and no generic message-bearing error can be constructed without declaring a family/variant or abusing an unrelated conversion. Independent `task-envcfg` and `task-colsum` sessions reproduced the same validation-boundary gap. This is a semantic capability—direct construction of an expected validation failure—not merely a spelling change in the current product. The ticket contains the required API-surface justification and limits scope to checker/runtime/specification/tests plus linked replay.
- Assignment boundary: prefer the smallest existing declared-error or type-directed mechanism if it genuinely provides a generic message-bearing validation failure; otherwise implement the narrowest explicit form. Preserve `Err`/`Result` semantics, add canonical docs and focused tests, and do not broaden into boolean operators or unrelated APIs.
- Acceptance gate: clean portable commit, `task-colsum` replay passing all nine cases without the sentinel conversion for the missing-header branch, and independent eval manifest passing. CTO merge remains conditional on scope, tests, and replay evidence.

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-colsum`
- Shared handbook lineage: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785893827191/phases/01-eval/lineage/handbook-approved.md`
- Manager run: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785893827191/phases/01-eval/workers/eval-manager/task-colsum/REPORT.md`
- Executor run: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785893827191/phases/01-eval/workers/eval-worker/task-colsum-1/run.json`
- XSH baseline commit: `e5d29c7ec8b4411dc749fd3e44bf472d641ad9f4`

## Observation

The eval contract for `task-colsum` requires the program to exit nonzero and
print nothing when `HEADER` is not present in the header row (case
`hidden_missing_header`) and when a target-column value is not a decimal
integer (case `hidden_bad_value`). The malformed-value failure maps naturally
to `Str.parse_int()?`. But there is no explicit, idiomatic way to raise a
deliberate validation failure for the header-not-found condition. The worker
was forced to abuse a typed conversion — `let _ = "__missing_header__".parse_int()?`
— to force a nonzero exit with empty stdout for that control path.

## Evidence

- Worker session: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785893827191/phases/01-eval/workers/eval-worker/task-colsum-1/session.jsonl.bz2.bz2` (candidate written turn ~39; runtime `parse-int: invalid integer` used as the deliberate fail path).
- Submitted artifact `/work/colsum.xsh` contains the `".parse_int()?"` hack for the not-found branch.
- Worker review `review.md` explicitly flags: "There is no general, idiomatic way to raise a deliberate validation error with a message... A dedicated fail/error-raise form would make such control flow explicit."
- Evaluator `run.json`: both failure controls pass (nonzero exit, empty stdout) only because of this workaround.

## Diagnosis or hypothesis

This is a reusable XSH ergonomics gap, not task confusion: any eval or real
glue script that must "fail loudly when a condition is not met" currently has
no straightforward mechanism other than abusing a failing typed conversion or
an unrelated host failure. The factory handbook already documents the current
workaround ("no generic `Error(...)` constructor; use a typed conversion"),
which confirms agents are expected to work around an absent explicit
fail/raise form. A dedicated `fail`/`error`-raise construct would make
validation-failure control flow explicit and is general across evals
(`task-colsum`, `task-intsum`, config-validation, and malformed-input
contracts).

## North-star impact

Resolving this improves XSH ergonomics and trust: agents would not have to
invent a sentinel string and route it through `parse_int` to express a
deliberate rejection. It also improves learnability, giving a documented
spelling for an expected failure instead of a trick. Success evidence would be
a later eval that needs an explicit fail-on-condition path resolving it with a
named `fail(...)`/`error(...)` form and no conversion abuse.

## Proposed XSH change
## API-surface justification

For any new builtin, keyword, constructor, type, method, or syntax form, state:

- the semantic capability that existing XSH cannot express: a deliberate,
  message-bearing validation failure that exits nonzero without emitting the
  program's normal stdout contract;
- the closest existing spelling and why it is insufficient: abusing
  `"sentinel".parse_int()?` or another typed conversion couples control flow to
  an unrelated conversion error and hides the intent;
- whether a desugaring, type-directed rule, declared error family, or library
  API would solve the problem with less surface area: a library/Runtime error
  family plus a `fail(message)` result is likely the smallest surface;
- the implementation and maintenance cost: checker/runtime/API-registry support
  for producing and propagating an expected error value, plus
  documentation/tests;
- the evidence and falsification replay required: replay the linked
  `task-colsum` eval plus a second fail-on-condition eval to confirm the form
  replaces the conversion-abuse pattern.

An ergonomic shortcut that merely gives a second spelling to an existing
operation is not sufficient justification for product admission.

## Proposed XSH change

Add an explicit error-raise form (e.g., a `Result` factory such as
`error.fail(message)` or a `fail` keyword akin to `return`) that produces a
propagable expected failure suitable for `?`, so a deliberate validation
failure can be expressed directly instead of via a failing typed conversion.
Describe the smallest candidate implementation; do not claim it is implemented.

## Acceptance criteria

- Standardized evaluator replay (this `task-colsum` run) still passes all nine
  cases, including both failure controls, with the explicit form replacing the
  `parse_int` sentinel hack.
- A second eval with a fail-on-condition contract can use the same form without
  a workaround.
- Docs/handbook updated to name the form and its `error` effect requirement.

## Scope and non-goals

Does not add a generic user exception/subprocess boundary; does not alter
existing `parse_int`/`Result` semantics.

## Post-merge evaluation

The linked `task-colsum` eval-manager replay (same manager run path) will
accept or reject the merged change by confirming the failure controls still
pass and that the submitted solution no longer routes a deliberate rejection
through `parse_int`.

<!-- CONTROLLER_TICKET_SNAPSHOT_END -->

## Factory context required before coding

The factory documents below are outside the XSH worktree. Before coding, use
the `read` tool on each exact absolute path. This is required so the session
JSONL proves that the worker consumed the current factory guidance:

- North star: `/Users/josh/d/laputa-systems/xsh-factory/NORTH-STAR.md`
- Shared handbook: `/Users/josh/d/laputa-systems/xsh-factory/runtime/handbook.md`

Then use the `read` tool on the product worktree's exact guidance files:

- Product agent guide: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785894766939/phases/01-ticket/worktrees/task-colsum-001/AGENTS.md`
- XSH rationale: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785894766939/phases/01-ticket/worktrees/task-colsum-001/docs/CHAPTER-01-why-xsh.md`

## Implementation contract

Work only in `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785894766939/phases/01-ticket/worktrees/task-colsum-001` on branch `factory/task-colsum-001/1785894767724`. Do not edit XSH main, the
factory main tree, or the ticket diagnosis. Make the smallest general XSH
language, tooling, test, or canonical-documentation change supported by the
ticket. Run the narrowest relevant checks, commit the product change on this
branch, and leave the worktree clean.

The controller has staged a fail-closed `not-ready` report at
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785894766939/phases/01-ticket/workers/engineer/task-colsum-001/REPORT.md`. Complete that file in place; do not spend turns
reconstructing its headings. Keep `## Result` as `not-ready` until the
acceptance checks, commit, and clean-worktree validation are complete.

Write `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785894766939/phases/01-ticket/workers/engineer/task-colsum-001/REPORT.md` with these exact headings:

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
