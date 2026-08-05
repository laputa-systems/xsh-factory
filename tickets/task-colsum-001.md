# Ticket task-colsum-001

## Status

Merged.

## Change target

- `product`

## CTO decision — post-cycle review

- Review cycle: `run-1785894766939`.
- Decision: Merge accepted; implementation is now present at XSH `HEAD`.
- Evidence: engineer commit `5f46267067991d5af1d988732e5c2f6f5de5ad04`; linked `task-colsum` replay passed all nine cases without the sentinel conversion; XSH checkout is clean at that commit.
- Remaining validation: the new `error.fail` spelling itself was not exercised by the linked replay, so retain the follow-up cross-eval requirement in `task-colsum-002`/the next cycle. The product merge is not reverted on that basis; the acceptance behavior already has a valid `first()?` idiom.


## CTO decision — next organization cycle

- Review cycle: next organization cycle.
- Decision: Approved for one bounded engineer assignment.
- Basis: The current XSH `HEAD` is `e5d29c7`, where the prior `Error(kind: ...)` constructor is removed and no generic message-bearing error can be constructed without declaring a family/variant or abusing an unrelated conversion. Independent `task-envcfg` and `task-colsum` sessions reproduced the same validation-boundary gap. This is a semantic capability—direct construction of an expected validation failure—not merely a spelling change in the current product. The ticket contains the required API-surface justification and limits scope to checker/runtime/specification/tests plus linked replay.
- Assignment boundary: prefer the smallest existing declared-error or type-directed mechanism if it genuinely provides a generic message-bearing validation failure; otherwise implement the narrowest explicit form. Preserve `Err`/`Result` semantics, add canonical docs and focused tests, and do not broaden into boolean operators or unrelated APIs.
- Acceptance gate: clean portable commit, `task-colsum` replay passing all nine cases without the sentinel conversion for the missing-header branch, and independent eval manifest passing. CTO merge remains conditional on scope, tests, and replay evidence.

## Budget breach

None.

## Merge record

- Implementation branch: `factory/task-colsum-001/1785894767724`
- Implementation commit: `5f46267067991d5af1d988732e5c2f6f5de5ad04`
- Detected at XSH commit: `5f46267067991d5af1d988732e5c2f6f5de5ad04`
- Implementation run: `runs/run-1785894766939/phases/01-ticket`

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

- Worker session: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785893827191/phases/01-eval/workers/eval-worker/task-colsum-1/session.jsonl` (candidate written turn ~39; runtime `parse-int: invalid integer` used as the deliberate fail path).
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
