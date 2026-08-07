# Eval-manager report

## Result

pass

## Effort metrics

Trial 1 (`task-histogram-1`, 1-trial plan): 50 assistant turns, 61 tool calls
(57 bash, 2 read, 1 edit, 1 write), 0 tool errors, 61 tool results, 0
malformed session lines. Session span 552,667 ms (~9.2 min); agent wall
553,856 ms. Stop reasons: 1 `stop`, 49 `toolUse`. The worker reached a
correct, byte-exact 9/9 solution and completed `review.md`, so friction was
bounded and did not threaten the budget (0.5 USD cap untouched).

## Usage and cost

Trial 1 provider-reported buckets: input 119,238; output 17,990; cacheRead
818,688; cacheWrite 0; bucket total 955,916; provider total 955,916 (match).
Reasoning tokens reported: 9,861 (subset of output). Cost: input $0.01073,
output $0.00324, cacheRead $0.01474, total $0.02871. Budget $0.50, no breach.
Phase aggregate equals the single trial: 50 turns, `cost_usd` 0.028706004,
total bucket tokens 955,916, `tool_errors` 0.

## Thinking evidence

40 thinking blocks recorded in `session.jsonl.bz2` (assistant `thinking` blocks);
provider reported 9,861 reasoning tokens. There is no standalone
`thinking.md`; the provider-reported reasoning-token count is present, so
thinking-token evidence is available (not unavailable). The thinking paired
with the tool-call transcript documents the record-literal and integer-division
discovery loops (turns 36-48) rather than unexplained blade-churn; correctness
of the final artifact is independently confirmed by the evaluator, so the
thinking is qualitative evidence of a deliberate, discover-then-verify loop.

## Tool-error findings

None. The structured worker `report.json`, phase `report.json`, and both
`tool_errors` arrays are empty (0 errors); the session JSONL contains zero
`isError:true` tool results. The permissive discovery probes that used the
dot form (`xsht api method.Str.parse_int`) or wrong module/`api:` prefixes
returned bash-level `status: missing` / `status: not-found` text inside their
stdout and exited 0 (they were piped through `| head` / `2>&1`), so they are
discovery friction, not failed Pi tool results, and do not appear in the
structured error arrays.

## Timing evidence

Candidate/oracle wall per case (both ~11-13 ms): public, hidden_width,
hidden_many, hidden_sparse, hidden_single, hidden_ties, hidden_empty — all
`exact: true` with exit 0. hidden_bad_width: candidate exit 3 vs oracle exit 1;
hidden_bad_value: candidate exit 3 vs oracle exit 2 — both nonzero and both
print nothing, and stdout comparison is byte-exact. `timings.passed` true.
This eval has no strict candidate/oracle ratio gate; timings are diagnostic
only. Latency attribution: `unknown` for wall-clock purposes — the
`session.jsonl.events.jsonl` referenced by `provider_telemetry` is absent, so
derived output tokens/s and response elapsed are 0/unavailable; `retry_count`
0 and `provider_errors` empty give no external-health signal, and 50 turns /
955,916 tokens over 9.2 min is not an agent-latency concern.

## Observation classification

- **Correctness: pass.** All nine cases byte-exact; both failure controls exit
  nonzero and print nothing; source uses `fs` typed read (`fp"${file}".read_text()`),
  `parse_int`, and a `sort-by` stage, satisfying the restriction checks. Not noise.
- **Worker friction (reusable handbook gap):** integer division and record
  literals. Grounded in turn 36-48 of `session.jsonl.bz2`: `/` on Int returns the
  truncated quotient (`17 / 5 -> q=3 r=2` probe), `//`/`div` are parse errors;
  `{run: 0, lines: []}` and `type Accum = {run: Int, lines: List[Str]}` both
  fail with `expected record field`/`expected schema field name` while a
  declared-type literal with non-reserved names (`type Config`/`demo`) parses.
  Reusable signal: teaching the `/`-on-Int operator, the declared-type
  requirement, and the reserved `run`/`lines` names removes recurring
  discover-and-verify turns across any record/division task.
- **Worker friction (API discovery):** multiple `xsht api` probes with the dot
  form (`method.Str.parse_int`, `module.fs.read_text`) and invalid `api:`/
  `search:` guesses returned `status: missing`. The handbook already documents
  the `method:`/`module:`/`language:`/`search:` forms; this is ordinary
  discovery cost on a fresh task, not a new handbook gap.
- **Product/tooling defect (ticket):** record-literal parsing is
  over-restrictive and mis-diagnosed — see `task-histogram-008`.
- **Product signal already covered:** no unsigned parser and forced-failure
  idiom (004/005), `where` vs `filter` (006), fold-print (003), and explicit
  integer division (007) are already open tickets; no duplicate created.
- **Ordinary noise:** none material.

## Handbook decision

Provisional candidate staged at
`lineage/handbook-approved.md` -> `lineage/handbook-candidate.md` (approved
hash `3b56a781…`, candidate hash `ce6a8e8d…`; diff is one added section only).
The candidate adds a concise, general "Arithmetic and record literals" note:
`/` is integer division on Int with no `//`/`div`; `Str.parse_int()` trims and
accepts a sign, so strict digit contracts need a regex check; record literals
require an explicit declared type, `run`/`lines` are reserved field names, and
a type used only to permit a literal must be referenced or `xsht lint` reports
`unused-type`. These are global XSH facts that remove repeated agent discovery,
not task recipes. The integer-division claim is the same evidence tracked by
open ticket `task-histogram-007`; the record-literal guidance is independent.
Replay scope before promotion: re-run `task-histogram` (and a second
record/division eval) against the candidate and confirm the worker reaches the
9/9 solution with fewer discovery turns and without the `method.`/`module.`
query and record-literal probe chains. Single-trial evidence only; promotion
requires later replay and CTO approval.

## Tickets created

- `tickets/task-histogram-008.md` (product): record-literal parsing
  ergonomics — record literals require an explicit declared type, `run`/`lines`
  are reserved field names producing a cryptic `expected record field` error,
  and a record type used only to enable a literal's parse trips `xsht lint
  unused-type`. Links this eval, manager run, executor run, handbook lineage,
  and XSH baseline `1477f472d5b4d57db3584357116ef97c32358ab6`.

No other tickets; integer division (007) and the other recorded observations
are already tracked and are not re-filed.

## Post-merge decisions

None. The reconciler found no merged ticket files for this cycle; there are no
post-merge acceptance assignments to adjudicate.

## Next replay

Replay `task-histogram` (9/9 byte-exact) against the staged candidate handbook
`lineage/handbook-candidate.md` to test whether the added "Arithmetic and
record literals" section removes the division/record discovery turns, plus a
second record- or division-heavy eval to confirm the guidance generalizes
before promotion to `runtime/handbook.md`. Separately, when open tickets
003-007 reach an accepted implementation commit, each becomes a post-merge
acceptance replay of this eval.

## North-star impact

The run confirms a substantive, compositional systems-glue capability — typed
binned cumulative distribution with two independent aggregations — reached
with restricted, subprocess-free XSH and byte-exact output, advancing the
practical-glue mission. The staged handbook candidate and the record-literal
ticket target durability: they surface general, reusable XSH facts (integer
division, typed record literals, reserved names, strict integer contracts)
that reduce repeated agent discovery and make boundaries explicit, per the
rationale's "no hidden/implicit behavior" principle. The concrete success
criterion is a future replay where the same task is solved in fewer discovery
turns with correct, clear XSH.
