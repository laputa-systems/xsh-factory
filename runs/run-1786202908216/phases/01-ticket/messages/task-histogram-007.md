# Controller-assigned engineer ticket

This is an immutable controller assignment for one implementation worker.
The controller, not the worker, selected the ticket, snapshot, worktree, and
branch.

## Assignment authority

- Ticket ID: `task-histogram-007`
- Ticket snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786202908216/phases/01-ticket/tickets/task-histogram-007.md`
- Ticket snapshot SHA-256: `744843ce3266255e57aab923b3aa4137610116d95e705ae973fab7af7a6f5c1c`
- Dedicated XSH worktree: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786202908216/task-histogram-007`
- Branch: `factory/task-histogram-007/1786202910274`
- XSH base commit: `608ab11bcf25cb0f69df4cb352fa40b27c1be2b3`
- engineer report: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786202908216/phases/01-ticket/workers/engineer/task-histogram-007/REPORT.md`
- Factory root: `/Users/josh/d/laputa-systems/xsh-factory`
- Run evidence root: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786202908216/phases/01-ticket`

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
# Ticket task-histogram-007

## Status

Approved.

## CTO decision — cycle-22 queue

- Decision: Approved for implementation in cycle 23.
- Basis: the independent `task-histogram` worker reproduced the same
  `//`/`div` discovery and diagnostic gap in
  `runs/run-1786201137236/phases/03-eval/workers/eval-worker/task-histogram-1/`;
  the evaluator still passed all supplied cases. The change is diagnostic-only,
  has a bounded scope, and its API-surface justification explicitly rejects a
  new operator.
- Scope: add a readable check-time diagnostic for `//`/`div` that points to
  integer `/`; do not change division semantics.

## CTO decision — clean-slate cycle 2026-08-07

- Decision: Deferred; do not approve or dispatch.
- Basis: `runs/` was intentionally reset, so this single-eval arithmetic
  observation has no fresh replay or cross-eval confirmation. Preserve it
  until the explicit-division diagnostic is tested again.

## Change target

- `product`

## CTO review

- Review cycle: post-clean-validation.
- Decision: Deferred; do not approve or dispatch.
- Basis: The observation is single-eval guidance from the dispatch-repair
  period. Require cross-eval replay before admitting another ticket.

## Budget breach

None.

## CTO decision — pre-cycle 2026-08-06

- Decision: Deferred; do not approve or dispatch in this cycle.
- Basis: The observation remains single-eval guidance from the dispatch-repair
  period. Require cross-eval replay before any implementation approval.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-histogram`
- Shared handbook lineage: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785973336705/phases/03-eval/lineage/handbook-approved.md`
- Manager run: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785973336705/phases/03-eval/workers/eval-manager/task-histogram/REPORT.md`
- Executor run: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785973336705/phases/03-eval/workers/eval-worker/task-histogram-1/run.json`
- XSH baseline commit: `1cf4ad3d7ee5fde9b3160b11d8073cbd7ce5e7c4`

## Observation

There is no explicit integer-division operator in XSH. `//` and `div` are both
rejected at parse time, `xsht api search:div` and `search:operator` return
`status: missing`, and the only working spelling is `/` on Int operands, which
performs integer (truncating) division with the behavior inferred entirely from
the operand type. The eval's own contract and the common binning idiom use
`v // WIDTH`, which does not exist in the language.

The `task-histogram` worker spent multiple turns discovering this: it probed
`search:div`, `search:floor`, and `search:operator` (only `Float.floor`
matched), then wrote a probe trying `7 div 2` and `7 // 2` (both rejected with
`err[parse.expected-terminator]: expected statement terminator`, which does not
name the operator) before confirming that `7 / 2` parses and evaluates to `3`
(truncated). The final solution relies on `/` truncating silently for
non-negative values.

## Evidence

- Session: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785973336705/phases/03-eval/workers/eval-worker/task-histogram-1/session.jsonl.bz2`
  — `xsht api search:div` -> `status: missing`, `search:operator` -> missing,
  `search:floor` -> only `method.Float.floor`; probe `7 div 2` and `7 // 2`
  both rejected (`parse.expected-terminator`, no operator named); probe `7 / 2`
  prints `3` (truncated integer division).
- Review: `workers/eval-worker/task-histogram-1/review.md`, "XSH language
  proposals" item 1 ("`//` is not an integer-division operator; ... Integer `/`
  on Int values silently performs integer division (truncated...). Consider
  supporting `//` as an explicit integer division operator (or documenting that
  `/` truncates for Int).").
- Artifact: `histogram.xsh` uses `|> map { |v| v / width }` and passed all nine
  cases byte-exact with both failure controls exiting nonzero (run.json).
- Handbook: the approved snapshot ships no guidance on Int division, `//`, or
  `div` anywhere in the document.

## Diagnosis or hypothesis

This is a general XSH ergonomics and discoverability issue, not task-specific
confusion. Quotient/bin computation (`v // width`) is a canonical systems-glue
operation, and the natural spelling used by the eval contract and by SQL/awk
idiom (`//`) does not exist, with no readable diagnostic pointing at an
alternative. Integer division is instead expressed by overloaded `/` whose
truncation behavior is inferred purely from operand types — exactly the kind of
implicit, type-directed behavior the XSH rationale says should be made explicit
("no hidden ... behavior"; boundaries should be explicit). Any eval that divides
or bins numeric measurements hits the same discovery path. This mirrors the
already-logged "opaque diagnostic" theme (task-histogram-003 fold-print,
task-histogram-006 filter/where) but is a distinct surface: the absence of an
explicit integer-division operator rather than a mis-diagnosed stage.

## North-star impact

Explicit integer division would make the intended math readable and verifiable
instead of inferred from the operand type, improving learnability and trust for
every numeric-glue eval (bins, quotients, page sizes, chunked processing). The
falsification replay is a fresh `task-histogram` (and at least one other
division-heavy eval) confirming the worker reaches a correct binning solution
in fewer turns without the `div`/`//`/`operator` probe chain, and that either
`//` compiles or a check-time diagnostic names the `/`-on-Int alternative.

## Proposed XSH change
## API-surface justification

- Semantic capability not expressible today: an explicit integer-division
  operator whose semantics do not depend on operand type inference; today an
  agent must know that `/` truncates Int and be careful not to use `//`/`div`
  (which parse-fail).
- Closest existing spelling and why it is insufficient: `/` on Int truncates
  but the behavior is inferred and undiscoverable; the natural `//` and `div`
  spellings are rejected with a generic `expected-terminator` error that does
  not mention integer division.
- Whether a desugaring/type-directed rule or alias would solve it with less
  surface: supporting `//` as an alias for Int `/` (or emitting a check-time
  diagnostic naming `/`-on-Int) is a small parser/checker addition with no new
  runtime or type surface. A type-directed rule already exists (`/` truncates
  Int), so the gap is purely syntactic discoverability.
- Implementation and maintenance cost: add `//` as an integer-division operator
  (or a parse/check diagnostic for `//`/`div` naming `/` on Int), one native
  test, an `xsht api`/language-reference note; the runtime is unchanged.
- Evidence and falsification replay required before approval: a script using
  `v // width` (or a diagnostic for the missing operator) must behave as
  documented, and `task-histogram` must stay 9/9 byte-exact.

## Proposed XSH change

Smallest candidate: emit a readable `check`-time diagnostic for `//`/`div`
that points to `/` on Int. Do not add a new operator or change the truncation
semantics of `/` in this ticket.

## Acceptance criteria

1. A script using `7 // 2` or `7 div 2` receives a readable diagnostic naming
   `/` on Int, and the binning solution compiles with `/`.
2. `task-histogram` re-run stays 9/9 byte-exact using the documented `/`
   spelling.
3. No regression in the other approved eval suite.

## Scope and non-goals

- Non-goal: changing Int `/` truncation semantics or the type system.
- Non-goal: Float division behavior or mixing Int/Float division.
- Non-goal: altering the eval task contract or its oracle.
- The descriptive handbook note (``/` on Int truncates; there is no `//`/`div``
  ) is staged separately as a provisional handbook candidate and does not
  depend on this product change.

## CTO preparation — 2026-08-06

- Selected implementation path: diagnostic-only guidance for `//` and `div`.
- Defer adding a new operator until separate evidence demonstrates that the
  diagnostic path is insufficient.

## Post-merge evaluation

A linked eval-manager replay of `task-histogram` against the merged commit,
verifying the explicit integer-division spelling is discovered and used and all
nine cases remain byte-exact, with the decision recorded in
`## Post-merge decisions` of the manager report.

<!-- CONTROLLER_TICKET_SNAPSHOT_END -->

## Factory context required before coding

The factory documents below are outside the XSH worktree. Before coding, use
the `read` tool on each exact absolute path. This is required so the session
JSONL proves that the worker consumed the current factory guidance:

- North star: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786202908216/phases/01-ticket/guidance/NORTH-STAR.md`
- Approved handbook snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786202908216/phases/01-ticket/guidance/handbook.md`
- Handbook candidate: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786202908216/phases/01-ticket/lineage/handbook-candidate.md`

The approved snapshot is a run-scoped copy of the checked-in handbook. Read it
as an input and never edit it or the checked-in handbook. If this ticket
produces a reusable lesson, add it to the run-scoped candidate path above; the
candidate is shared review input and is promoted only after CTO review. If no
handbook improvement is justified, leave the candidate unchanged.

Then use the `read` tool on the product worktree's exact guidance files:

- Product agent guide: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786202908216/task-histogram-007/AGENTS.md`
- XSH rationale: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786202908216/task-histogram-007/docs/CHAPTER-01-why-xsh.md`

## Implementation contract

Work only in `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786202908216/task-histogram-007` on branch `factory/task-histogram-007/1786202910274`. Do not edit XSH main, the
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
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786202908216/phases/01-ticket/workers/engineer/task-histogram-007/REPORT.md`. Complete that file in place; do not spend turns
reconstructing its headings. Keep `## Result` as `not-ready` until the
acceptance checks, commit, and clean-worktree validation are complete.

Write `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786202908216/phases/01-ticket/workers/engineer/task-histogram-007/REPORT.md` with these exact headings:

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
