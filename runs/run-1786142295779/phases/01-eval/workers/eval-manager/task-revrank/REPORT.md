# Eval-manager report

## Result

fail

## Effort metrics

Single trial (Trial 1) against XSH commit `a248267612439dfcfa203fba583ac3e95d37f70c`.
Worker `eval-worker/task-revrank-1`:
- assistant turns: 61; user messages: 1
- tool calls: 74 (65 bash, 2 edit, 3 read, 4 write); tool results: 74
- tool errors: 0
- thinking blocks: 50
- session span: 489,703 ms (~490 s); agent wall: 492,221 ms
- stop reasons: 1 `stop`, 60 `toolUse`; wrapper state `completed`, agent_state `pass`,
  budget_state `pass`, reporting_state `pass`, evaluator_state `fail`.
- Worker `result: pass` refers to the session completing; the trial outcome is `fail`
  (run.json classification `restriction_failed`).

Efficiency judgment: no tool errors and zero provider retries, yet 61 turns / 74 tool
calls for a ~20-line task. The exploratory load is consistent with the worker
experimenting with `sort-by --desc`, a folding Map accumulator that hit an IR-encoding
blocker, and inference of `map.empty()` typing before settling on a `var` Map reassigned
inside an `each` loop. No tool-error friction. See Timing/Thinking sections.

## Usage and cost

Worker `task-revrank-1` (model `openrouter/deepseek/deepseek-v4-flash-0731`):
- input tokens: 88,722; output: 26,617; cacheRead: 1,335,616; cacheWrite: 0
- provider bucket total: 1,450,955; bucket sum (in+out+cacheRead+cacheWrite) = 1,450,955 (matches)
- reasoning tokens (provider-reported): 16,287 (subset of output; not added to total)
- cost USD: total 0.036817 (input 0.007985, output 0.004791, cacheRead 0.024041, cacheWrite 0)
- budget: 0.50, budget_state pass, no breach. Aggregate = same (1 trial).

## Thinking evidence

50 thinking blocks; the provider reported 16,287 reasoning tokens for the worker, so
reasoning-token counts are available. Thinking shows the worker: at turn 41 deliberating
whether `map.empty()` infers `Map[Int]` or `Map[Any]`; later trying a `fold`-based Map
accumulator that repeatedly throws `indexed IR could not encode full_ir_function_blocker`
and then abandoning fold for a `var` Map reassigned inside `each`; and weighing
`sort-by --desc` stability before adopting the ascending `{neg, region}` key. These
deliberations correlate with the high turn count and with the final source using
`map.empty()` (no literal `Map[Int]` annotation). The reported reasoning-token count is
provider-reported; the qualitative assertions above are grounded in `session.jsonl.bz2`
turns 41/94/98.

## Tool-error findings

None. The structured worker `report.json` lists `tool_errors: []`; the phase
`report.json` `data.tool_errors` is `[]`; the manager session has zero tool calls and
zero errors; `grep -c '"isError": true' session.jsonl.bz2` = 0. There are no failed Pi tool
results (including no invalid `xsht api` queries) in the current evidence packet.

## Timing evidence

No strict candidate/oracle timing gate (eval contract: timing is diagnostic). All cases
finish in low milliseconds. Candidate wall ns: public 10,980,983; multiproduct
11,916,742; tie 10,949,441; negative 12,762,501; order 13,123,254; many 12,301,330;
empty 12,736,917; bad_fields 11,920,826; bad_unit 11,445,072; missing 12,965,377. Oracle
comparable (10.9–13.4 ms). `timings.passed: true`. On failure controls the candidate
exits 3 and the oracle exits 2/1 — both nonzero with empty stdout, so the exactness rule
(pass on "both nonzero, empty stdout") is satisfied and not a gate.

## Observation classification

- **Harness mismatch (root cause of fail):** `restrictions.passed = false` solely because
  the evaluator requires the literal substring `"Map[Int]"` in the source
  (`evaluator.xsh`: `... and "Map[Int]" in source ...`). The EVAL.md documented contract
  for this gate is "a Map accumulation"; the submitted `revrank.xsh` performs a genuine
  Map accumulation via `map.empty()` + `totals.set(...)`/`totals.get(...)` (typed member
  reads, `read_text`, `parse_int`, `sort-by` all present, no forbidden subprocess).
  The detector is stricter than its own documented contract, producing a false-negative
  restriction failure on a correct, restriction-compliant-per-intent program.
- **Correctness (pass):** all ten cases exact; candidate stdout matches oracle byte-for-byte
  and all three failure controls exit nonzero with empty stdout.
- **Product-signal candidate (unverified, not a ticket this cycle):** the worker review and
  session report `sort-by --desc` not composing a stable compound descending order, and a
  cryptic `indexed IR could not encode full_ir_function_blocker` when folding a Map or using
  a multi-statement value-`if` inside a stream lambda. These are agent-authored,
  independently unreproduced claims; the eval's documented "two-pass ascending on negated
  key" idiom already sidesteps the descent case, and the submitted program is correct. Not
  strong enough for a product ticket without independent reproduction; recorded as signal
  for a future focused eval.
- **Agent effort (efficiency signal):** 61 turns with zero provider retries and zero tool
  errors; the exploration was driven by the friction above, not external health.
- **Provider health:** `provider_telemetry` present with `retry_count: 0`,
  `provider_errors: []`, `retry_errors: []` — no external-health confounder. Latency
  attribution is agent/exploration, not provider.
- **Noise:** none.

## Handbook decision

Unchanged. The approved snapshot was copied verbatim to
`runs/run-1786142295779/phases/01-eval/lineage/handbook-candidate.md` (identical,
confirmed by diff). No reusable lesson is justified: the failure is a harness/evaluator
restriction-detector mismatch, not a gap in XSH knowledge the handbook can teach. Adding a
rule like "always write an explicit `Map[Int]` annotation so restriction detectors pass"
would be a task-specific recipe aimed at a brittle literal check, contrary to the
north-star rejection of task-specific recipes. Replay scope: none for a handbook change
(snapshot preserved for the next trial of this eval under the same lineage).

## Tickets created

None (0). The cause is a harness/evaluator-detector mismatch, not a general XSH ergonomics
or correctness product defect, so no product ticket is opened. Per factory policy this is
reported as a factory/CTO finding (evaluator scaffold fix), not an engineer ticket and not
a factory-target ticket.

## Post-merge decisions

None. The reconciler reported zero merged ticket files (`none`) for this run; no
post-merge acceptance assignment exists.

## Next replay

After the CTO corrects the package-owned `evaluator.xsh` restriction detector so it
recognizes a Map accumulation (accept `map.empty`/`Map.set`/`Map.get`, or a typed
`Map[Str,Int]` annotation) rather than the literal `Map[Int]`, replay Trial 1 of
`task-revrank` against this same handbook lineage and XSH commit
`a248267612439dfcfa203fba583ac3e95d37f70c`. The unchanged `revrank.xsh` already passes all
ten correctness cases and the protocol gate, so it should then pass `restrictions` and the
trial should flip from `fail` to `pass` — this is the falsification check for the harness
finding. Also re-examine the `sort-by --desc` / IR-blocker product claims in a focused eval
if a future cycle wants to reproduce them independently.

## North-star impact

This run shows a correct, restrictions-compliant-per-intent XSH program (typed file read,
`parse_int` validation, keyed Map accumulation, `sort-by` ranking, no subprocess) being
marked `fail` solely by a brittle literal-substring restriction detector — a trust and
harness problem, not a product defect. Correctness of the submitted solution is intact, so
there is no evidence the agent or handbook needs a compatibility fix; the actionable
durable change is making the eval's restriction gate match its documented contract so that
valid, general XSH solutions are not rejected by an implementation artifact. Separately,
the high-turn exploration (61 turns, 50 thinking blocks) around map-type inference,
descent-rank stability, and an opaque IR-encoding error is a candidate fluency signal worth
pursuing in a dedicated, independently-verifiable eval before any handbook or product
change is trusted.
