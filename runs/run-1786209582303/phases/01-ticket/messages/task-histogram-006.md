# Controller-assigned engineer ticket

This is an immutable controller assignment for one implementation worker.
The controller, not the worker, selected the ticket, snapshot, worktree, and
branch.

## Assignment authority

- Ticket ID: `task-histogram-006`
- Ticket snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786209582303/phases/01-ticket/tickets/task-histogram-006.md`
- Ticket snapshot SHA-256: `c0d3a469494b9a99ac5e159adc44aa5d284771ee3a2823e861bf1907d3d0bb4a`
- Dedicated XSH worktree: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786209582303/task-histogram-006`
- Branch: `factory/task-histogram-006/1786209590202`
- XSH base commit: `26d59eb844b670365931d91ffb15ae8c109bae12`
- engineer report: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786209582303/phases/01-ticket/workers/engineer/task-histogram-006/REPORT.md`
- Factory root: `/Users/josh/d/laputa-systems/xsh-factory`
- Run evidence root: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786209582303/phases/01-ticket`

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
# Ticket task-histogram-006

## Status

Approved.

## CTO review — cycle 24 close

- Decision: Approved for implementation in the next organization cycle.
- Basis: The observation has reproducible focused-eval evidence, a narrow
  diagnostic-only product scope, explicit non-goals, and a falsification path
  that preserves the existing `where` behavior. The prior deferral required a
  controlled replay after dispatch repair; cycle 24 now provides that repaired
  dispatch boundary and the linked replay remains a hard merge gate.
- Scope: Improve the parser/check diagnostic for an unknown stream stage such
  as `filter` so it names the stage and recommends `where`; do not add a
  `filter` alias or change stream semantics.
- Evidence: The existing task-histogram worker session, review, and evaluator
  manifest linked in this ticket, plus the repaired organization/replay
  machinery validated by cycle 24's `task-grep-001` delivery.

## CTO decision — clean-slate cycle 2026-08-07

- Decision: Deferred; do not approve or dispatch.
- Basis: `runs/` was intentionally reset, so this single-eval parser
  observation has no fresh focused replay or cross-eval confirmation. Keep it
  Open. pending that evidence.

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

## CTO decision — pre-cycle 2026-08-06

- Decision: Deferred; do not approve or dispatch in this cycle.
- Basis: The observation was produced during the dispatch-repair period and
  lacks cross-eval confirmation. Preserve it as Open. pending a controlled
  replay; do not spend an engineer row this cycle.

## CTO preparation — 2026-08-06

- Selected implementation path: diagnostic-only recognition of unknown stream
  stages, naming `filter` and recommending `where`.
- Do not add a `filter` alias or alter stream semantics. Approval still
  requires the focused parser replay described above.

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

- Session: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785972584122/phases/03-eval/workers/eval-worker/task-histogram-1/session.jsonl.bz2`
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

<!-- CONTROLLER_TICKET_SNAPSHOT_END -->

## Factory context required before coding

The factory documents below are outside the XSH worktree. Before coding, use
the `read` tool on each exact absolute path. This is required so the session
JSONL proves that the worker consumed the current factory guidance:

- North star: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786209582303/phases/01-ticket/guidance/NORTH-STAR.md`
- Approved handbook snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786209582303/phases/01-ticket/guidance/handbook.md`
- Handbook candidate: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786209582303/phases/01-ticket/lineage/handbook-candidate.md`

The approved snapshot is a run-scoped copy of the checked-in handbook. Read it
as an input and never edit it or the checked-in handbook. If this ticket
produces a reusable lesson, add it to the run-scoped candidate path above; the
candidate is shared review input and is promoted only after CTO review. If no
handbook improvement is justified, leave the candidate unchanged.

Then use the `read` tool on the product worktree's exact guidance files:

- Product agent guide: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786209582303/task-histogram-006/AGENTS.md`
- XSH rationale: `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786209582303/task-histogram-006/docs/CHAPTER-01-why-xsh.md`

## Implementation contract

Work only in `/Users/josh/d/laputa-systems/.xsh-factory-worktrees/run-1786209582303/task-histogram-006` on branch `factory/task-histogram-006/1786209590202`. Do not edit XSH main, the
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
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786209582303/phases/01-ticket/workers/engineer/task-histogram-006/REPORT.md`. Complete that file in place; do not spend turns
reconstructing its headings. Keep `## Result` as `not-ready` until the
acceptance checks, commit, and clean-worktree validation are complete.

Write `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786209582303/phases/01-ticket/workers/engineer/task-histogram-006/REPORT.md` with these exact headings:

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
