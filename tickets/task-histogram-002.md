# Ticket task-histogram-002

## Status

Merged.

## CTO decision — post-cycle run-2

- Decision: Merge accepted; implementation is present at XSH `HEAD`.
- Evidence: engineer commit `aaa968c73fd7649f70a6a94e21f77a90bf6a778c`; linked `task-histogram` replay and independent manifest both passed correctness and restrictions; focused sema test passed on merged HEAD.
- Remaining validation: cross-eval grouped-key replay remains desirable; no handbook candidate is promoted from this cycle until that evidence exists.

## CTO decision — pre-cycle run-2

- Decision: Approved for one bounded engineer assignment.
- Basis: The linked `task-histogram` trial was byte-exact on all nine cases but failed only the required `sort-by` restriction because the checker rejected `group-by`'s generic `key` projection. The ticket is general, scoped, has the required API-surface justification, and has a live linked replay plus cross-eval acceptance criteria.
- Assignment boundary: fix concrete group-key projection for the existing `sort-by` surface, add focused native coverage, and avoid new syntax or library APIs. Do not promote the provisional handbook candidate until replay evidence supports it.
- Acceptance gate: clean portable commit, linked histogram replay passing correctness and restrictions, and independent `task-bigfiles` manifest passing.

## Budget breach

None.

## Merge record

- Implementation branch: `factory/task-histogram-002/1785900055647`
- Implementation commit: `aaa968c73fd7649f70a6a94e21f77a90bf6a778c`
- Detected at XSH commit: `aaa968c73fd7649f70a6a94e21f77a90bf6a778c`
- Implementation run: `runs/run-1785900054828/phases/01-ticket`

## Source eval and manager

- Eval: `task-histogram`
- Shared handbook lineage: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785899099112/phases/01-eval/lineage/handbook-approved.md`
- Manager run: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785899099112/phases/01-eval/workers/eval-manager/task-histogram/REPORT.md`
- Executor run: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785899099112/phases/01-eval/workers/eval-worker/task-histogram-1/run.json`
- XSH baseline commit: `a1cbb632d1ab8673176f6ef9f9d9cf04a7ad5e02`

## Observation

Sorting grouped streams by their key is a canonical aggregation pattern, but
`sort-by` rejects a `group-by` record's projected `key` field at check time
even when the key values are a supported scalar type:

    err[check.stream-sort]: sort-by keys must be Int, Str, Bool, Path, or a
    record of supported keys
      |> sort-by { |g| g.key }

The worker in `task-histogram` computed integer bins with `group-by` and then
tried the natural `group-by |> sort-by { |g| g.key }` ordering. The checker
rejected it because the group record's `key` field is exposed as a generic
type variable, not the concrete Int/Str of the source values. The worker had
to abandon the documented north-star path (group-by -> sort-by -> fold) and
instead rearrange into a `reduce(map.empty())` Map keyed by bin string, then
`keys()` -> `parse_int` -> `sort()`. This workaround is semantically correct
(all nine evaluator cases byte-exact) but no longer contains a `sort-by`
stage, so the evaluator's literal `source.contains("sort-by")` restriction
gate fails.

## Evidence

- Artifact: `workers/eval-worker/task-histogram-1/histogram.xsh` — final
  solution uses `sort()` on parsed integer keys, not `sort-by`.
- Checker rejection: `workers/eval-worker/task-histogram-1/session.jsonl`
  shows `err[check.stream-sort]: sort-by keys must be Int, Str, Bool, Path, or
  a record of supported keys ... |> sort-by { |g| g.key }`.
- Thinking: session turns where the agent reasons that `g.key` is a generic
  type variable (`g.key might be inferred as something else`) and therefore
  `sort-by` cannot confirm the key type, then pivots to the Map+`sort()` path.
- Evaluator: `workers/eval-worker/task-histogram-1/run.json` —
  `correctness.all_exact: true` but `restrictions.passed: false`
  (classification `restriction_failed`); the `restriction_ok` predicate in
  the package-own `evaluator.xsh` requires `source.contains("sort-by")`.
- Review: `workers/eval-worker/task-histogram-1/review.md`.
- Metrics: 41 thinking blocks, 17272 reasoning tokens, 0 tool errors.

## Diagnosis or hypothesis

This is a general XSH ergonomics/type-checker issue, not task-specific
confusion. Any eval that groups records and then orders them by the grouping
key (task-groupsum, task-ecount, task-logstat, task-colsum, task-histogram)
hits the same wall: `group-by` returns records whose `key` field is generic,
so `sort-by { |g| g.key }` is rejected even though the runtime values are a
supported scalar type. The agent must either re-project the key to a concrete
type through `map`/`parse_int` before `sort-by`, or leave `sort-by` altogether
and use a scalar `sort()`. In this eval that literal divergence caused a
restriction failure purely because of the missing `sort-by` spelling, despite
a fully correct program.

## North-star impact

Explicit, learnable stream boundaries are central to XSH. "Group, then order
by the group key" is everyday systems glue, and the current check-time
rejection makes the most natural spelling fail and pushes agents into
workarounds. This fixes an ergonomics/correctness hole in the checker/gradient
by either (a) accepting a concrete Int/Str group key in `sort-by` (projection
resolution), or (b) providing a documented, supported spelling for ordering a
grouped result by its key. Generalization evidence: the same pattern is
required by the grouped-aggregation eval family, so a replay across
task-groupsum / task-ecount against the fix should show the natural
`group-by |> sort-by` path compiling where it currently fails.

## Proposed XSH change
## API-surface justification

The semantic need — order a grouped stream by its group key — is already
expressible in principle through `sort-by`; the problem is that the group
record's `key` field is a generic type variable that the checker will not
confirm as a `sort-by` key, so the existing surface is insufficient for the
canonical pattern. No new keyword or constructor is warranted. The smallest
candidate fixes are a checker/type-directive change that resolves the groupby
key to its concrete scalar type before `sort-by` accepts it, or (if a
type-directed rule is not viable) a documented grammar/documented stage that
orders a grouped stream by `key`. Desugaring or a library helper would add
surface without removing the underlying type confusion, so a checker-side
projection resolution is preferred. Cost: checker/type-inference change plus
API-registry documentation (contract already lists Int/Str/... as supported
keys) and one native test that `group-by |> sort-by { |g| g.key }` checks on
Int and Str keys.

## Proposed XSH change

The smallest candidate implementation is a checker type-refinement fix: when
`sort-by`'s projected key is a field of a `group-by` record, resolve that
field to the concrete key type (e.g., the type of the grouping expression,
Int/Str/Bool/Path) instead of leaving it as an unresolved generic, so the
existing supported-key contract accepts it. If canonical group-key typing
cannot be inferred, document and add a supported spelling under
`language:stream.sort-by` (e.g., sorting on `g.key` after the group stage) and
add a native test. This change is not yet implemented; it is a candidate for
engineer dispatch next cycle.

## Acceptance criteria

- `group-by { |x| <Int expr> } |> sort-by { |g| g.key }` passes `xsht check`
  and orders ascending by key.
- Same for Str, Bool, and Path keys.
- `task-histogram` replayed on the fixed build reaches the documented
  north-star path (group-by -> sort-by -> fold) and satisfies the literal
  `sort-by` restriction gate, with all nine cases byte-exact.
- `task-groupsum` / `task-ecount` replayed to confirm generality.

## Scope and non-goals

- Not adding a new API method or keyword; this is a checker/projection
  refinement or documentation fix on the existing `sort-by`.
- Not changing the eval task contract or its oracle.
- Provider switching and timing are out of scope.

## Post-merge evaluation

Post-merge acceptance by `task-histogram` eval-manager on lineage
`runs/<merge-cycle>/phases/01-eval/lineage/handbook-approved.md` at the XSH
commit that merges this ticket, verifying the natural grouped-key `sort-by`
path compiles and the restriction gate passes; rejection requires the
workaround-only path to reproduce.
