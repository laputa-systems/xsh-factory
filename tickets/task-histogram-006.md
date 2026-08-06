# Ticket task-histogram-006

## Status

Open.

## Change target

- `product`

## CTO review

- Review cycle: pre-cycle-2.
- Decision: Deferred; do not approve or dispatch.
- Basis: This observation was created by the latest independent eval while
  the engineer dispatch was still blocked. It needs a controlled replay after
  the boundary repair and is outside this narrow corrective cycle.

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
- Shared handbook lineage: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785972584122/phases/03-eval/lineage/handbook-approved.md`
- Manager run: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785972584122/phases/03-eval/workers/eval-manager/task-histogram/REPORT.md`
- Executor run: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785972584122/phases/03-eval/workers/eval-worker/task-histogram-1/run.json`
- XSH baseline commit: `1cf4ad3d7ee5fde9b3160b11d8073cbd7ce5e7c4`

## Observation

The stream filtering predicate stage is named `where`; there is no `filter`
stage. `xsht api language:stream.filter` reports `status: missing`, but calling
`filter { |x| ... }` in a pipeline is not rejected as an unknown stage — it is
re-parsed as a record literal and fails with a cascade of misleading parse
errors (`expected statement terminator`, `expected record field`,
`expected } after record`, and `unsupported operator '|'`), none of which names
`filter` or the intended `where` stage.

The `task-histogram` worker tried `filter { |line| line.trim() != "" }` to drop
blank measurement lines, hit this confusing parse-error cascade on the script
and on a minimal probe, then discovered the correct `where` stage only after
querying `xsht api language:stream.where`.

## Evidence

- Session: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785972584122/phases/03-eval/workers/eval-worker/task-histogram-1/session.jsonl`
  — `xsht api language:stream.filter` returns `status: missing`; a minimal
  probe `xs |> filter { |x| x.trim() != "" }` reproduces the record-literal
  parse-error cascade (turns around `23:37:46`–`23:37:58`); the working stage
  `where` is confirmed by `xsht api language:stream.where`.
- Review: `workers/eval-worker/task-histogram-1/review.md`, "xsht friction"
  item 1 ("There is no `filter` stream stage ... using it causes a confusing
  record-literal parse error. The working stage is `where` ...").
- Artifact: `histogram.xsh` uses `|> where { |line| line.trim() != "" }`.
- Evaluator: `run.json` — all nine cases byte-exact, restrictions `pass`,
  protocol `pass`.

## Diagnosis or hypothesis

This is a general XSH ergonomics/tooling issue, not task-specific confusion.
Stream stage names are tokens that a parser should recognize; an unknown or
missing stage name is a common agent mistake, yet the parse path falls through
to record-literal parsing and emits opaque, misleading errors that do not point
at the offending stage. Any eval that filters a stream with a guessed stage name
(`filter`, `select`, `grep`) hits the same wall. The handbook documents `where`
but not the absence of a `filter` alias, so the natural expectation is not
disambiguated. This mirrors the opaque-diagnostic theme already logged for
`fold` (`task-histogram-003`): the tooling surfaces an internal/literal-parse
error instead of an actionable stage-level diagnostic.

## North-star impact

Readable discovery is central to XSH ergonomics. A clear "no stream stage named
`filter`; use `where`" check-time diagnostic (instead of a record-literal parse
cascade) would let agents recover in one shot rather than reverse-engineering
the error, improving learnability and efficient agent use for every stream
eval. Generalization evidence: any eval that filters a stream should either
compile with `where` or produce a check error naming the invalid stage and the
`where` alternative, rather than a literal-parse confusion.

## Proposed XSH change
## API-surface justification

- Semantic capability not expressible today: although `where` already exists and
  works, the failure mode for a guessed stage name is an opaque literal-parse
  error rather than a readable "no such stage" message, so the discovery path is
  not usable.
- Closest existing spelling and why it is insufficient: `where` is the working
  stage; the insufficiency is purely in the diagnostic quality when an agent
  omits it. No runtime, type, or constructor surface is missing.
- Whether a desugaring/type-directed rule/library change solves it with less
  surface: this is a parser/checker diagnostic change on existing stream-stage
  token recognition — no new runtime, type, builtin, or syntax is required. The
  candidate requires no new API surface.
- Implementation and maintenance cost: recognize known stream stage names in the
  parse/check path and, when a pipeline stage token is not a known stage, emit a
  stage-level error naming the token and the closest stage (e.g. `where`) instead
  of falling through to record-literal parsing; add a native test and the
  `xsht api`/language-reference note that the filter stage is `where`.
- Evidence and falsification replay required before approval: a stream pipeline
  using `filter` must produce a clear stage-level check error, and the "fold to a
  record/list, then `where`/`each` to emit" solution must still pass
  `task-histogram` 9/9.

## Proposed XSH change

Smallest candidate: when a pipeline stage name is not a recognised stream stage,
reject it at `xsht check`/parse time with a clear diagnostic that names the
unrecognised stage and recommends `where` for filtering, instead of re-parsing
the stage block as a record literal and emitting the current misleading cascade.
Document that the filtering predicate stage is `where` (no `filter` alias).

## Acceptance criteria

- A script using `filter { |x| ... }` in a pipeline reports a readable
  stage-level error naming `filter` and the `where` alternative, not the
  `expected record field` / `expected } after record` cascade.
- The `where` form (block and implicit) keeps passing `xsht check` and
  `xsht lint`.
- `task-histogram` remains 9/9 byte-exact with the rewritten (`where` +
  fold/print-after) form.

## Scope and non-goals

- Non-goal: adding a `filter` alias (the handbook candidate and diagnostic
  guidance point to `where`; alias admission is a separate API-surface decision).
- Non-goal: changing stream semantics or runtime behavior.
- Non-goal: altering the eval task contract or its oracle.

## Post-merge evaluation

Post-merge acceptance by the `task-histogram` eval-manager on a future cycle's
lineage at the XSH commit that merges this change, verifying the `filter`
pipeline produces a readable stage-level error and the `where`-based solution
still passes all nine cases.
