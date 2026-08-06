# Ticket task-histogram-007

## Status

Open.

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

- Session: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785973336705/phases/03-eval/workers/eval-worker/task-histogram-1/session.jsonl`
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

Smallest candidate: support `//` as an explicit integer-division operator on
Int operands (alias to the existing truncating `/`), or, if a new operator is
to be avoided, emit a readable `check`-time diagnostic for `//`/`div` that
points to `/` on Int. Do not change the truncation semantics of `/`.

## Acceptance criteria

1. A script using `7 // 2` (or, on the diagnostic-only path, being told to use
   `/`) passes `xsht check` and the binning solution compiles.
2. `task-histogram` re-run stays 9/9 byte-exact using the explicit
   integer-division spelling.
3. No regression in the other approved eval suite.

## Scope and non-goals

- Non-goal: changing Int `/` truncation semantics or the type system.
- Non-goal: Float division behavior or mixing Int/Float division.
- Non-goal: altering the eval task contract or its oracle.
- The descriptive handbook note (``/` on Int truncates; there is no `//`/`div``
  ) is staged separately as a provisional handbook candidate and does not
  depend on this product change.

## Post-merge evaluation

A linked eval-manager replay of `task-histogram` against the merged commit,
verifying the explicit integer-division spelling is discovered and used and all
nine cases remain byte-exact, with the decision recorded in
`## Post-merge decisions` of the manager report.
