# Ticket task-ecount-007

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

- Eval: `task-ecount` (`evals/task-ecount/EVAL.md`)
- Shared handbook lineage: `runs/run-1785723986829/phases/02-reeval/lineage/handbook-approved.md` (approved `c7c9dd9a…`; candidate `handbook-candidate.md` unchanged)
- Manager run: `runs/run-1785723986829/phases/02-reeval/workers/eval-manager/task-ecount/session.jsonl`
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

- Worker session: `runs/run-1785723986829/phases/02-reeval/workers/eval-worker/task-ecount-1/session.jsonl`:
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
