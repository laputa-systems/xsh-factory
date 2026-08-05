# Ticket task-histogram-003

## Status

Open.

## CTO decision — post-cycle run-2

- Decision: Deferred; do not approve or dispatch.
- Basis: The observation is reproducible and has a complete API-surface justification, but it was created by the independent eval after admission and has not yet received a fresh controlled replay. Keep the safer pure-fold/list-then-each contract until a targeted diagnostic replay confirms the internal error on current merged HEAD.
- Next evidence: run a focused fold-with-print check and, if the opaque diagnostic persists, approve one bounded diagnostic-only implementation with the linked histogram replay.

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-histogram`
- Shared handbook lineage: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785900054828/phases/03-eval/lineage/handbook-approved.md`
- Manager run: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785900054828/phases/03-eval/workers/eval-manager/task-histogram/REPORT.md`
- Executor run: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785900054828/phases/03-eval/workers/eval-worker/task-histogram-1/run.json`
- XSH baseline commit: `a1cbb632d1ab8673176f6ef9f9d9cf04a7ad5e02`

## Observation

A `fold` (stream accumulator) block that contains a side effect such as
`print` fails at IR-build time with an internal, non-actionable diagnostic
rather than a check-time explanation:

    err[compact.indexed-build]: indexed IR could not encode
    `full_ir_function_blocker`
      proc main(...argv: List[Str]) [fs, error] {

The worker in `task-histogram` first wrote the natural cumulative-print
spelling — inside the `fold(0) { |acc, g| ... print ... }` that emits each
sorted bin line while building the running total — and it rejected at
`xsht check`. The only working route was to accumulate the formatted lines
into a list inside a pure `fold` block and emit them afterward with an
`each { |l| print $l }` stage.

## Evidence

- Artifact: `workers/eval-worker/task-histogram-1/histogram.xsh` — final
  solution folds into a `{total, lines}` record and prints via a separate
  `each` stage.
- Checker rejection reproduced twice in-session: `s2.xsh` and the first
  `histogram.xsh` draft both produced `err[compact.indexed-build]: indexed IR
  could not encode full_ir_function_blocker` (session turns around
  `03:36:38` and `03:36:43`).
- Review: `workers/eval-worker/task-histogram-1/review.md`, "XSH language
  proposals" section ("A fold combinator's block cannot contain a side effect
  such as print ... There is no obvious reason a fold body should be
  restricted from emitting output ... Either allow side effects in fold
  bodies or document a first-class cumulative fold stage.").
- Metrics: 42 assistant turns, 56 tool calls, 32 thinking blocks, 8427
  reasoning tokens, 2 tool errors (the lint.path-constructor and the
  nonexistent-fixture probes are separate, already-documented friction).

## Diagnosis or hypothesis

This is a general XSH ergonomics/tooling issue, not task-specific confusion.
Emitting a running aggregate (cumulative sum, prefix, running window) is a
canonical stream-reduction pattern, and `fold`'s accumulator block is the
natural place to emit each step. The build rejects that idiom not with an
actionable `check` message explaining that `fold` bodies must be pure (the
`each` stage exists for side effects) but with an internal `indexed-build`
IR error naming an internal blocker symbol. The opaque diagnostic gives the
agent no path forward and forces a workaround (materialize lines, print
afterwards) or a wrong guess. Any eval that folds into a printed running
aggregate hits the same wall.

## North-star impact

Clear, learnable stream boundaries are central to XSH. Either (a) allow
side-effecting fold bodies so `fold |> print-per-step` compiles, or (b) reject
it at `xsht check` with a readable message that names the pure-`fold`
constraint and points to `each` for side effects. The concrete, verifiable
improvement is a usable diagnostic in place of `full_ir_function_blocker`.
Generalization evidence: an eval that folds a running total and prints each
step should either compile (option a) or produce a clear check error (option
b) instead of an indexer-internal parse failure.

## Proposed XSH change
## API-surface justification

The semantic capability — emitting a running aggregate while reducing — is not
cleanly expressible today because `fold` bodies reject side effects and the
`each` stage does not maintain an accumulator across iterations at the block
level (the worker had to thread the running total through a record it
materialized and only then print). The closest existing spelling (pure `fold`
building a list, then `each` to print) works but is indirect and was
discovered only after the opaque error. Options: (a) make `fold` blocks able
to contain an `each`/`print`, which adds observable-side-effect surface to a
reduction (larger semantic change), or (b) keep fold pure and downgrade the
diagnostic from an indexer-internal `compact.indexed-build` failure to a
`check`-time error that explains the pure-`fold` constraint and recommends
`each` for output. Option (b) is the smallest, safest surface (compiler
diagnostic plumbing plus one native test) and is preferred unless a
first-class "cumulative fold" stage is separately requested. A desugared
`cumulative-fold` stage would add API surface without being necessary to fix
the opaque diagnostic.

## Proposed XSH change

Smallest candidate: when a `fold` (or any stream-block) body contains an
effect the indexed IR cannot encode, surface a `check`-time error explaining
that `fold`/reduce blocks are expected to be pure reductions and that output
should go through an `each { |...| print $x }` stage, instead of the internal
`full_ir_function_blocker` message. Optionally, document the "fold to a
list/record, then `each` to print" idiom under `language:stream.fold`.

## Acceptance criteria

- A script that prints inside a `fold` block reports a clear, actionable
  `xsht check` error (naming the pure-`fold` constraint and the `each`
  alternative) rather than `full_ir_function_blocker`.
- The pure `fold` -> `each { |l| print $l }` idiom keeps passing `xsht check`
  and `xsht lint`.
- `task-histogram` remains byte-exact on all nine cases with the rewritten
  (list-then-print) form.

## Scope and non-goals

- No new runtime semantics or language surface unless a cumulative-fold stage
  is separately requested.
- Not changing the eval task contract or its oracle.
- Not relaxing false/negative safety; the constraint may remain, only the
  diagnostic and documentation change.

## Post-merge evaluation

Post-merge acceptance by the `task-histogram` eval-manager on a future cycle's
lineage at the XSH commit that merges this change, verifying the fold-with-
print script produces a readable check error and the list-then-print solution
still passes all nine cases.
