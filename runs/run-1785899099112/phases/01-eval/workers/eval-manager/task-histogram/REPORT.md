# Eval-manager report

## Result

fail

## Effort metrics

One trial (`task-histogram-1`), electron model
`openrouter/deepseek/deepseek-v4-flash-0731`. The worker produced a single
byte-exact histogram artifact and a complete review.

- assistant_turns: 46 (1 user message, 45 toolUse stops + 1 final stop)
- tool_calls: 51 (46 bash, 3 read, 1 edit, 1 write); tool_results: 51
- tool_errors: 0
- thinking_blocks: 41
- session_span_ms: 390005 (agent_wall_ms 391542), ~6.5 minutes
- budget: 0.028945 US$ of a 0.5 budget

The session was efficient and converged: the worker reasoned about the
group-by vs Map alternatives in-stream, compiled the final Map+fold approach,
ran all validation branches (bad width, negative, hex, bad value), and emitted
a 13-line solution without repeated dead-end loops. No worker friction beyond
the single `sort-by` type rejection (see `## Observation classification`).

## Usage and cost

Provider-reported per the worker `report.json` (single agent, trial 1):

- input_tokens: 75025
- output_tokens: 25721
- cacheRead_tokens: 975744
- cacheWrite_tokens: 0
- reasoning_tokens: 17272 (provider-reported, subset of output; 41 thinking
  blocks)
- provider_total_tokens: 1076490 (bucket total 1076490; no mismatch)
- cost: input 0.006752, output 0.004630, cacheRead 0.017563, cacheWrite 0;
  total 0.028945 US$; cache_write cost 0
- budget_used: 0.028945 of 0.50

Reasoning tokens were reported by the provider; 17272 across 41 thinking
blocks. No unknown-cost fields.

## Thinking evidence

`thinking_blocks: 41` in the worker report, matching a reasoning score of
17272 tokens reported by the provider. The core reasoning sequence (session
turns) shows the worker correctly identifying that a `group-by` record's `key`
field is generic and therefore rejected by `sort-by`:

- `err[check.stream-sort]: sort-by keys must be Int, Str, Bool, Path, or a
  record of supported keys ... |> sort-by { |g| g.key }`
- Reasoned this was because `g.key` is a generic type variable (projection
  type confusion), then pivoted to a `reduce(map.empty())` Map keyed by bin
  string + `keys()` + `parse_int` + `sort()`.

The thinking is grounded and correlates with the final artifact, which is
correct on all nine evaluator cases. The one wrong hypothesis (that a
group-by key field would sort directly) was a genuine tooling-rejection
signal, not a correctness error.

## Tool-error findings

None.

The worker `report.json` reports `tool_errors: 0`; the phase `report.json`
`tool_errors` array is empty; the session JSONL has zero `isError:true`
results. There were no invalid `xsht api` queries recorded as tool errors in
this current session.

## Timing evidence

The eval contract has no strict candidate/oracle timing gate; timing is
diagnostic.

- public: cand 12.86 ms / oracle 16.20 ms
- hidden_width: 12.95 / 12.33
- hidden_many: 15.61 / 15.14
- hidden_sparse: 15.33 / 16.10
- hidden_single: 12.20 / 15.38
- hidden_ties: 10.91 / 14.17
- hidden_empty: 15.55 / 15.50
- hidden_bad_width: 15.13 / 15.54
- hidden_bad_value: 15.75 / 15.63

Candidate is at or below oracle timing on every passing case with no ratio
gate. `timings.passed: true`. No timing concern.

## Observation classification

- **Correctness: pass.** All nine cases (two failure controls included) are
  byte-exact; `correctness.all_exact: true`. The candidate correctly rejects
  `WIDTH=0` and the `12x` line (candidate exits 3, oracle exits 1/2 — both
  nonzero as required by the contract, so the failure controls pass).
- **Restriction: fail (reusable product signal).** The evaluator's
  `restriction_ok` gate requires a literal `sort-by` in the source. The worker
  never used `sort-by`; it tried `sort-by { |g| g.key }` and hit
  `err[check.stream-sort]` because a group-by record's `key` field is generic,
  then switched to `sort()`/`sort-by`-free Map+fold. This is a real, general
  XSH ergonomics issue: the most natural grouped-key ordering
  (`group-by` then `sort-by` on the projected key) is rejected at check time
  even for Int keys, forcing a workaround. It is reproducible (the check error
  is deterministic) and affects any eval that groups then orders by key.
- **Restriction: eval gate is literal.** The evaluator checks `source.contains
  ("sort-by")` as a string; a semantically-equivalent `sort` on parsed int
  keys does not satisfy it. Combined with the `sort-by` rejection above, the
  documented north-star path (group-by -> sort-by -> fold) is not reachable
  cleanly today.
- **Protocol: pass.** `review_ok: true`, both required headings present, no
  template placeholders, artifact present.
- **Worker friction: none material.** One failed `sort-by` probe, correctly
  diagnosed; ~6.5 min for a converged correct result.
- **Noise: none.**
- **Provider health:** `provider_telemetry.present: true`, retry_count 0,
  provider_errors [], retry_delay 0, output_tokens_per_second 0. No external
  latency signal; ~6.5 min span is not attributable to provider retries.
  Latency attribution: provider telemetry shows no errors/retries, so the
  span reflects normal agent work.

## Handbook decision

Provisional candidate staged at
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1785899099112/phases/01-eval/lineage/handbook-candidate.md`
(approved snapshot copied, one general paragraph added to the
"Streams and collections" section).

- General lesson: a `group-by` record's `key` field is generic, so
  `sort-by { |g| g.key }` is rejected at check time even for Int/Str keys;
  project the key to a concrete sortable type (parse_int/cast) before
  `sort-by`, or collect concrete keys and sort that list.
- Replay scope: this lesson is global and should be replayed by
  task-ecount / task-groupsum (group-by then order by key) before promotion to
  `runtime/handbook.md`. It removes repeated discovery of the same type
  rejection anywhere a grouped result must be ordered.

## Tickets created

One product ticket for the next cycle:

- `tickets/task-histogram-002.md` — `sort-by` rejects a group-by record's
  generic `key` field at check time even when the key values are a supported
  scalar type (Int), forcing a Map+`sort()` or parse-then-sort workaround and
  failing literal `sort-by` restriction gates. General XSH ergonomics issue,
  not a task-specific miss.

## Post-merge decisions

None. The controller reconciled no merged tickets for this eval this cycle
(merged-ticket list: `none`); the candidate re-evaluation field is
`not-reevaluation`, so no post-merge acceptance work applies.

## Next replay

Replay `task-histogram` and `task-ecount` (and `task-groupsum`) against the
provisional candidate on lineage `run-1785899099112/phases/01-eval/lineage/
handbook-candidate.md` once the CTO accepts the ticket and the sort-by
generic-key behavior is addressed or documented. If the sort-by key rejection
is a product defect, replay `task-histogram` should reach the documented
north-star path (group-by -> sort-by -> fold) and satisfy the literal
`sort-by` gate; otherwise the handbook candidate's sort-path guidance is the
falsification check.

## North-star impact

The eval correctly keeps correctness as the gate (all nine cases byte-exact),
but the run exposed a learnability/ergonomics defect in XSH's stream sorting:
the canonical grouped-key ordering idiom (`group-by` then `sort-by` on the
key) is rejected at check time for generic keys, so an agent must discover a
parse-then-sort workaround. This is exactly the kind of glue-language
boundary the factory is meant to make explicit: ordering grouped keys is
common systems work, and the rejection adds guesswork and pushes solutions off
the documented path. Fixing or documenting the group-key sort behavior, plus
the provisional handbook lesson, directly improves practical, learnable,
ergonomic XSH and reduces agent exploration on any grouped-aggregation eval.
