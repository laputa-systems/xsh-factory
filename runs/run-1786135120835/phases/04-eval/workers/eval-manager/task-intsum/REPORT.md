# Eval-manager report

Eval: `task-intsum` (run `04-eval`, run_id `run-1786135120835`)
XSH commit under test: `857154dfe505f0d01053c1b5311f44422070eb34`
Trials configured/completed: 1 / 1
Handbook snapshot reviewed: `/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786135120835/phases/04-eval/lineage/handbook-approved.md`
(sha256 `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b`)
Candidate re-evaluation: `not-reevaluation`; Reconciled merged tickets: `none`.

## Result

pass

## Effort metrics

Trial 1 (worker `task-intsum-1`, model `openrouter/deepseek/deepseek-v4-flash-0731`):
assistant turns 19 (plus 1 user message), tool calls 20, tool results 20, tool
errors 0, thinking blocks 15. Tools used: bash 15, read 3, write 2. Session
span 124,025 ms; agent wall 128,308 ms; agent state `pass`. Budget state
`pass` ($0.5 budget). Worker friction: minimal. The two API-discovery touch
points (summary grep returning nothing; `not` rejected as negation) each cost a
single extra probe before the worker moved on; neither caused looped
exploration. 19 turns for a correct single-file program is efficient.

## Usage and cost

Trial 1 buckets (provider-reported): input 16,658; output 5,407 (reasoning
2,805 is a subset of output); cacheRead 209,152; cacheWrite 0; total bucket
tokens 231,217 (= provider_total 231,217; no mismatch). Dollars:
cost input $0.00149922, output $0.00097326, cacheRead $0.003764736, cacheWrite
$0, total $0.006237216. Budget $0.5; utilization ~1.2%. Reasoning tokens were
reported (2,805). No unknown-cost fields. Aggregate (1 trial) equals the above.

## Thinking evidence

15 thinking blocks in the session; provider reported `reasoning` tokens at
2,805 across the run. Findings grounded in `thinking.md`: the worker read the
handbook and task first, then discovered `Str.parse_int` behavior empirically
(including that it coerces `+5`, hex, and whitespace), which drove the decision
to add an explicit strict decimal regex so that `+5`, `0x1F`, and padded input
are rejected rather than silently coerced. Thinking correlated with the two
successful checks and the no-stdout-on-failure validation loop. Reasoning
tokens are provider-reported (not derived from text).

## Tool-error findings

None. The structured `tool_errors` arrays in the worker `report.json` (0) and
the phase `report.json` (0) are empty. The parse errors seen in the transcript
(`err[parse.expected-expression]` for `not`, and the runtime `parse-int:
invalid integer` traceback) are expected diagnostic feedback from `xsht check`
/ `xsh`, not failed Pi tool results.

## Timing evidence

No strict candidate/oracle ratio gate for this eval (timing is diagnostic).
Candidate vs oracle wall (ns):
public 11,791,810 vs 14,345,157; hidden_zero 13,675,487 vs 29,406,900;
hidden_neg 12,423,522 vs 16,164,749; hidden_large 12,431,147 vs 15,770,206;
hidden_mixed 30,896,032 vs 17,556,465 (candidate slower); hidden_malformed
17,870,882 vs 22,240,571. All candidate times are tens of ms; the mixed-case
candidate being the slowest is launch noise for a short program, not a gate
concern. Latency attribution: provider telemetry present (`present: true`) with
`retry_count 0`, `provider_errors []`, `response_elapsed_ms 0`. The referenced
`session.jsonl.events.jsonl` telemetry file is not present on disk, but no
retry or provider-error evidence exists; wall time is attributed to normal
short-task execution, not provider health.

## Observation classification

- `xsht api summary | grep Str` returns nothing because the summary is an
  indented module tree with counts, not flat `method.X.Y` ids.
  **Reusable handbook guidance** — strong, general, reproducible (two
  independent probes: `grep "method.Str"` and `grep -i "Str\."` both empty);
  affects every eval that tries type enumeration this way.
- Boolean negation is `!`, not `not`; `not expr` is a parse error. **Reusable
  handbook guidance / minor learnability** — `not` is a natural shell/Python
  guess and the handbook did not document negation; a one-line correction is
  warranted. Small, general, cross-task.
- No generic `Error(...)` / dedicated `fail` primitive, so a deliberate
  validation failure is expressed by forcing a typed conversion failure
  (`"bad-value".parse_int()?`). **Ordinary noise / already-documented** — the
  approved handbook already states there is no generic `Error` constructor and
  to use a typed conversion; the worker followed that and the eval passed. Not
  a new defect or ticket.
- Correctness, restrictions, protocol, review headings all `pass`; case-6
  malformed produces the expected nonzero exit with a trace to stderr and empty
  stdout. **Correctness signal** — no action.
- `+5`, `0x1F`, whitespace-padded integers rejected while `-7` accepted:
  matches the strict decimal contract. **Correctness signal** — no action.

## Handbook decision

Provisional candidate staged at
`/Users/josh/d/laputa-systems/xsh-factory/runs/run-1786135120835/phases/04-eval/lineage/handbook-candidate.md`
(sha256 differs from approved; see file). It is a copy of the approved
snapshot plus two concise, general edits: (1) corrects the API-enumeration
guidance so `xsht api summary | grep Str` is not recommended (the summary is a
tree with counts) and points to `search:TERM` / exact `method:X.Y` queries; (2)
documents that boolean negation is `!`, not `not`. Both are general lessons for
the shared factory-wide handbook, not task-specific recipes. The candidate is
NOT promoted to `runtime/handbook.md`; promotion requires re-review and replay.
Replay scope: re-run this eval and at least one other typed-boundary eval
(e.g. a regex or env-typed task) against the candidate to confirm the corrected
enumeration guidance and the `!` idiom reduce discovery friction without
changing correct behavior.

## Tickets created

None. The summary-grep and negation lessons are concise general handbook
edits (staged as the candidate), not product defects; no strong, general XSH
ergonomics bug merits a product ticket this cycle.

## Post-merge decisions

None. The reconciler found no merged ticket files for this run.

## Next replay

Re-run `task-intsum` (and one additional typed/API-discovery eval, e.g.
`task-histogram` or `task-dupcheck`) against the same XSH commit
`857154dfe505f0d01053c1b5311f44422070eb34` with the `handbook-candidate.md`
lineage to falsify or confirm the corrected enumeration and negation guidance
before promotion to `runtime/handbook.md`.

## North-star impact

This cycle demonstrates typed CLI glue done correctly: the worker summed argv
with a typed `parse_int()?` loop and an explicit strict decimal check, letting
a typed failure produce the nonzero exit rather than silently coercing `+5`,
`0x1F`, or whitespace. The run passed all public and hidden cases and is cheap
and low-friction, confirming the handbook's typed-boundary model is learnable
for this class of task. The staged candidate improves learnability and API
ergonomics by fixing two general discovery/idiom lessons (`xsht api summary`
is not a flat enumerator; negation is `!`) that will otherwise recur across
every eval, advancing the practical, learnable, ergonomic XSH north star.
