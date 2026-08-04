# Ticket task-envcfg-001

## Status

Approved.

## CTO closeout

- Close cycle: `runs/run-1785818570933`.
- Decision: Closed as `too difficult` after the assigned engineer reached the
  coded 160-turn session limit without a commit, clean worktree, portable
  patch, or completed report.
- Evidence: `runs/run-1785818570933/phases/01-ticket/workers/engineer/task-envcfg-001/report.json`;
  the controller recorded `SESSION-LIMIT` and the linked replay was not
  admitted because no reviewable implementation existed.
- Reopened for a fresh implementation assignment after changing the engineer
- model to `openai/gpt-5.6-luna` and raising the bounded engineer allowance.

## CTO review

- Review cycle: `pre-cycle-1785821294691`
- Decision: Approved for the next organization cycle and assigned to a new
- engineer session.
- Basis: The prior engineer exhausted the old 160-turn ceiling without a
- reviewable artifact; the underlying product defect remains evidence-backed
- and unimplemented.
- Assignment boundary: Keep the smallest deliberate-error primitive that
- propagates through `?`; preserve validator semantics and add focused tests
- and canonical documentation. Do not broaden into boolean operators,
- module-shadow guidance, or unrelated environment APIs.

## CTO review

- Review cycle: `pre-cycle-17858185373`
- Decision: Approved for this organization cycle.
- Basis: The deliberate-validation failure workaround was independently
  reproduced by both `task-envcfg` workers, is a general structured-error gap,
  and has focused acceptance criteria plus a linked replay. It is distinct
  from the deferred handbook-only boolean/operator guidance.
- Assignment boundary: Add the smallest canonical deliberate-error primitive
  that propagates through `?`; preserve existing validator semantics and add
  focused native coverage and canonical product documentation. Do not address
  boolean operators, module-shadow guidance, or unrelated env APIs.

## Merge record

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-envcfg`
- Shared handbook lineage: `runs/run-1785816263612/phases/03-eval/lineage/handbook-approved.md` (snapshot `97c5d804c42c7742c9edfea4480163828d864279391d391df77aa60ee4a40e83`); candidate `handbook-candidate.md`
- Manager run: `runs/run-1785816263612/phases/03-eval/workers/eval-manager/task-envcfg/REPORT.md`
- Executor run: `runs/run-1785816263612/phases/03-eval/workers/eval-worker/task-envcfg-1/` and `task-envcfg-2/`
- XSH baseline commit: `5e0c679344458c4f39bf3f368a6d63a4c51aa01f`

## Observation

`task-envcfg` requires a deliberate nonzero exit (with no partial output file)
when `CFG_PORT` is present but not a byte-exact decimal integer. The build has
no generic error constructor, so both eval-workers (trial 1 turn 14, trial 2)
reached the same workaround: route an unrelated typed conversion to failure
inside the validation branch, e.g. `let _ = "not-a-port".parse_int()?`. Both
`review.md` files name the missing deliberate-error primitive as the top
reusable language proposal.

## Evidence

- Session JSONL: `workers/eval-worker/task-envcfg-1/session.jsonl` (tool errors turns 11/14/16/37), `task-envcfg-2/session.jsonl` (tool errors turns 9/13).
- Artifacts: `task-envcfg-1/envcfg.xsh`, `task-envcfg-2/envcfg.xsh` (both use the sentinel `parse_int` idiom).
- Reviews: `task-envcfg-1/review.md` (XSH language proposals) and `task-envcfg-2/review.md` (XSH language proposals) independently request a `fail`/`Error(...)` constructor.
- Evaluator: both `run.json` files pass all 10 cases (see `tool_errors` arrays).
- Handbook note at `handbook-approved.md:83-87` documents the absence of a generic `Error(...)` constructor and tells agents not to use an unrelated host failure — yet that is the only documented action available for a byte-exact validation contract where no typed conversion matches.

## Diagnosis or hypothesis

A deliberate validation failure is a normal, reusable systems-glue pattern
("reject this input, exit nonzero, don't write anything"). Forcing an
unrelated `parse_int` on a sentinel literal to fabricate the failure is opaque,
fragile, and directly contradicts the handbook's own "do not use an unrelated
host failure" guidance. This is a general ergonomics gap, not task-specific
confusion: it appears in any config/args-validation boundary, and it was
reproduced independently by two separate sessions.

## North-star impact

XSH's north star calls for structured errors and making expected failures
visible. A first-class deliberate-error primitive (`fail`/`Error(...)` that
propagates through `?` with the standard error family) would let programs
reject malformed input clearly instead of abusing a correlation-free parse
error. Evidence that it generalizes: it removes the sentinel workaround in any
eval that gates on a loud nonzero exit, and it makes the `?` propagation lesson
transfer cleanly to validation boundaries.

## Proposed XSH change

Add a generic deliberate-error mechanism that propagates through postfix `?`
with the existing error family — e.g. a `fail("...")` primitive or an
`Error(...)`/`Err(...)` constructor — replacing the sentinel typed-conversion
idiom. Keep it a word/constructor that works in expression position inside an
`if`/guard, and does not require the current hacky `let _ = "sentinel".parse_int()?`.

## Acceptance criteria

- A program can reject a bad value and exit nonzero with no output file using only the new primitive (no unrelated typed conversion).
- The `task-envcfg` malformed and empty-port failure controls still pass.
- A focused unit test verifies the new primitive propagates through `?` and exits nonzero.
- `xsht check`/`lint` accept the canonical form.

## Scope and non-goals

- Out of scope: changing the semantics or strictness of `env.int`/`parse_int` validators (that is a separate contract decision: `env.int` rejects only non-numeric runs and stays lenient about sign/whitespace/hex).
- Out of scope: the `&&`/`||` word-form friction (handled as a handbook candidate in this cycle, not a product ticket).

## Post-merge evaluation

Replay `task-envcfg` (and ideally `task-ecount`/`task-tags`) against a merged
commit to confirm the deliberate-error idiom is accepted and pass rates are
unchanged or improved.
