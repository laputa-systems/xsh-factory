# Eval-manager report

## Result

pass

## Effort metrics

One trial (Trial 1). Worker `task-colsum-1`:

- assistant turns: 29
- tool calls: 34 (bash 28, read 3, edit 2, write 1)
- tool results: 34
- tool errors: 2
- session span: 148,822 ms (agent wall 150,187 ms)
- stop reasons: 28 x toolUse, 1 x stop
- user messages: 1

Worker friction is low for a short task: modest turn count, single coherent
development loop (read handbook/task -> xsht api discovery -> write -> check/
fmt/lint -> self-test against staged CSVs -> finalize). The two tool errors are
API-query syntax slips (see Tool-error findings) that the agent self-corrected
within a couple of turns; they did not extend the session meaningfully.

## Usage and cost

Provider: openrouter/deepseek/deepseek-v4-flash-0731 (worker), single model.

Per worker (Task 1):

- input tokens: 20,625
- output tokens: 7,057
- cache read tokens: 313,920
- cache write tokens: 0
- reasoning tokens: 3,752 (provider-reported; subset of output)
- provider total tokens: 341,602 (bucket total 341,602, no mismatch)
- cost: input $0.00185625, output $0.00127026, cacheRead $0.00565056,
  cacheWrite $0.00, total $0.00877707
- unknowns: 0
- budget: $0.5, no budget breach

Aggregate: 29 turns, 341,602 tokens, $0.00877707, one worker.

## Thinking evidence

17 thinking blocks in the worker session. Provider reported reasoning tokens
(3,752). Thinking is qualitative: the transcript shows the agent reasoning
through typed parsing (`Result`/postfix `?`) for per-cell integers and about
how to force a deliberate "missing header" failure when there is no generic
`Error` constructor — it converged on abusing `"not-a-number".parse_int()?`,
which is the handbook-documented idiom for this build. Correlated with the
artifact: the submitted `colsum.xsh` uses exactly that pattern for the
missing-header path. No evidence that thinking outweighed correctness.

## Tool-error findings

Two nonzero Pi tool results, both from the worker structured `tool_errors`
(manager session has no tool errors):

1. Turn 5 (`bash`): `xsht api api:method.Str.parse_int` -> invalid query
   `'api:method.Str.parse_int'; expected NAME.MEMBER`. Agent prefixed the
   method query with a stray `api:` (the companion `api:fs.read_text` in the
   same call resolved correctly). Agent corrected with `method:Str.parse_int`
   two turns later.
2. Turn 12 (`bash`): `xsht api language.core.results` and
   `xsht api language.core.postfix-question` -> invalid; `expected
   KIND:VALUE`. Agent used a dot separator instead of the `kind:value` colon
   form. Corrected next turn with `language:core.results`.

Both errors are invalid API-discovery query forms that the approved handbook
already warns against explicitly ("do not spend turns trying `api:...`,
dotted `language.core...` guesses"). No recorded provider errors; telemetry
present with `retry_count: 0`, `retry_errors: []`, `provider_errors: []`.

## Timing evidence

Candidate/oracle wall times per case (ms), all `exact: true`,
all candidate exits match oracle non-zero/zero contract:

- public: cand 12.7 / oracle 11.1
- hidden_order: 11.5 / 13.4
- hidden_negative: 12.4 / 11.3
- hidden_many: 11.2 / 12.4
- hidden_single: 13.3 / 11.8
- hidden_no_data: 10.8 / 11.4
- hidden_extra_cols: 12.7 / 12.3
- hidden_missing_header (fail): cand exit 3 / oracle exit 1, no output
- hidden_bad_value (fail): cand exit 3 / oracle exit 2, no output

No strict candidate/oracle timing gate for this eval; both sides finish in
milliseconds. Timing is diagnostic only and shows no anomaly. Session span
148.8s is separate from these per-program timings; with zero retries and no
provider errors, the ~2.5-minute session reflects the ordinary 29-turn
development loop, not provider latency.

## Observation classification

- Correctness: `pass` — all 9 cases byte-exact including both failure
  controls (candidate exits 3 on both, oracle 1/2 respectively, no stdout).
- Restriction: `pass` — source references `fs.read_text`, `parse_int`, no
  subprocess boundary, source and `review.md` present with required headings.
- Worker friction (handbook-covered): the two `xsht api` query-form slips
  (stray `api:` prefix and dotted `language.core.*` instead of `kind:value`).
  Non-recurring, self-corrected, already documented in the approved handbook.
  Reusable-signal: none new.
- Product observation (review.md proposal, classified ordinary, not a
  defect): the worker reviewer noted there is no generic fail/`Error`
  constructor, so a deliberate "missing header" failure must be forced through
  `parse_int()?`. This is already documented in the approved handbook
  ("This build has no generic `Error(...)` constructor..."). A first-class
  fail/Error constructor would be an ergonomic improvement in general, but
  this run produced no strong reproducible failure — the documented workaround
  is clean and the eval passed. No ticket opened.
- Evaluator/harness: no failures; protocol, review, and image matched.
- Noise: none significant.

## Handbook decision

Unchanged. Copied the approved snapshot verbatim to
`lineage/handbook-candidate.md` (SHA-256
`3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b`, identical
to approved). The only friction observed (invalid `xsht api` query forms) is
already covered by existing handbook guidance, so no new general lesson is
warranted from a single short passing trial. No candidate to replay.

## Tickets created

None.

## Post-merge decisions

Controller reconciler reported `none` merged tickets. No post-merge acceptance
assignments to decide.

## Next replay

No handbook candidate to promote. Optional: re-run `task-colsum` once more
across the shared handbook lineage to confirm the `xsht api` query-form
self-correction is stable and that the missing-header/fail-idiom workaround
remains valid under the pinned image; this would give a second data point for
generalization, but is not required for this passing trial.

## North-star impact

This eval sharpens a capability the approved set did not cover: selecting a
named column of a comma-delimited table and reducing only that column with
typed per-cell integer parsing (`parse_int`/postfix `?`) and no subprocess
escape — the modern XSH analogue of `awk -F,`. The passing run demonstrates
that typed `Result`/`?` transfers cleanly to a per-cell table boundary and
that header-indexing via ordinary stream/list logic is discoverable and
composable, with a loud nonzero exit for a missing header or malformed cell.
The clean, byte-exact nine-case pass (including both failure controls) is
evidence for practical, learnable, trustworthy XSH glue without hidden
evaluation or text sludge. No handbook or product change is triggered this
cycle.
