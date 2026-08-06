# Ticket task-histogram-005

## Status

Open.

## Change target

- `product`
- `product`

## CTO review

- Review cycle: pre-cycle-2.
- Decision: Deferred; do not approve or dispatch.
- Basis: This is a single-eval follow-on observation created during repeated
  factory-blocked validation runs. It requires a controlled replay after the
  dispatch boundary is repaired; no second ticket is admitted while the
  approved `task-findexec-001` validation is unresolved.

## CTO review

- Review cycle: post-cycle-1.
- Decision: Deferred; do not approve or dispatch.
- Basis: Single-eval observation; requires controlled replay after the
  worktree/dispatch repair and is outside this cycle's corrective scope.

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-histogram`
- Shared handbook lineage: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785967719321/phases/03-eval/lineage/handbook-approved.md`
- Manager run: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785967719321/phases/03-eval/workers/eval-manager/task-histogram/REPORT.md`
- Executor run: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785967719321/phases/03-eval/workers/eval-worker/task-histogram-1/run.json`
- XSH baseline commit: `1cf4ad3d7ee5fde9b3160b11d8073cbd7ce5e7c4`

## Observation

A strict non-negative decimal integer contract has no first-class typed
spelling. `Str.parse_int` accepts an optional sign ("-5", "+3" both parse), so
rejecting signed input for a non-negative contract requires an extra regex
check; and there is no generic `Error(...)` constructor and no unsigned
integer parser, so a deliberate rejection with no matching typed conversion
must be forced by parsing an empty string (`"".parse_int()?`), which is
opaque and easy to misread.

The `task-histogram` worker searched `xsht api search:parse_uint`,
`search:unsigned`, and `search:nat`; the first two returned
`status: missing`, confirming no unsigned parser exists. It then had to
combine `regex.compile("^[0-9]+$")` with `parse_int` and the
`"".parse_int()?` forced-failure idiom to express the strict contract.

## Evidence

- Session: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785967719321/phases/03-eval/workers/eval-worker/task-histogram-1/session.jsonl`
  — the `search:parse_uint` and `search:unsigned` probes both return
  `status: missing`; the worker reasons explicitly about the missing `Error`
  constructor and the `"".parse_int()?` forced-failure idiom.
- Review: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785967719321/phases/03-eval/workers/eval-worker/task-histogram-1/review.md`
  — "XSH language proposals" records the unsigned-parser gap and the opaque
  `"".parse_int()?` rejection hack.
- Artifact: `histogram.xsh` in the same worker directory uses
  `regex.compile("^[0-9]+$")` + `parse_int` + `"".parse_int()?` to express
  the strict non-negative validation.
- Evaluator: `run.json` — all nine cases byte-exact, restrictions `pass`;
  both failure controls exit nonzero with empty stdout.

## Diagnosis or hypothesis

This is a general XSH ergonomics gap, not task-specific confusion. Strict
non-negative / unsigned integer validation is a recurring systems-glue
boundary (ports, counts, sizes, durations). Today an agent must either accept
signed input silently (a correctness risk) or layer a regex on top of a
typed parser and fall back to an opaque empty-string parse to force failure.
A typed unsigned parser (e.g. `Str.parse_uint()` rejecting any sign) and/or a
generic way to construct a typed `Error` would make the intended-rejection
path explicit and match the handbook's "prefer a typed conversion"
guidance.

## North-star impact

Validation of numeric input is a core systems-glue concern and a recurring
eval pattern. A typed unsigned/`parse_uint` parser or a generic `Error`
constructor would let agents express strict integer contracts with one typed
operation instead of regex-plus-hack, improving learnability, ergonomics, and
trust (no silent signal acceptance). It generalizes to any eval that reads a
non-negative decimal field; the falsification replay is a fresh
`task-histogram` and at least one other numeric-parsing eval confirming the
regex/empty-string workaround disappears and all cases stay byte-exact.

This is separate from `task-histogram-004`, which targets the unrelated
`check.try-context` rule governing where postfix `?` may appear in helper
procedures. This ticket deliberately does not propose changing `parse_int`
permissiveness or the `?` rule; it proposes additive surface (an unsigned
parser and/or a typed error constructor).

## Proposed XSH change
## API-surface justification

- Semantic capability not expressible today: a typed operation that parses a
  non-negative/unsigned decimal and rejects any signed or malformed input, and
  a first-class way to construct a deliberate typed failure.
- Closest existing spelling and why it is insufficient: `Str.parse_int` +
  `regex.compile("^[0-9]+$")` + `"".parse_int()?` works but is indirect,
  verbose, and the empty-string forced failure is unreadable at the call site.
- Less-surface alternative: a `parse_uint` method (type-directed, mirroring
  `parse_int`) is the smallest additive change that removes the regex and the
  sign hazard; a generic `Error(...)` constructor is an orthogonal additive
  change for the deliberate-failure path. Either is additive surface on an
  existing typed-conversion family, not a syntax or runtime redesign.
- Implementation and maintenance cost: a new method in the `Str`
  parse-conversion family plus its `xsht api` language-reference docs, checker
  wiring, and native tests; the runtime and effect system are otherwise
  unchanged.
- Evidence and falsification replay required: `task-histogram` must pass all
  nine cases using the new `parse_uint` (or `Error`) spelling, and one
  additional numeric-parse eval must confirm no regression.

## Proposed XSH change

Smallest candidate: add `Str.parse_uint()` that parses an unsigned decimal
integer and returns `Result[Int]`, rejecting any sign, and/or a generic
`Error` constructor so a deliberate validation failure can be typed directly
instead of via `"".parse_int()?`. Do not change `parse_int` behavior; the new
surface is additive.

## Acceptance criteria

1. `parse_uint` (or the `Error` constructor) is discoverable via `xsht api` in
   the pinned gym image.
2. `task-histogram` still passes all nine cases byte-exact using the new
   spelling, with the sign-rejection and non-positive-width paths expressed
   directly rather than via `"".parse_int()?`.
3. No regression in the rest of the approved eval suite.

## Scope and non-goals

- Non-goal: changing `parse_int` permissiveness or the `?`/`check.try-context`
  rule (tracked separately in `task-histogram-004`).
- Non-goal: new stream or fold surface.
- Non-goal: altering the effect system or error semantics at runtime.

## Post-merge evaluation

A linked eval-manager replay of `task-histogram` against the merged commit,
verifying the natural `parse_uint`/`Error` spelling is discovered and all
cases remain byte-exact, and recording an accept/reject decision in
`## Post-merge decisions` of the manager report.
