# Ticket task-histogram-009

## Status

Approved.

## CTO review — cycle 28 close

- Decision: Approved for controlled implementation in the next fresh engineer
  slot.
- Basis: The positive-exclusive bound remains reproducible after the
  `task-histogram-008` implementation replay: the eval's nine cases remain
  byte-exact, but the task contract still has no typed `> 0` rejection. The
  independent `task-bigfiles` eval also exercises the same numeric parsing
  family, providing a second signal that this is a language ergonomics gap,
  not a histogram-only workaround.
- Scope guard: Implement the smallest additive typed positive parse surface
  and preserve existing `parse_int`/`parse_uint` behavior. The linked replay
  remains mandatory for this fresh implementation.
- Evidence: cycle 28 fresh replay at
  `../runs/run-1786216593690/phases/02-reeval-task-histogram-008/`, independent
  eval at `../runs/run-1786216593690/phases/03-eval/`, and the retained replay
  evidence at `../runs/run-1786216593690/phases/02-reeval-task-histogram-005/`.

## CTO review — cycle 26 close

- Decision: Deferred; do not approve or dispatch yet.
- Basis: The positive-bound observation is strong and reproducible, but it is
  a single-eval language proposal. Preserve it for a directed replay after a
  typed positive parser or explicit failure surface is available; do not spend
  the next implementation slot on a workaround that intentionally raises
  SIGFPE.
- Evidence: the cycle-26 `task-histogram` worker and manager reports linked
  below, including all nine byte-exact cases and the width-zero signal path.

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

- Eval: `task-histogram`
- Shared handbook lineage: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786212430316/phases/02-reeval-task-histogram-005/lineage/handbook-approved.md`
- Manager run: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786212430316/phases/02-reeval-task-histogram-005/workers/eval-manager/task-histogram/REPORT.md`
- Executor run: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786212430316/phases/02-reeval-task-histogram-005/workers/eval-worker/task-histogram-1/run.json`
- XSH baseline commit: `26d59eb844b670365931d91ffb15ae8c109bae12` (candidate `2d255aa8297671339564f1f93587ec69c5f96cb5` adds `parse_uint`)

## Observation

A strict `> 0` (positive-exclusive) integer contract has no typed rejection.
With the `parse_uint` candidate in place, `parse_uint()` correctly rejects a
signed value, but it accepts `0`; the `task-histogram` width must be a
positive decimal. There is no typed positive-integer parser, no generic
`fail()`/`Error(...)` constructor, and no boolean-predicate failure primitive,
so the only runtime rejection available to the worker was forcing integer
division by zero:

    let _ = 1 / width # reject non-positive width (division by zero)

This aborts the interpreter via SIGFPE rather than a clean typed error: the
`hidden_bad_width` control has `candidate_exit = -1` (signal) with a byte-exact
empty stdout, and the worker's own probe reported `width 0` => `exit=133`.

## Evidence

- Run: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786212430316/phases/02-reeval-task-histogram-005/workers/eval-worker/task-histogram-1/run.json`
  — all nine cases byte-exact (`correctness.all_exact = true`); `hidden_bad_width`
  has `candidate_exit = -1` / `oracle_exit = 1`, `exact = true` (nonzero and
  empty stdout on both sides, but the candidate sides through a signal abort,
  not a typed error). `restrictions.passed = false` (see the separate factory
  note about the evaluator restriction checker only accepting `parse_int`).
- Session: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786212430316/phases/02-reeval-task-histogram-005/workers/eval-worker/task-histogram-1/session.jsonl`,
  tool result turn 22 — `width 0` => `exit=133`, and `width non-int` path also
  ends in a `sh: syntax error: bad substitution` (test-shell noise, not the
  typed path).
- Review: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786212430316/phases/02-reeval-task-histogram-005/workers/eval-worker/task-histogram-1/review.md`,
  "XSH language proposals": "there is no `fail()`/`Error(...)` construct and no
  checked positive-integer conversion, so the only runtime failure available is
  forced integer division by zero, which aborts via SIGFPE (exit 133) rather
  than a clean typed error."
- Artifact: `histogram.xsh` uses `let _ = 1 / width # reject non-positive width`.
- Handbook: the approved snapshot's validation guidance covers non-negative
  parsing but is silent on a positive-exclusive bound, which has no typed
  spelling.

## Diagnosis or hypothesis

This is a general XSH ergonomics gap, not task-specific confusion. Positive
boundaries recur across systems glue (widths, sizes, port numbers, counts,
durations, chunk sizes), and an agent facing a `> 0` contract today must either
skip validation silently (a correctness risk) or force a signal-raising
side effect (division by zero) that aborts the runtime instead of yielding a
typed expected error. A typed `parse_uint_positive()` conversion, or a general
`fail(message)` / `Error(...)` constructor for boolean-predicate failure, would
make the deliberate rejection explicit and idiomatic, matching the handbook's
"prefer a typed conversion" guidance. The existing tickets do not cover this:
`task-histogram-005` covers only `parse_uint` (sign rejection); the positive
(`> 0`) bound is the unmapped remainder.

## North-star impact

Typed validation of positive integer contracts is core systems-glue ergonomics.
A typed positive parser or a general error constructor would let agents reject
an out-of-range value loudly and clearly instead of aborting via SIGFPE or
silently accepting it, improving correctness, trust, and learnability for every
numeric-boundary eval. Falsification replay: a fresh `task-histogram` (and a
second numeric-parse eval) where the positive-width rejection is expressed with
one typed operation, all nine cases stay byte-exact, and `hidden_bad_width`
exits nonzero through a typed error rather than a signal.

## Proposed XSH change
## API-surface justification

- Semantic capability not expressible today: a typed operation that rejects a
  non-positive integer (a `> 0` bound). `parse_uint` accepts `0`, so it cannot
  express a positive-exclusive contract.
- Closest existing spelling and why it is insufficient: `parse_uint()?` +
  `let _ = 1 / width` works by forcing a divide-by-zero SIGFPE abort — it is
  opaque, raises a signal rather than a typed error, and is unreadable at the
  call site. There is no generic `Error(...)`/`fail(...)` for a boolean
  predicate.
- Less-surface alternative: a type-directed `Str.parse_uint_positive()`
  (mirroring `parse_int`/`parse_uint`) is the smallest additive change that
  removes the divide-by-zero side effect and the positive-bound hazard. A
  generic `Error(...)` constructor would also solve it but combines a separate,
  larger error-construction proposal with this validation fix.
- Implementation and maintenance cost: a new method in the Str
  parse-conversion family plus its `xsht api` language-reference docs, checker
  wiring, and native tests; the runtime and effect system are otherwise
  unchanged.
- Evidence and falsification replay required: `task-histogram` must pass all
  nine cases with the new spelling (including a clean nonzero/empty-stdout
  `hidden_bad_width` that does not rely on a signal abort), and an additional
  numeric-parse eval must confirm no regression.

## Proposed XSH change

Smallest candidate: add `Str.parse_uint_positive()` (or an equivalent typed
positive-exclusive parse) that parses an unsigned decimal and rejects `0` and
any sign, returning `Result[Int]`. Do not add a generic `Error` constructor in
this ticket and do not change `parse_uint`/`parse_int` behavior; the new
surface is additive.

## Acceptance criteria

1. `parse_uint_positive` (or the chosen spelling) is discoverable via `xsht api`
   in the pinned gym image.
2. `task-histogram` still passes all nine cases byte-exact using the new
   spelling, and `hidden_bad_width` exits nonzero with empty stdout through a
   typed error rather than a signal.
3. No regression in the rest of the approved eval suite.

## Scope and non-goals

- Non-goal: changing `parse_int`/`parse_uint` permissiveness or the
  `?`/`check.try-context` rule.
- Non-goal: a generic `Error(...)` constructor (tracked as a possible separate
  proposal).
- Non-goal: new stream or fold surface, or altering the eval task contract or
  its oracle.

## Post-merge evaluation

A linked eval-manager replay of `task-histogram` against the merged commit,
verifying the positive-bound rejection is discovered and used and all nine
cases remain byte-exact, with the decision recorded in
`## Post-merge decisions` of the manager report.
