# Controller-assigned engineer ticket

This is an immutable controller assignment for one implementation worker.
The controller, not the worker, selected the ticket, snapshot, worktree, and
branch.

## Assignment authority

- Ticket ID: `task-ecount-007`
- Ticket snapshot: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785805967215/phases/01-ticket/tickets/task-ecount-007.md`
- Ticket snapshot SHA-256: `73853ebc5302865881c90f8d4e6009464c1d9f7ebc9e54eebe32fecb994c0b44`
- Dedicated XSH worktree: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785805967215/phases/01-ticket/worktrees/task-ecount-007`
- Branch: `factory/task-ecount-007/1785805967997`
- XSH base commit: `e45dc69d301e9db44f9166f2abf0e7f9e1ab5bf9`
- engineer report: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785805967215/phases/01-ticket/workers/engineer/task-ecount-007/REPORT.md`
- Factory root: `/Users/josh/d/laputa-systems/xsh-factory`
- Run evidence root: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785805967215/phases/01-ticket`

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
# Ticket task-ecount-007

## Status

Approved.

## CTO review

- Review cycle: `pre-cycle-1785805851` (2026-08-03)
- Decision: Approved for the next two-engineer ticket cycle.
- Basis: `fold` has a reproducible parser/checker/runtime failure on the active
  build and a bounded contract can be established from the existing reference
  and minimal regression cases.
- Assignment boundary: Make one documented accumulator-plus-item form compile
  and run with a precise signature, or replace the internal IR blocker with a
  source-local diagnostic; preserve non-fold stream stages.

## Budget breach

None.

## Merge record

- Implementation branch: `{{IMPLEMENTATION_BRANCH}}`
- Implementation commit: `{{IMPLEMENTATION_COMMIT}}`
- Detected at XSH commit: `{{DETECTED_XSH_COMMIT}}`
- Implementation run: `{{IMPLEMENTATION_RUN}}`

## Source eval and manager

- Eval: `task-ecount` (`evals/task-ecount/EVAL.md`)
- Shared handbook lineage: `runs/run-1785723986829/phases/02-reeval/lineage/handbook-approved.md` (approved `c7c9dd9a…`; candidate `handbook-candidate.md` unchanged)
- Manager run: `runs/run-1785723986829/phases/02-reeval/workers/eval-manager/task-ecount/session.jsonl.bz2`
- Executor run: `runs/run-1785723986829/phases/02-reeval/workers/eval-worker/task-ecount-1` (trial 1)
- XSH baseline commit: `c2e1039d8856c04ad8466504d445dc93a341f720` (task-ecount-003 candidate under replay, image `sha256:76930780c3bf09e97756da287144da95e913bc0bd703bc5c8307f771238d572b`)

## Observation

The `fold`/`reduce` stream stage cannot express an accumulator-plus-item
reduction in the gym runtime, and one close variant crashes the compiler with
an internal IR error instead of a diagnostic. The handbook tells agents to
query `xsht api language:stream.fold` when a stage's block semantics matter,
and the reference lists `fold` with a contract, but every accumulator form the
task-ecount worker tried failed:

- `items |> fold({ |acc, it| acc.set(it, acc.get(it, 0) + 1) }, {})` and the
  pipe-method variant `items.fold(block, init)` fail at parse time with
  `err[parse.expected-record-field]` / `expected-token` / `expected-expression`
  cascades (the `{ |acc, it| … }` inside the call parens is misread as a
  record literal).
- `items |> fold(init) { |acc, it| … }` fails check time with
  `err[check.stream-block-params]: stream stage blocks accept at most one
  parameter`.
- `items |> fold { |init, it| … }` fails check time with
  `err[check.arity]: fold/reduce expects an initial value`.
- `items |> fold(0) { |x| x }` (the only accepted arity shape) crashes the
  compiler with `err[compact.indexed-build]: indexed IR could not encode
  `full_ir_function_blocker``, located at the `proc main` signature line with
  no source mapping.

The worker abandoned `fold` and assembled counting from `group-by` records
(`key`/`items`), which required extra discovery because `group-by`'s return
shape is undocumented (already tracked in task-ecount-001). The reference entry
`language:stream.fold` carries no signature and no example, so block arity,
argument order, and result shape are not discoverable from the documented
source of truth.

## Evidence

- Worker session: `runs/run-1785723986829/phases/02-reeval/workers/eval-worker/task-ecount-1/session.jsonl.bz2`:
  - line 82 (`isError: true`): `fold({ |acc, it| … }, {})` parse-error cascade (structured tool error, turn 37).
  - line 96: three more `fold` forms fail with `check.stream-block-params` / `check.arity` / parse errors.
  - line 110: `fold(0) { |x| x }` → `err[compact.indexed-build]: indexed IR could not encode `full_ir_function_blocker``.
  - lines 101 and 107 (thinking): the worker reasons through the arity rules, tries `fold(0) { |x| x }`, hits the IR crash, and pivots to `group-by`.
- Worker review: `runs/run-1785723986829/phases/02-reeval/workers/eval-worker/task-ecount-1/review.md`, section `## XSH language proposals` — "Stream stage blocks accept at most one parameter, and `fold`/`reduce`'s accumulator-plus-item binding is undocumented and effectively unusable here: `fold(init) { |acc, it| ... }` fails with `check.stream-block-params` (at most one parameter), `fold { |a, b| ... }` fails with `check.arity` (expects an initial value), and a close variant crashed the compiler with `compact.indexed-build`/`full_ir_function_blocker` (an internal IR error with no source mapping)."
- Handbook contract: `runs/run-1785723986829/phases/02-reeval/lineage/handbook-approved.md`, Streams section — "Common stages include where, map, sort-by … Query their language references when the stage's block or ordering semantics matter: `xsht api language:stream.fold`".
- Quantitative metrics: `run.json` `result: pass`, `correctness.exact_output: true`, `restrictions.passed: true`; the eval still passed because the worker substituted `group-by` — the defect is the unusable documented stage, not the eval result.

## Diagnosis or hypothesis

`fold` is advertised as a first-class stream stage but its accumulator
contract is unimplementable through any call shape the parser/checker accepts:
two-parameter blocks are globally rejected (`check.stream-block-params`), the
no-init form is rejected (`check.arity`), and the one-parameter-with-init form
crashes the compact indexed-IR builder. The reference entry has no signature or
example, so the stage's intended binding cannot be learned from `xsht api`.
This is a general correctness/learnability defect, not an ecount recipe: any
eval or user script that wants a left fold over a stream must either guess the
undocumented shape, work around it with `group-by`, or accept an internal
compiler error with no source mapping. The `full_ir_function_blocker` text is
the same internal blocker seen in open tickets task-ecount-002 (positional
optional arguments) and task-ecount-006 (direct `collect()` of a module
stream); the fold trigger may share the indexed-IR root cause, but the primary
fold defect is the arity/parse contract, which is independent.

## North-star impact

The north star asks for a typed, composable glue language where "boundaries,
types, errors, and data flow are explicit" and agents avoid "repeated
discoveries". A stage the handbook names as a query target that cannot be used
for its documented purpose — with one variant leaking an internal IR error
located at the wrong line — forces exactly the trial-and-error loop the
factory exists to remove and undermines trust in `xsht check`. Making
`fold(init) { |acc, it| … }` work (or, if accumulator blocks are intentionally
unsupported, documenting that and making every other form fail with a
diagnostic naming the stage) would let an agent accumulate directly instead of
reassembling counting from `group-by` records. Evidence of generalization: any
pipeline eval where an agent counts or accumulates would either use a
first-class `fold` or receive a clear contract, never an internal IR crash.

## Proposed XSH change

Smallest candidate, one of:

1. Support an accumulator-plus-item block for `fold`/`reduce` (e.g.
   `fold(init) { |acc, it| … }`), with a documented signature and an example
   in `language:stream.fold`, matching the runtime semantics; or
2. If accumulator blocks are intentionally unsupported in this build, reject
   every non-supported `fold` form at check time with a clear diagnostic
   naming the stage and the actual limitation, and never emit
   `full_ir_function_blocker`; update the `xsht api` reference to state the
   supported block arity and add a working example.

In both cases, add regression tests for each call shape (parse, check, and
runtime) and confirm `xsht check` and `xsh` agree on every accepted/rejected
form.

No change to other stream stages or to sort semantics (task-ecount-003/004).

## Acceptance criteria

- `items |> fold(0) { |acc, it| acc + it }` (or the documented accumulator
  form) compiles and returns the correct sum, or every unsupported form is
  rejected at check time with a diagnostic naming `fold` and the block
  limitation — never `err[compact.indexed-build]` / `full_ir_function_blocker`
  and never a parse cascade about record fields.
- The reference `xsht api language:stream.fold` states the block signature
  (parameter count and meaning), argument order, and result shape, with a
  working example.
- `xsht check` and `xsh` agree on every `fold` form (no checker-accepts /
  runtime-fails split, and no runtime-crashes-after-check-accepts split).
- A replay of `task-ecount` on the merged change still byte-for-byte matches
  the `fd | awk | sort | uniq -c | sort -n` oracle, and a worker may count via
  `fold` without a discovery loop or the `group-by` workaround.

## Scope and non-goals

- No change to `group-by` semantics, stream ordering, or the sort contract.
- Not an ecount shortcut; the fix must generalize to every `fold`/`reduce`
  use.
- The separate `full_ir_function_blocker` triggers (positional optional
  arguments, direct module-stream `collect()`) are tracked in task-ecount-002
  and task-ecount-006; fix them together only if they share a root cause.
- No change to the shared agent handbook inside XSH; the factory lineage owns
  the agent-facing handbook.

## Post-merge evaluation

The `task-ecount` eval-manager will run a controlled replay against the merged
XSH commit using the current approved handbook lineage, verify the `fold`
forms and reference text described in the acceptance criteria, and record
acceptance or rejection in that run's manager report.

<!-- CONTROLLER_TICKET_SNAPSHOT_END -->

## Factory context required before coding

The factory documents below are outside the XSH worktree. Before coding, use
the `read` tool on each exact absolute path. This is required so the session
JSONL proves that the worker consumed the current factory guidance:

- North star: `/Users/josh/d/laputa-systems/xsh-factory/NORTH-STAR.md`
- Shared handbook: `/Users/josh/d/laputa-systems/xsh-factory/runtime/handbook.md`

Then use the `read` tool on the product worktree's exact guidance files:

- Product agent guide: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785805967215/phases/01-ticket/worktrees/task-ecount-007/AGENTS.md`
- XSH rationale: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785805967215/phases/01-ticket/worktrees/task-ecount-007/docs/CHAPTER-01-why-xsh.md`

## Implementation contract

Work only in `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785805967215/phases/01-ticket/worktrees/task-ecount-007` on branch `factory/task-ecount-007/1785805967997`. Do not edit XSH main, the
factory main tree, or the ticket diagnosis. Make the smallest general XSH
language, tooling, test, or canonical-documentation change supported by the
ticket. Run the narrowest relevant checks, commit the product change on this
branch, and leave the worktree clean.

The controller has staged a fail-closed `not-ready` report at
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785805967215/phases/01-ticket/workers/engineer/task-ecount-007/REPORT.md`. Complete that file in place; do not spend turns
reconstructing its headings. Keep `## Result` as `not-ready` until the
acceptance checks, commit, and clean-worktree validation are complete.

Write `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785805967215/phases/01-ticket/workers/engineer/task-ecount-007/REPORT.md` with these exact headings:

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
