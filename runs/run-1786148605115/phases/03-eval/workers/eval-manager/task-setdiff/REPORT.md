# Eval-manager report

## Result

pass

## Effort metrics

Trial 1 (only configured trial, `task-setdiff-1`): result `pass`. 37 assistant
turns, 43 tool calls (35 `bash`, 3 `edit`, 4 `read`, 1 `write`), 43 tool
results, 2 tool errors, 1 user message. Session span 113,516 ms (agent wall
114,706 ms). Worker friction: both tool errors were recoverable within the
loop (see Tool-error findings); no repeated re-exploration beyond the targeted
negation discovery.

## Usage and cost

Trial 1 buckets (provider-reported): input 24,809; output 8,466; cacheRead
528,384; cacheWrite 0; bucket total 561,659 (matches provider total 561,659).
Reasoning tokens 3,434 (subset of output). Cost: input $0.00223281, output
$0.00152388, cacheRead $0.009510912, cacheWrite $0, total $0.0132676 (bucket
sum 0.013267602 matches reported). Budget $0.50, no breach. Aggregate = the
single trial values; one worker.

## Thinking evidence

32 thinking blocks across the session; provider reported reasoning tokens
(3,434), so reasoning-token counts are available and not estimated. Thinking
was concentrated on discovering the predicate-negation idiom (`== false`),
recovering from the `Path(...)` lint warning, and verifying the final
byte-for-byte contract.

## Tool-error findings

Two nonzero Pi tool results from the structured `tool_errors` array (both
`bash`):
1. Turn 10 (parse): `setdiff.xsh` failed `xsht check` with
   `parse.expected-expression` at `|> where { |l| not bSet.has(l) }` and
   follow-on cascade errors. Root cause: unary `not` is not a keyword in this
   build; the agent replaced it with `bSet.has(l) == false`.
2. Turn 23 (lint): `xsht lint` returned code 1 with
   `warn[lint.path-constructor]` preferring `fp"${argv[0]}"` over
   `Path(argv[..])`. The agent corrected to `fp` interpolation and re-checked.
Both were self-corrected; the final artifact passes check/fmt/lint and the
evaluator.

## Timing evidence

Correctness, protocol, restrictions, and timing all `pass` in `run.json`.
EVAL.md sets no strict candidate/oracle timing gate: both sides complete in
milliseconds, so timing is diagnostic only. No per-case timing table was
emitted beyond the pass state; latency attribution is `unknown` (no explicit
provider retry/error events; the telemetry events file was absent), so
efficiency is judged from turns, tokens, tool calls, and correctness.

## Observation classification

- Correctness: pass (all success cases byte-exact, both missing-file controls
  exit nonzero, per `run.json` exact/correctness and the evaluator).
- Restriction: pass (uses `set.from`/`set.has`, `fs.read_text`, `Str.lines`,
  `sort-by`; no subprocess boundary).
- Reusable handbook guidance (strongest signal): predicate negation in a
  `where` block requires `expr == false`; this build has no unary `not`/`!`.
  This is general (any predicate negation, not just set difference) and was
  the session's main friction (tool error + several failed `xsht api
  search:negation/not/invert/boolean` probes).
- Product/tooling ergonomics signal (not filed this cycle): the language gap +
  absence of any discoverable negation entry is a real learnability/ergonomics
  gap, but one session's evidence is not yet the multi-session "strong
  reproducible" bar for an engineer ticket.
- Worker friction (minor, not a handbook gap): `Path(...)` lint warning came
  from ignoring existing fp guidance; the handbook already teaches
  `fp"${expr}"` as lint-preferred.
- Ordinary noise: none meaningful.

## Handbook decision

Provisional candidate staged at
`runs/run-1786148605115/phases/03-eval/lineage/handbook-candidate.md`: add one
sentence to `## Streams and collections` teaching predicate negation via
`== false` (no unary `not`/`!`). General lesson: when a `where` predicate must
be inverted in this build, compare the boolean result with `== false`. Replay
scope: re-run `task-setdiff`, and any eval exercising predicate negation
(e.g. `task-dupcheck`, `task-histogram`), against this candidate lineage before
promotion to `runtime/handbook.md`. Not yet trusted; one-trial provisional.

## Tickets created

None. Current evidence is a single passed trial; the friction is addressed by
the staged handbook candidate. A product ticket for unary boolean negation is
deferred until a second replay confirms the discoverability gap (would then
target a general ergonomics change, not this eval's workaround).

## Post-merge decisions

None. The reconciler found no merged tickets (`none`); the candidate
re-evaluation is `not-reevaluation`. No post-merge acceptance action.

## Next replay

Replay `eval_id=task-setdiff` against the candidate handbook lineage
(`runs/run-1786148605115/phases/03-eval/lineage/handbook-candidate.md`) on a
post-fix or next-cycle basis to falsify/confirm the `== false` negation
lesson and to decide whether the unary-negation ergonomics gap warrants a
product ticket.

## North-star impact

Confirms the `set` module (`set.from`/`set.has`) and `Str.lines` trailing-
newline semantics are discoverable and composable for a real reconciliation
workflow (the typed replacement for `comm -23 <(sort -u ...)`), advancing
practicality and learnability. Stages a general predicate-negation lesson that
should remove guesswork for any inverted `where` predicate, and records the
unary-negation ergonomics gap as a candidate-signal for future product
decisions without over-claiming on one session.
