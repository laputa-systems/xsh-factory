# Ticket task-envcfg-001

## Status

Closed.

## Change target

- `product`

## CTO disposition — semantic-novelty rejection

- Review cycle: `cto-2026-08-05`
- Decision: Closed; reject the proposed API addition.
- Basis: the proposal adds no semantic capability beyond the existing
  deliberate-error/`Result` machinery and fails the API-surface semantic-
  novelty gate. No engineer dispatch or replay is authorized from this ticket.
- Reopen condition: a materially different design must compare the existing
  mechanism, desugaring, declared error families, and registry/test cost.

## CTO review

- Review cycle: pre-cycle-1.
- Decision: Deferred; do not approve or dispatch.
- Basis: The current proposal remains a convenience error constructor and
  fails the API-surface semantic-novelty gate. Existing `error.fail`/Result
  machinery is the relevant merged mechanism; no new evidence demonstrates
  that this ticket needs a separate product surface.

## CTO decision — pre-cycle review

- Review cycle: pre-cycle organization request.
- Decision: Deferred; do not approve or dispatch.
- Basis: The current product checkout reverted the prior convenience
  `fail(message)` implementation. The ticket's API-surface review found no
  semantic novelty beyond existing `Err`/`Result` machinery, so the quality
  gate is not satisfied. The linked `task-envcfg` eval remains live, but a
  live eval alone does not justify this API addition.
- Next evidence: a materially different, type-directed or otherwise
  semantically novel design must be proposed and reviewed before admission.

## CTO decision — rejected API addition

- Review cycle: `post-cycle-1785876949561`.
- Decision: Reopened and rejected for implementation in its current form.
- Basis: `754fcba` added `fail(message)` as a second spelling for constructing
  `Err(Error)`, with no semantic capability beyond existing Result/error
  machinery. The implementation added separate checker, lowering, indexed-IR,
  runtime, specification, and test surface for a convenience constructor.
  Passing the linked eval proved only that the feature worked—not that the API
  addition was justified.
- Product disposition: the XSH checkout reverted `754fcba` and its prerequisite
  API-registration commit `2d423c1`; current product `HEAD` is `a67599b`. The
  original commits and run evidence remain preserved for audit, but are not an
  accepted product change.
- Next evidence required: compare `Err` construction, declared error families,
- API-surface justification

The rejected proposal is a convenience constructor, so it fails the current
quality gate. Existing `Err` already represents the required Result branch;
the only observed gap is that `Err("message")` does not infer the declared
`Error` payload. A smaller alternative is to improve type-directed error
construction or define a declared validation error family, rather than add a
parallel builtin and IR tag. The proposed `fail` implementation would touch
the checker, lowering, indexed runtime, specification, API registry, and
tests, while adding no semantic behavior beyond `Err(Error)`. Approval would
require a concrete semantic difference, an alternatives comparison, and a
replay proving the simpler design cannot satisfy the validation contract.

- Next evidence required: compare `Err` construction, declared error families,
  and any desugaring or type-directed alternative. A future proposal must
  demonstrate semantic novelty or a materially simpler existing mechanism
  before approval. No engineer dispatch is authorized from this ticket until
  that design review is complete.

## CTO decision — current-HEAD implementation cycle

- Review cycle: `pre-cycle-1785873121313-next`.
- Decision: Approved for a fresh implementation assignment.
- Basis: The defect remains evidence-backed, the linked `task-envcfg` eval is
  active, and current XSH `HEAD` (`434080d`) contains both the runtime
  `fail(message)` primitive and its canonical `xsht api` registration
  (`2d423c1`). The prior unmerged branch (`91e0eaa`) was based before the API
  registration and is not a valid current-HEAD candidate.
- Branch disposition: the dependency-incomplete branch is not eligible for
  reuse; its run evidence and commit remain preserved. This cycle must
  dispatch a fresh engineer from current `HEAD`.
- Assignment boundary: implement the smallest deliberate-error primitive
  behavior required by the ticket, preserve validator semantics, and add
  focused tests and canonical documentation. Do not broaden into boolean
  operators, module-shadow guidance, or unrelated environment APIs.
- Acceptance gate: the fresh engineer must produce a clean portable patch;
  the linked replay must discover `fail` through `xsht api`, adopt
  `fail(...)?`, and pass all ten evaluator cases.

## CTO decision — throughput cycle

- Review cycle: pending next organization run.
- Decision: Rejected for dispatch in this cycle; retain `Open.` pending a
  candidate branch that includes both the runtime primitive and API registry.
- Basis: The existing implementation branch `91e0eaa` omits the already merged
  API registration `2d423c1`; its linked replay passed the evaluator but failed
  the ticket's required discovery/adoption gate. Dispatching a duplicate
  engineer would not be productive while that branch remains the reusable
  implementation and the controller's reuse path cannot combine two branches.
- Next evidence: create a bounded replay/candidate branch based on current XSH
  `HEAD` (which contains `2d423c1`) and require `xsht api search:fail`, adoption
  of `fail(...)?`, and all ten evaluator cases before changing this ticket to
  `Approved.` again.

## CTO decision

- Review cycle: `runs/run-1785821597944`.
- Decision: Deferred pending the linked API-discovery fix; do not merge
  `91e0eaa` yet.
- Basis: The `fail(message)` runtime implementation is correct in isolation,
  but the linked replay's manager found that `xsht api` cannot discover it, so
  the eval agent still used the sentinel `parse_int` workaround. The branch is
  retained for reuse after `task-envcfg-002` is implemented.
- Next evidence: replay `task-envcfg` against the repaired branch and require
  `xsht api search:fail` discovery plus adoption of `fail(...)?` and all ten
  evaluator cases passing.

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

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

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
