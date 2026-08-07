# Eval-manager report

## Result

pass

## Effort metrics

One fresh trial (trial 1) executed by the controller. Editorial decision: this
eval's manager policy defaults to one trial and no `## Trial plan` raising the
count, so a single trial is the expected plan.

Trial 1 (`workers/eval-worker/task-svcstat-1/`):
- assistant turns 36, user messages 1
- tool calls 42: 35 bash, 3 read, 3 write, 1 edit; tool results 42
- structured tool_errors: 1 (see `## Tool-error findings`)
- session span 307,967 ms (worker `session_span_ms`); agent wall 309,212 ms
- agent_state, budget_state, evaluator_state, reporting_state, result all `pass`
- worker friction: early probe was rejected for missing the `error` effect on
  a `?` (`/tmp/probe.xsh`); the candidate helper lost several turns rediscovering
  that `?` needs a Result-returning context. Both are worker-side discovery
  friction, resolved within the trial, and the second is a reusable handbook
  lesson (candidate staged).

## Usage and cost

Trial 1 provider telemetry (provider-present, retry_count 0, provider_errors [],
retry_delay_ms 0):
- input tokens 60,272; output tokens 15,642; cache_read 679,040; cache_write 0
- provider total tokens 754,954; bucket total 754,954 (match)
- reasoning tokens 10,973 (provider-reported, subset of output; not added to total)
- thinking blocks 28
- cost: input $0.00542448, output $0.00281556, cache_read $0.01222272,
  cache_write $0, total $0.02046276; budget $0.50
- total cost for the run $0.02046276 (budget pass)

Reasoning token counts were reported (deepseek-v4-flash-0731, openrouter).

## Thinking evidence

28 thinking blocks across 36 turns; provider reported 10,973 reasoning tokens.
Grounding from `thinking.md`/session: the agent systematically enumerated
`line.fields()` behaviors, validated blank handling and field-count edge cases
(turn 39, 74, 76), then correctly designed grouped aggregation with
`group-by .service` + per-group `fold`. It intentionally exercised a
malformed-line probe, a no-`.log` empty tree, and an all-blank tree (turn 74)
before submission, and confirmed the aggregate math (`alpha 2 4`, `beta 2 7`,
`zeta 2 13`). The main rediscovery loop was the `?`-in-non-Result-returning-
procedure rejection (turn 44/47), which matches the single structured tool
error. Thinking is consistent with the correct final artifact and is
qualitative evidence of sound design, not of an inflated effort.

## Tool-error findings

The structured `tool_errors` array for the current sessions contains exactly
one nonzero Pi tool result:
- `workers/eval-worker/task-svcstat-1/report.json`, turn 12, tool bash:
  `err[check.effect-violation]: ? requires the error effect` for the probe
  `let files = fs.files(p"/work/logs")?`. This is a genuine failure that was
  immediately corrected by adding the `error` effect to the probe's signature
  (and later by returning `Result[Entry, Error]` from `parse_line`). It is
  worker discovery friction, not a product defect, and it already had a
  handbook basis (Effects and errors section); the Result-returning context
  nuance is the part not yet taught (see handbook decision).

The worker also issued several `api:...` discovery queries (`api:fs.files`,
`api:fs.read_text`, `api:fs.dirs`). These returned `status: exact` / `matches`
in-session (isError false), so they are not counted as tool errors. The manager
session recorded zero tool errors. Thus the single error above accounts for
every failed Pi tool result in the current evidence packet.

## Timing evidence

No strict candidate/oracle timing gate for this eval; the EVAL.md states timing
is diagnostic until a stable envelope is established. Per-case wall times
(ns):
- public 11054987 (oracle 11198322)
- hidden_single 12548924 (12879970)
- hidden_many 11168822 (12009083)
- hidden_nested 13078264 (12961679)
- hidden_idents 10947568 (12532882)
- hidden_blank 13369519 (12885053)
- hidden_empty 11988875 (11018694)
- hidden_malformed 11726912 (11231447)

All cases complete in ~11-13 ms on either side; candidate and oracle are within
~10% of each other and both are milliseconds. There is no ratio gate to enforce.
The `hidden_malformed` failure-control case: candidate exit 3 (nonzero, empty
stdout) vs oracle exit 1 (nonzero, empty stdout) — exact byte parity on the
expected-failure contract is satisfied (both fail, both print nothing), which
is what `expect_fail` checks.

## Observation classification

- Correctness signal (pass): all 8 cases byte-exact; `run.json` correctness
  `passed: true`, protocol `review_ok` true, restrictions passed, no forbidden
  subprocess, source uses `fs.files`, `group-by`, and `fold`. This is a clean
  demonstration of the eval's core hypothesis (keyed count+sum rollup across a
  file tree). Not noise.
- Worker friction (reusable handbook guidance): the `?`-requires-Result-
  returning-context rejection cost the agent several turns and one tool error.
  This generalizes beyond the task to any validation helper that must
  abandon-and-propagate, so it is staged as a handbook candidate rather than
  a product ticket.
- Worker friction (one-off): the missing-`error`-effect probe error is a
  single, self-correcting discovery and is ordinary friction, not reusable.
- Product/tooling signal: the reviewer's note (no generic `Error(...)`
  constructor, forcing `parse_int` into failure to signal validation) is a
  real ergonomic observation but is a design constraint of the pinned build
  rather than a reproducible defect against the XSH commit, and it is already
  consistent with the approved handbook's guidance ("this build has no generic
  `Error(...)` constructor"). Not opened as a product ticket this cycle.
- Timing: diagnostic only; no gate, noise-free, no agent-efficiency concern.
- No image/harness mismatch and no evaluator failure observed; all 8 cases,
  including `hidden_empty` and `hidden_malformed`, exercised cleanly.

## Handbook decision

Provisional candidate staged at
`lineage/handbook-candidate.md` (approved snapshot plus one sentence in the
Effects and errors section): postfix `?` is valid only in a Result-returning
context — a procedure that must abandon-and-propagate a validation failure
must return `Result[T, Error]` (or `Result[T]`), and a bare `?` in a proc whose
return type is not a Result is rejected even when that proc declares the
`error` effect.

This is a general XSH language rule, not a task recipe: it applies to any
helper that performs manual field validation and must fail the whole program,
so it should reduce repeated agent friction across validation-style evals
(task-svcstat, task-jsonfilter, task-groupsum, task-safepath). Replay scope:
the same eval and at least one other validation/aggregation eval against the
candidate lineage. Not promoted; promotion requires later replay and CTO
approval.

## Tickets created

None. The only meaningful observation (postfix `?` Result-returning context)
is handled by the handbook candidate; the missing-`Error`-constructor point is
a pinned-build design constraint already consistent with the handbook, not a
strong reproducible defect against this commit. Nothing warrants a product
ticket this cycle.

## Post-merge decisions

The reconciler found merged tickets: `none`. No post-merge acceptance
assignments to evaluate; no decisions required.

## Next replay

Replay `evals/task-svcstat` against the candidate handbook lineage
(`runs/run-1786142295779/phases/04-eval/lineage/handbook-candidate.md`) on XSH
commit `a248267612439dfcfa203fba583ac3e95d37f70c` to confirm the
Result-returning-context lesson removes the validation-helper discovery
friction while preserving byte-exact correctness. Because this is a
one-trial plan, the staged candidate was NOT independently replayed by the
controller this cycle; validation is pending a later trial. A falsification
check: if a future trial writes a validation helper that returns a non-Result
type and correctly avoids `?` (e.g. by building a Result explicitly), the
candidate sentence should be narrowed.

## North-star impact

This eval directly advances the practical, learnable systems-glue mission: the
agent produced a correct, subprocess-free, byte-exact keyed count+sum rollup
across a recursive file tree using typed `fs.files` discovery, `group-by`, and
an accumulator `fold` — exactly the kind of stateful aggregation the north
star wants XSH to be first-class. Correctness passed on all eight cases,
including the strict failure control (malformed line suppresses the entire
report with nonzero exit and empty stdout). The one staged lesson
(postfix `?` needs a Result-returning context) improves learnability and AI
efficiency by removing a repeated discovery cost, and the clean result
strengthens the evidence that stream grouping plus accumulator fold are
discoverable and composable, keeping the connection to clarity and
explicit boundaries explicit.
