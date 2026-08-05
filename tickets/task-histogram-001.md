# Ticket task-histogram-001

## Status

Open.

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-histogram`
- Shared handbook lineage: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785896401695/phases/03-eval/lineage/handbook-approved.md`
- Manager run: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785896401695/phases/03-eval/workers/eval-manager/task-histogram/REPORT.md`
- Executor run: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785896401695/phases/03-eval/workers/eval-worker/task-histogram-1/run.json`
- XSH baseline commit: `5f46267067991d5af1d988732e5c2f6f5de5ad04`

## Observation

The worker had to reject a parsed-but-invalid input (a width that parses as a
decimal integer but is non-positive, and a malformed measurement line). No
typed conversion expresses these conditions — `parse_int` succeeds on a
positive and a non-positive decimal equally — and the build has no generic
error-value constructor or assertion predicate. The only way to fail loudly
was to call an unrelated conversion on a sentinel in the failing branch:

    if width <= 0 {
        let _ = "".parse_int()?
    }

This makes the deliberate rejection unintelligible to a reader: the failure is
an unrelated empty-string parse, not an expression of the violated condition.
The same pattern is required at the two validation sites (width check and bad
value check).

## Evidence

- Artifact: `workers/eval-worker/task-histogram-1/histogram.xsh` (the two
  sentinel-`parse_int` failure branches).
- Review: `workers/eval-worker/task-histogram-1/review.md`, "XSH language
  proposals" section.
- Session: `workers/eval-worker/task-histogram-1/session.jsonl` (turns 26-45
  show the agent also probing for an assertion/error primitive; `record.require`
  query returned `missing`).
- Report/usage: `workers/eval-worker/task-histogram-1/report.json`.

The handbook-`approved` snapshot already documents the limitation ("This build
has no generic `Error(...)` constructor; do not invent an error value or use
an unrelated host failure when a typed conversion can express the rejected
input"); the gap is that a typed conversion cannot express a non-positivity
condition, forcing the unrelated-host-failure workaround the handbook warns
against.

## Diagnosis or hypothesis

This is a real XSH ergonomics gap, not task confusion: rejecting a value that
parses but fails a domain predicate (positive width, range, set membership) is
a recurring systems-glue pattern, and the only current spelling is an
unrelated sentinel conversion. It generalizes beyond `task-histogram` to any
numerical/range validation.

## North-star impact

A first-class `require(cond, msg)` predicate (or an error-family constructor /
`Result` assertion) that fails the current effect with a readable message
would make deliberate negative validation explicit, learnable, and
self-documenting, removing the misleading sentinel hack. Acceptance evidence:
the source eval replays with `width <= 0` and malformed-value branches written
as readable `require(...)` calls, and at least one other eval that validates a
parsed numeric domain adopts the same idiom.

## Proposed XSH change

Add a small surface-area assertion, e.g. a `require(cond: Bool, msg: Str)` that
returns a failing `Result[Unit, Error]` when `cond` is false, or a
`Result.fail(msg)` / typed error constructor, usable with postfix `?` to exit
nonzero. Keep it a general predicate, not a histogram-specific helper.

## API-surface justification

- Semantic capability not expressible today: failing on a condition that no
  typed conversion represents (positivity/range/membership after a successful
  parse).
- Closest existing spelling: propagating a typed `parse_int`/`env.int` failure
  — sufficient only when the failure is itself a parse/format error, not a
  post-parse domain violation.
- Surface-area options: a desugared `require` lowering to a `Result.fail`
  would be the smallest; an error-family constructor adds more checker/runtime
  surface.
- Cost: checker (condition block and message), a Result/error family entry,
  API registry entry, docs, and tests.
- Falsification replay: `task-histogram` with the two validation branches
  rewritten as `require(...)`, plus a second numeric-validation eval, must keep
  byte-exact output and the failure controls.

## Proposed XSH change

Describe the smallest candidate implementation or bug fix below. Do not claim
that the change is already implemented.

Implement the `require(cond, msg)` predicate (or `Result.fail`) as a library
function lowering to an expected-failure `Result`, documented via `xsht api`,
and usable with postfix `?`.

## Acceptance criteria

- `xsht api` documents the new predicate under an exact `method:` / `module:`
  key.
- A script can fail with a readable message on a false predicate while keeping
  `[error]` effects and nonzero exit.
- `task-histogram` reference rewrite stays byte-exact on all nine cases and
  exits nonzero/empty on both failure controls.
- At least one other numeric-validation eval replays the idiom.

## Scope and non-goals

- No change to `parse_int`/`env.int` semantics.
- No general purpose-control-flow assertion beyond the named fail-on-condition.
- No subprocess or I/O involvement; pure expected-failure handling.

## Post-merge evaluation

The linked `task-histogram` eval-manager replay (after the CTO merges the
implementation branch) accepts or rejects based on the acceptance criteria
above.
